"""Unit tests for input-idle-monitor."""

import asyncio
import faulthandler
import io
import os
import struct
import tempfile
import unittest
from typing import cast
from unittest import mock

import evdev
from evdev import AbsInfo, InputEvent, ecodes

import input_idle_monitor as iim


def abs_info(minimum: int, maximum: int) -> AbsInfo:
    return AbsInfo(value=0, min=minimum, max=maximum, fuzz=0, flat=0, resolution=0)


class FakeDevice:
    name = "Fake Gamepad"

    def __init__(self, axes: dict[int, AbsInfo] | None = None) -> None:
        self.axes = axes or {}

    def absinfo(self, axis_num: int) -> AbsInfo:
        return self.axes[axis_num]


def event(type_: int, code: int, value: int) -> InputEvent:
    return InputEvent(0, 0, type_, code, value)


def deck_report(
    sequence: int = 0,
    buttons: bytes = bytes(8),
    axes: tuple[int, int, int, int, int, int] = (0, 0, 275, 639, -1137, -154),
    report_type: int = 0x09,
) -> bytes:
    report = bytearray(64)
    report[0] = 0x01
    report[2] = report_type
    struct.pack_into("<I", report, 4, sequence)
    report[8:16] = buttons
    struct.pack_into("<HHhhhh", report, 44, *axes)
    return bytes(report)


A_BUTTON = bytes([0x80]) + bytes(7)
LEFT_STICK_TOUCH = bytes(5) + bytes([0x40]) + bytes(2)


class DeckControllerStateTest(unittest.TestCase):
    def setUp(self) -> None:
        self.state = iim.DeckControllerState()
        self.assertFalse(self.state.is_activity(deck_report()), "baseline")

    def test_sequence_counter_alone_is_not_activity(self) -> None:
        self.assertFalse(self.state.is_activity(deck_report(sequence=1)))

    def test_motion_sensor_data_is_not_activity(self) -> None:
        report = bytearray(deck_report(sequence=1))
        report[24:44] = bytes(range(1, 21))
        self.assertFalse(self.state.is_activity(bytes(report)))

    def test_button_press_and_release_are_activity(self) -> None:
        self.assertTrue(self.state.is_activity(deck_report(1, A_BUTTON)))
        self.assertFalse(self.state.is_activity(deck_report(2, A_BUTTON)), "held")
        self.assertTrue(self.state.is_activity(deck_report(3)), "released")

    def test_touching_a_stick_is_activity(self) -> None:
        self.assertTrue(self.state.is_activity(deck_report(1, LEFT_STICK_TOUCH)))

    def test_stick_drift_is_not_activity(self) -> None:
        self.assertFalse(self.state.is_activity(deck_report(1, axes=(0, 0, 900, 1200, -1137, -154))))

    def test_large_stick_movement_is_activity(self) -> None:
        self.assertTrue(self.state.is_activity(deck_report(1, axes=(0, 0, -6888, 639, -1137, -154))))
        self.assertFalse(
            self.state.is_activity(deck_report(2, axes=(0, 0, -6900, 639, -1137, -154))),
            "held in place",
        )

    def test_pulling_a_trigger_is_activity(self) -> None:
        self.assertTrue(self.state.is_activity(deck_report(1, axes=(0, 20000, 275, 639, -1137, -154))))

    def test_other_report_types_are_ignored(self) -> None:
        self.assertFalse(self.state.is_activity(deck_report(1, A_BUTTON, report_type=0x01)))

    def test_short_reports_are_ignored(self) -> None:
        self.assertFalse(self.state.is_activity(deck_report(1, A_BUTTON)[:40]))

    def test_first_report_only_establishes_the_baseline(self) -> None:
        state = iim.DeckControllerState()
        self.assertFalse(state.is_activity(deck_report(0, A_BUTTON)))
        self.assertFalse(state.is_activity(deck_report(1, A_BUTTON)))


class EvdevActivityTest(unittest.TestCase):
    def setUp(self) -> None:
        self.monitor = iim.IdleMonitor(900, io.StringIO())
        # is_activity only uses absinfo from the device.
        self.device = cast(
            "evdev.InputDevice[str]",
            FakeDevice({ecodes.ABS_X: abs_info(-32768, 32767), ecodes.ABS_HAT0X: abs_info(-1, 1)}),
        )
        self.baselines: dict[int, int] = {}

    def is_activity(self, type_: int, code: int, value: int) -> bool:
        return self.monitor.is_activity(self.device, event(type_, code, value), self.baselines)

    def test_key_events_are_activity(self) -> None:
        self.assertTrue(self.is_activity(ecodes.EV_KEY, ecodes.BTN_SOUTH, 1))
        self.assertTrue(self.is_activity(ecodes.EV_KEY, ecodes.BTN_SOUTH, 0))

    def test_relative_motion_is_activity(self) -> None:
        self.assertTrue(self.is_activity(ecodes.EV_REL, ecodes.REL_X, 3))
        self.assertFalse(self.is_activity(ecodes.EV_REL, ecodes.REL_X, 0))

    def test_absolute_axes_ignore_drift(self) -> None:
        self.assertFalse(self.is_activity(ecodes.EV_ABS, ecodes.ABS_X, 100), "baseline")
        self.assertFalse(self.is_activity(ecodes.EV_ABS, ecodes.ABS_X, 400), "drift")
        self.assertTrue(self.is_activity(ecodes.EV_ABS, ecodes.ABS_X, 20000), "large movement")
        self.assertFalse(self.is_activity(ecodes.EV_ABS, ecodes.ABS_X, 20100), "held in place")

    def test_small_range_axes_count_every_step(self) -> None:
        self.assertFalse(self.is_activity(ecodes.EV_ABS, ecodes.ABS_HAT0X, 0), "baseline")
        self.assertTrue(self.is_activity(ecodes.EV_ABS, ecodes.ABS_HAT0X, 1))

    def test_sync_and_misc_events_are_not_activity(self) -> None:
        self.assertFalse(self.is_activity(ecodes.EV_SYN, ecodes.SYN_REPORT, 0))
        self.assertFalse(self.is_activity(ecodes.EV_MSC, ecodes.MSC_SCAN, 4))


class FakeClock:
    def __init__(self) -> None:
        self.time = 1000.0

    def __call__(self) -> float:
        return self.time


class IdleThresholdTest(unittest.TestCase):
    def setUp(self) -> None:
        self.clock = FakeClock()
        patcher = mock.patch.object(iim, "now", self.clock)
        patcher.start()
        self.addCleanup(patcher.stop)
        self.output = io.StringIO()
        self.monitor = iim.IdleMonitor(900, self.output)
        # Keep log messages out of the test output.
        log_patcher = mock.patch.object(iim, "log")
        log_patcher.start()
        self.addCleanup(log_patcher.stop)

    def reports(self) -> list[str]:
        return self.output.getvalue().splitlines()

    def wait(self, seconds: float) -> None:
        self.clock.time += seconds
        self.monitor.check_idle()

    def activity_after(self, seconds: float) -> None:
        self.clock.time += seconds
        asyncio.run(self.monitor.activity("Fake Gamepad"))

    def test_reports_nothing_before_the_threshold(self) -> None:
        self.wait(899)
        self.activity_after(0)
        self.assertEqual(self.reports(), [])

    def test_reports_idle_once_the_threshold_passes(self) -> None:
        self.wait(900)
        self.wait(60)
        self.assertEqual(self.reports(), ["idle"])

    def test_reports_active_at_the_next_input(self) -> None:
        self.wait(900)
        self.activity_after(60)
        self.activity_after(1)
        self.assertEqual(self.reports(), ["idle", "active"])

    def test_input_after_a_missed_check_reports_both(self) -> None:
        # Like input right after resuming from suspend, before the next check
        self.activity_after(3600)
        self.assertEqual(self.reports(), ["idle", "active"])

    def test_steady_activity_never_reports(self) -> None:
        for _ in range(100):
            self.activity_after(60)
            self.wait(0)
        self.assertEqual(self.reports(), [])

    def test_idle_time_restarts_with_each_activity(self) -> None:
        self.activity_after(600)
        self.wait(600)
        self.assertEqual(self.reports(), [])
        self.wait(300)
        self.assertEqual(self.reports(), ["idle"])


class ValveHidrawDevicesTest(unittest.TestCase):
    def setUp(self) -> None:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.sysfs = directory.name

    def add(self, name: str, uevent: str) -> None:
        path = os.path.join(self.sysfs, name, "device")
        os.makedirs(path)
        with open(os.path.join(path, "uevent"), "w") as file:
            file.write(uevent)

    def test_finds_only_valve_devices(self) -> None:
        self.add(
            "hidraw0",
            "DRIVER=hid-steam\nHID_ID=0003:000028DE:00001205\nHID_NAME=Valve Software Steam Controller\n",
        )
        self.add("hidraw1", "HID_ID=0003:000028DE:00001205\nHID_NAME=Valve Software Steam Controller\n")
        self.add("hidraw6", "HID_ID=0005:0000054C:00000CE6\nHID_NAME=DualSense Wireless Controller\n")
        self.assertEqual(
            list(iim.valve_hidraw_devices(self.sysfs)),
            [
                ("/dev/hidraw0", "Valve Software Steam Controller"),
                ("/dev/hidraw1", "Valve Software Steam Controller"),
            ],
        )

    def test_skips_malformed_entries(self) -> None:
        self.add("hidraw0", "HID_NAME=No ID\n")
        self.add("hidraw1", "HID_ID=not-an-id\n")
        self.add("hidraw2", "HID_ID=0003:zzzz:1205\n")
        self.add("hidraw3", "HID_ID=0003:000028DE:00001205\n")
        self.assertEqual(list(iim.valve_hidraw_devices(self.sysfs)), [("/dev/hidraw3", "Valve controller")])


class WatchHidrawTest(unittest.TestCase):
    """Feeds reports through a FIFO standing in for a hidraw device."""

    def test_reports_activity_and_stops_when_the_device_goes_away(self) -> None:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        fifo = os.path.join(directory.name, "hidraw0")
        os.mkfifo(fifo)
        monitor = iim.IdleMonitor(900, io.StringIO())
        activity: list[str] = []

        async def record(name: str) -> None:
            activity.append(name)

        patcher = mock.patch.object(monitor, "activity", record)
        patcher.start()
        self.addCleanup(patcher.stop)

        async def scenario() -> None:
            monitor.devices[fifo] = "Fake Deck"
            watcher = asyncio.ensure_future(monitor.watch_hidraw(fifo, "Fake Deck"))
            await asyncio.sleep(0.1)
            writer = os.open(fifo, os.O_WRONLY)
            for report in (deck_report(0), deck_report(1), deck_report(2, A_BUTTON), deck_report(3, A_BUTTON)):
                os.write(writer, report)
            await asyncio.sleep(0.1)
            os.close(writer)
            await asyncio.wait_for(watcher, timeout=5)

        # A busy loop in the reader blocks the event loop, so asyncio's timeout can't fire.
        # Abort the test run instead of hanging the build.
        faulthandler.dump_traceback_later(10, exit=True)
        try:
            with self.assertLogs(iim.log, "INFO"):
                asyncio.run(scenario())
        finally:
            faulthandler.cancel_dump_traceback_later()
        self.assertEqual(activity, ["Fake Deck"])
        self.assertNotIn(fifo, monitor.devices)


class ParseArgsTest(unittest.TestCase):
    def test_defaults(self) -> None:
        self.assertEqual(iim.parse_args([]).threshold, 900)

    def test_threshold(self) -> None:
        self.assertEqual(iim.parse_args(["--threshold", "600"]).threshold, 600)


if __name__ == "__main__":
    unittest.main()
