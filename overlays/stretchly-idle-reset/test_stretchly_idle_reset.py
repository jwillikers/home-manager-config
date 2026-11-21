"""Unit tests for stretchly-idle-reset."""

import asyncio
import faulthandler
import importlib.machinery
import importlib.util
import os
import struct
import tempfile
import unittest
from collections import namedtuple
from unittest import mock

from evdev import InputEvent, ecodes


def load_module():
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "stretchly-idle-reset.py")
    loader = importlib.machinery.SourceFileLoader("stretchly_idle_reset", path)
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


sir = load_module()

AbsInfo = namedtuple("AbsInfo", ["min", "max"])


class FakeDevice:
    name = "Fake Gamepad"

    def __init__(self, axes=None):
        self.axes = axes or {}

    def absinfo(self, code):
        return self.axes[code]


def event(type_, code, value):
    return InputEvent(0, 0, type_, code, value)


def deck_report(sequence=0, buttons=bytes(8), axes=(0, 0, 275, 639, -1137, -154), report_type=0x09):
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
    def setUp(self):
        self.state = sir.DeckControllerState()
        self.assertFalse(self.state.is_activity(deck_report()), "baseline")

    def test_sequence_counter_alone_is_not_activity(self):
        self.assertFalse(self.state.is_activity(deck_report(sequence=1)))

    def test_motion_sensor_data_is_not_activity(self):
        report = bytearray(deck_report(sequence=1))
        report[24:44] = bytes(range(1, 21))
        self.assertFalse(self.state.is_activity(bytes(report)))

    def test_button_press_and_release_are_activity(self):
        self.assertTrue(self.state.is_activity(deck_report(1, A_BUTTON)))
        self.assertFalse(self.state.is_activity(deck_report(2, A_BUTTON)), "held")
        self.assertTrue(self.state.is_activity(deck_report(3)), "released")

    def test_touching_a_stick_is_activity(self):
        self.assertTrue(self.state.is_activity(deck_report(1, LEFT_STICK_TOUCH)))

    def test_stick_drift_is_not_activity(self):
        self.assertFalse(self.state.is_activity(deck_report(1, axes=(0, 0, 900, 1200, -1137, -154))))

    def test_large_stick_movement_is_activity(self):
        self.assertTrue(self.state.is_activity(deck_report(1, axes=(0, 0, -6888, 639, -1137, -154))))
        self.assertFalse(
            self.state.is_activity(deck_report(2, axes=(0, 0, -6900, 639, -1137, -154))),
            "held in place",
        )

    def test_pulling_a_trigger_is_activity(self):
        self.assertTrue(self.state.is_activity(deck_report(1, axes=(0, 20000, 275, 639, -1137, -154))))

    def test_other_report_types_are_ignored(self):
        self.assertFalse(self.state.is_activity(deck_report(1, A_BUTTON, report_type=0x01)))

    def test_short_reports_are_ignored(self):
        self.assertFalse(self.state.is_activity(deck_report(1, A_BUTTON)[:40]))

    def test_first_report_only_establishes_the_baseline(self):
        state = sir.DeckControllerState()
        self.assertFalse(state.is_activity(deck_report(0, A_BUTTON)))
        self.assertFalse(state.is_activity(deck_report(1, A_BUTTON)))


class EvdevActivityTest(unittest.TestCase):
    def setUp(self):
        self.resetter = sir.IdleResetter(900, ["true"], dry_run=True)
        self.device = FakeDevice({ecodes.ABS_X: AbsInfo(-32768, 32767), ecodes.ABS_HAT0X: AbsInfo(-1, 1)})
        self.baselines = {}

    def is_activity(self, type_, code, value):
        return self.resetter.is_activity(self.device, event(type_, code, value), self.baselines)

    def test_key_events_are_activity(self):
        self.assertTrue(self.is_activity(ecodes.EV_KEY, ecodes.BTN_SOUTH, 1))
        self.assertTrue(self.is_activity(ecodes.EV_KEY, ecodes.BTN_SOUTH, 0))

    def test_relative_motion_is_activity(self):
        self.assertTrue(self.is_activity(ecodes.EV_REL, ecodes.REL_X, 3))
        self.assertFalse(self.is_activity(ecodes.EV_REL, ecodes.REL_X, 0))

    def test_absolute_axes_ignore_drift(self):
        self.assertFalse(self.is_activity(ecodes.EV_ABS, ecodes.ABS_X, 100), "baseline")
        self.assertFalse(self.is_activity(ecodes.EV_ABS, ecodes.ABS_X, 400), "drift")
        self.assertTrue(self.is_activity(ecodes.EV_ABS, ecodes.ABS_X, 20000), "large movement")
        self.assertFalse(self.is_activity(ecodes.EV_ABS, ecodes.ABS_X, 20100), "held in place")

    def test_small_range_axes_count_every_step(self):
        self.assertFalse(self.is_activity(ecodes.EV_ABS, ecodes.ABS_HAT0X, 0), "baseline")
        self.assertTrue(self.is_activity(ecodes.EV_ABS, ecodes.ABS_HAT0X, 1))

    def test_sync_and_misc_events_are_not_activity(self):
        self.assertFalse(self.is_activity(ecodes.EV_SYN, ecodes.SYN_REPORT, 0))
        self.assertFalse(self.is_activity(ecodes.EV_MSC, ecodes.MSC_SCAN, 4))


class FakeClock:
    def __init__(self):
        self.time = 1000.0

    def __call__(self):
        return self.time


class IdleThresholdTest(unittest.TestCase):
    def setUp(self):
        self.clock = FakeClock()
        patcher = mock.patch.object(sir, "now", self.clock)
        patcher.start()
        self.addCleanup(patcher.stop)
        self.resetter = sir.IdleResetter(900, ["true"], dry_run=False)
        self.resetter.reset = mock.AsyncMock()

    def activity_after(self, seconds):
        self.clock.time += seconds
        asyncio.run(self.resetter.activity("Fake Gamepad"))

    def test_activity_before_the_threshold_does_not_reset(self):
        self.activity_after(899)
        self.resetter.reset.assert_not_awaited()

    def test_activity_after_the_threshold_resets_once(self):
        self.activity_after(900)
        self.assertEqual(self.resetter.reset.await_count, 1)
        self.activity_after(1)
        self.assertEqual(self.resetter.reset.await_count, 1)

    def test_steady_activity_never_resets(self):
        for _ in range(100):
            self.activity_after(60)
        self.resetter.reset.assert_not_awaited()

    def test_idle_time_restarts_with_each_activity(self):
        self.activity_after(600)
        self.activity_after(600)
        self.resetter.reset.assert_not_awaited()
        self.activity_after(900)
        self.assertEqual(self.resetter.reset.await_count, 1)


class ResetCommandTest(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.marker = os.path.join(directory.name, "reset")

    def reset(self, command, dry_run=False):
        asyncio.run(sir.IdleResetter(900, command, dry_run).reset())

    def test_runs_the_command(self):
        self.reset(["sh", "-c", 'touch "$0"', self.marker])
        self.assertTrue(os.path.exists(self.marker))

    def test_dry_run_does_not_run_the_command(self):
        with self.assertLogs(sir.log, "INFO"):
            self.reset(["sh", "-c", 'touch "$0"', self.marker], dry_run=True)
        self.assertFalse(os.path.exists(self.marker))

    def test_logs_a_failing_command(self):
        with self.assertLogs(sir.log, "WARNING") as logs:
            self.reset(["sh", "-c", "exit 3"])
        self.assertIn("exited with status 3", logs.output[0])

    def test_logs_a_missing_command(self):
        with self.assertLogs(sir.log, "ERROR") as logs:
            self.reset(["/nonexistent/stretchly", "reset"])
        self.assertIn("Unable to run", logs.output[0])


class ValveHidrawDevicesTest(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.sysfs = directory.name

    def add(self, name, uevent):
        path = os.path.join(self.sysfs, name, "device")
        os.makedirs(path)
        with open(os.path.join(path, "uevent"), "w") as file:
            file.write(uevent)

    def test_finds_only_valve_devices(self):
        self.add(
            "hidraw0",
            "DRIVER=hid-steam\nHID_ID=0003:000028DE:00001205\nHID_NAME=Valve Software Steam Controller\n",
        )
        self.add("hidraw1", "HID_ID=0003:000028DE:00001205\nHID_NAME=Valve Software Steam Controller\n")
        self.add("hidraw6", "HID_ID=0005:0000054C:00000CE6\nHID_NAME=DualSense Wireless Controller\n")
        self.assertEqual(
            list(sir.valve_hidraw_devices(self.sysfs)),
            [
                ("/dev/hidraw0", "Valve Software Steam Controller"),
                ("/dev/hidraw1", "Valve Software Steam Controller"),
            ],
        )

    def test_skips_malformed_entries(self):
        self.add("hidraw0", "HID_NAME=No ID\n")
        self.add("hidraw1", "HID_ID=not-an-id\n")
        self.add("hidraw2", "HID_ID=0003:zzzz:1205\n")
        self.add("hidraw3", "HID_ID=0003:000028DE:00001205\n")
        self.assertEqual(list(sir.valve_hidraw_devices(self.sysfs)), [("/dev/hidraw3", "Valve controller")])


class WatchHidrawTest(unittest.TestCase):
    """Feeds reports through a FIFO standing in for a hidraw device."""

    def test_reports_activity_and_stops_when_the_device_goes_away(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        fifo = os.path.join(directory.name, "hidraw0")
        os.mkfifo(fifo)
        resetter = sir.IdleResetter(900, ["true"], dry_run=True)
        activity = []

        async def record(name):
            activity.append(name)

        resetter.activity = record

        async def scenario():
            resetter.devices[fifo] = "Fake Deck"
            watcher = asyncio.ensure_future(resetter.watch_hidraw(fifo, "Fake Deck"))
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
            with self.assertLogs(sir.log, "INFO"):
                asyncio.run(scenario())
        finally:
            faulthandler.cancel_dump_traceback_later()
        self.assertEqual(activity, ["Fake Deck"])
        self.assertNotIn(fifo, resetter.devices)


class ParseArgsTest(unittest.TestCase):
    def test_defaults(self):
        args = sir.parse_args([])
        self.assertEqual(args.threshold, 900)
        self.assertFalse(args.dry_run)
        self.assertEqual(args.command, ["stretchly", "reset"])

    def test_command_after_separator(self):
        args = sir.parse_args(["--threshold", "60", "--dry-run", "--", "/bin/stretchly", "reset"])
        self.assertEqual(args.threshold, 60)
        self.assertTrue(args.dry_run)
        self.assertEqual(args.command, ["/bin/stretchly", "reset"])


if __name__ == "__main__":
    unittest.main()
