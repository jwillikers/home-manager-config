#!/usr/bin/env python3
"""Reset Stretchly breaks after returning from a long period without any input.

Stretchly's natural breaks rely on the desktop's idle time.
Desktops don't count gamepad input as activity,
so natural breaks consider the user idle while playing games with a controller.
This watches every input device directly, gamepads included,
and resets Stretchly when input resumes after the idle threshold.
It never pauses Stretchly, so breaks still happen during long play sessions.

Choose an idle threshold longer than the longest break.
Otherwise, input after sitting through a break could reset Stretchly and end the break.

While Steam is running, it reads the Steam Deck's built-in controls directly from the raw HID device,
so they never produce events on any input device.
To catch them, this also reads the controller state reports from Valve's raw HID devices.

Requires read access to /dev/input/event*, i.e. membership in the input group.
On the Steam Deck, the logged-in user can read the controller's /dev/hidraw* devices.
"""

import argparse
import asyncio
import glob
import logging
import os
import shlex
import struct
import time
from collections.abc import AsyncIterator, Iterator, Sequence
from typing import cast

import evdev
from evdev import ecodes

log = logging.getLogger("stretchly-idle-reset")

# How far an absolute axis must move, as a fraction of its range, to count as activity.
# This filters out analog stick drift and sensor noise.
ABS_ACTIVITY_FRACTION = 0.1

# How often to look for new input devices, in seconds.
RESCAN_INTERVAL = 5

# Steam Deck controller state reports from Valve's raw HID devices.
# The layout matches the Linux kernel's hid-steam driver.
VALVE_VENDOR_ID = 0x28DE
DECK_STATE_REPORT_TYPE = 0x09
# Buttons, including the capacitive touch sensors on the sticks and trackpads
DECK_BUTTONS = slice(8, 16)
# Left trigger, right trigger, left stick x, left stick y, right stick x, right stick y
DECK_AXES_FORMAT = "<HHhhhh"
DECK_AXES_OFFSET = 44
DECK_AXIS_RANGES = (32767, 32767, 65535, 65535, 65535, 65535)
DECK_REPORT_MIN_SIZE = DECK_AXES_OFFSET + struct.calcsize(DECK_AXES_FORMAT)


def valve_hidraw_devices(sysfs: str = "/sys/class/hidraw") -> Iterator[tuple[str, str]]:
    for uevent in sorted(glob.glob(os.path.join(sysfs, "hidraw*", "device", "uevent"))):
        try:
            with open(uevent) as file:
                fields = dict(line.rstrip("\n").split("=", 1) for line in file if "=" in line)
        except OSError:
            continue
        # HID_ID=BUS:VENDOR:PRODUCT in hexadecimal
        parts = fields.get("HID_ID", "").split(":")
        try:
            vendor_id = int(parts[1], 16) if len(parts) == 3 else None
        except ValueError:
            continue
        if vendor_id == VALVE_VENDOR_ID:
            name = os.path.basename(os.path.dirname(os.path.dirname(uevent)))
            yield "/dev/" + name, fields.get("HID_NAME", "Valve controller")


class DeckControllerState:
    """Detects input in Steam Deck controller state reports."""

    def __init__(self) -> None:
        self.buttons: bytes | None = None
        self.axis_baselines: list[int] = []

    def is_activity(self, report: bytes) -> bool:
        if len(report) < DECK_REPORT_MIN_SIZE or report[2] != DECK_STATE_REPORT_TYPE:
            return False
        buttons = report[DECK_BUTTONS]
        axes = struct.unpack_from(DECK_AXES_FORMAT, report, DECK_AXES_OFFSET)
        if self.buttons is None:
            # The first report only establishes the baseline.
            self.buttons = buttons
            self.axis_baselines = list(axes)
            return False
        activity = buttons != self.buttons
        self.buttons = buttons
        for index, (value, axis_range) in enumerate(zip(axes, DECK_AXIS_RANGES, strict=True)):
            if abs(value - self.axis_baselines[index]) >= axis_range * ABS_ACTIVITY_FRACTION:
                self.axis_baselines[index] = value
                activity = True
        return activity


def now() -> float:
    # Includes time spent suspended, so a long suspend counts as being idle.
    return time.clock_gettime(time.CLOCK_BOOTTIME)


class IdleResetter:
    def __init__(self, threshold: float, command: list[str], dry_run: bool) -> None:
        self.threshold = threshold
        self.command = command
        self.dry_run = dry_run
        self.last_activity = now()
        # Watched devices, keyed by path, as input devices or the names of raw HID devices
        self.devices: dict[str, evdev.InputDevice[str] | str] = {}

    async def activity(self, name: str) -> None:
        current = now()
        idle = current - self.last_activity
        self.last_activity = current
        if idle >= self.threshold:
            log.info(
                "Input from %s after %.0f seconds idle, resetting breaks",
                name,
                idle,
            )
            await self.reset()

    async def reset(self) -> None:
        if self.dry_run:
            log.info("Dry run, not running: %s", shlex.join(self.command))
            return
        try:
            process = await asyncio.create_subprocess_exec(*self.command)
            return_code = await process.wait()
        except OSError as error:
            log.error("Unable to run %s: %s", shlex.join(self.command), error)
            return
        if return_code != 0:
            log.warning("%s exited with status %d", shlex.join(self.command), return_code)

    def is_activity(
        self, device: evdev.InputDevice[str], event: evdev.InputEvent, abs_baselines: dict[int, int]
    ) -> bool:
        if event.type == ecodes.EV_KEY:
            return True
        if event.type == ecodes.EV_REL:
            return event.value != 0
        if event.type == ecodes.EV_ABS:
            info = device.absinfo(event.code)
            threshold = max(1, (info.max - info.min) * ABS_ACTIVITY_FRACTION)
            baseline = abs_baselines.get(event.code)
            if baseline is None or abs(event.value - baseline) >= threshold:
                abs_baselines[event.code] = event.value
                # The first event for an axis only establishes its baseline.
                return baseline is not None
            return False
        return False

    async def watch(self, device: evdev.InputDevice[str]) -> None:
        abs_baselines: dict[int, int] = {}
        try:
            # evdev adds async_read_loop to input devices at runtime, so its type is unknown.
            read_loop = device.async_read_loop  # pyright: ignore[reportUnknownMemberType, reportUnknownVariableType]
            events = cast(AsyncIterator[evdev.InputEvent], read_loop())
            async for event in events:
                if self.is_activity(device, event, abs_baselines):
                    await self.activity(device.name)
        except OSError:
            # The device was removed.
            pass
        finally:
            self.devices.pop(device.path, None)
            try:
                device.close()
            except OSError:
                pass
            log.info("Stopped watching %s (%s)", device.path, device.name)

    async def watch_hidraw(self, path: str, name: str) -> None:
        loop = asyncio.get_running_loop()
        try:
            fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
        except OSError as error:
            log.debug("Unable to open %s (%s): %s", path, name, error)
            self.devices.pop(path, None)
            return
        log.info("Watching %s (%s)", path, name)
        state = DeckControllerState()
        reports: asyncio.Queue[bytes | None] = asyncio.Queue()

        def removed() -> None:
            reports.put_nowait(None)
            loop.remove_reader(fd)

        def readable() -> None:
            try:
                while True:
                    report = os.read(fd, 64)
                    if not report:
                        # End of file, which also means that the device is gone.
                        removed()
                        return
                    reports.put_nowait(report)
            except BlockingIOError:
                pass
            except OSError:
                # The device was removed.
                removed()

        loop.add_reader(fd, readable)
        try:
            while (report := await reports.get()) is not None:
                if state.is_activity(report):
                    await self.activity(name)
        finally:
            loop.remove_reader(fd)
            os.close(fd)
            self.devices.pop(path, None)
            log.info("Stopped watching %s (%s)", path, name)

    def scan(self) -> int:
        unreadable = 0
        for path, name in valve_hidraw_devices():
            if path not in self.devices:
                self.devices[path] = name
                asyncio.get_running_loop().create_task(self.watch_hidraw(path, name))
        # The type hint of the directory parameter of list_devices is incomplete.
        paths: list[str] = evdev.list_devices()  # pyright: ignore[reportUnknownMemberType]
        for path in paths:
            if path in self.devices:
                continue
            try:
                device = evdev.InputDevice(path)
            except PermissionError:
                unreadable += 1
                continue
            except OSError:
                continue
            # Motion sensors report constantly, even when the device is sitting still.
            if ecodes.INPUT_PROP_ACCELEROMETER in device.input_props():
                device.close()
                continue
            self.devices[path] = device
            log.info("Watching %s (%s)", path, device.name)
            asyncio.get_running_loop().create_task(self.watch(device))
        return unreadable

    async def run(self) -> None:
        warned = False
        while True:
            unreadable = self.scan()
            if unreadable and not self.devices and not warned:
                log.warning("Unable to read any input devices. Is this user in the input group?")
                warned = True
            await asyncio.sleep(RESCAN_INTERVAL)


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0] if __doc__ else None)
    parser.add_argument(
        "--threshold",
        type=float,
        default=900,
        help="Seconds without input before the next input resets breaks (default: %(default)s)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Log when breaks would be reset instead of running the command",
    )
    parser.add_argument(
        "command",
        nargs=argparse.REMAINDER,
        help="Command that resets breaks (default: stretchly reset)",
    )
    args = parser.parse_args(argv)
    command = args.command
    if command and command[0] == "--":
        command = command[1:]
    args.command = command or ["stretchly", "reset"]
    return args


def main() -> None:
    args = parse_args()
    command = args.command
    logging.basicConfig(
        level=os.environ.get("LOG_LEVEL", "INFO"),
        format="%(levelname)s: %(message)s",
    )
    log.info(
        "Resetting breaks after %.0f seconds without input with: %s",
        args.threshold,
        shlex.join(command),
    )
    asyncio.run(IdleResetter(args.threshold, command, args.dry_run).run())


if __name__ == "__main__":
    main()
