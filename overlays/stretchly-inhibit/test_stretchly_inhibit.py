"""Unit tests for stretchly-inhibit."""

import os
import tempfile
import unittest
from typing import Any

from jeepney import DBusAddress, new_method_call, new_method_return, new_signal
from jeepney.low_level import HeaderFields

import stretchly_inhibit as si

MICROPHONE: dict[str, Any] = {
    "index": 92,
    "name": "alsa_input.usb-webcam.analog-stereo",
    "properties": {"device.class": "sound"},
}
MONITOR: dict[str, Any] = {
    "index": 63,
    "name": "alsa_output.pci-0000_00_1f.3.analog-stereo.monitor",
    "properties": {"device.class": "monitor"},
}
SOURCES = [MICROPHONE, MONITOR]


def stream(
    index: int = 258,
    client: str = "257",
    source: int = MICROPHONE["index"],
    corked: bool = False,
    binary: str = "zoom",
    pid: int | None = None,
) -> dict[str, Any]:
    properties = {"application.name": binary, "application.process.binary": binary}
    if pid is not None:
        properties["application.process.id"] = str(pid)
    return {"index": index, "client": client, "source": source, "corked": corked, "properties": properties}


class FakeProc:
    """A temporary directory laid out like /proc with environ files."""

    def __init__(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.path = self.directory.name

    def add(self, pid: int, environment: dict[str, str], comm: str = "zoom", exe: str | None = None) -> None:
        os.makedirs(os.path.join(self.path, str(pid)))
        if exe is not None:
            os.symlink(exe, os.path.join(self.path, str(pid), "exe"))
        with open(os.path.join(self.path, str(pid), "comm"), "w") as file:
            file.write(comm + "\n")
        with open(os.path.join(self.path, str(pid), "environ"), "wb") as file:
            file.write(b"".join(f"{name}={value}".encode() + b"\0" for name, value in environment.items()))

    def cleanup(self) -> None:
        self.directory.cleanup()


class MicrophoneStreamsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.proc = FakeProc()
        self.addCleanup(self.proc.cleanup)
        self.proc.add(100, {"HOME": "/home/user", "PATH": "/usr/bin"})
        self.proc.add(200, {"HOME": "/home/user", "SteamAppId": "1245620", "SteamGameId": "1245620"}, comm="game")
        self.proc.add(300, {"HOME": "/home/user", "WINEPREFIX": "/home/user/Games/prefix"}, comm="game")
        self.proc.add(400, {"SteamAppId": "1245620"}, comm="averylongbinary")
        self.proc.add(500, {"SteamAppId": "1245620"}, comm="launcher", exe="/usr/bin/game-binary")

    def active(self, streams: list[dict[str, Any]]) -> list[dict[str, Any]]:
        return si.microphone_streams(streams, SOURCES, self.proc.path)

    def test_no_streams(self) -> None:
        self.assertEqual(self.active([]), [])

    def test_meeting_application_uses_the_microphone(self) -> None:
        meeting = stream(binary="zoom", pid=100)
        self.assertEqual(self.active([meeting]), [meeting])

    def test_corked_stream_is_ignored(self) -> None:
        self.assertEqual(self.active([stream(corked=True, pid=100)]), [])

    def test_monitor_source_is_ignored(self) -> None:
        self.assertEqual(self.active([stream(source=MONITOR["index"], pid=100)]), [])

    def test_monitor_detected_by_name(self) -> None:
        monitor: dict[str, Any] = {"index": 7, "name": "some_sink.monitor", "properties": {}}
        streams = [stream(source=7, pid=100)]
        self.assertEqual(si.microphone_streams(streams, [monitor], self.proc.path), [])

    def test_unknown_source_counts_as_microphone(self) -> None:
        meeting = stream(source=999, pid=100)
        self.assertEqual(self.active([meeting]), [meeting])

    def test_wine_binaries_are_ignored(self) -> None:
        for binary in ("wine", "wine64", "wine-preloader", "wine64-preloader", "Game.exe", "GAME.EXE", "steam"):
            with self.subTest(binary=binary):
                self.assertEqual(self.active([stream(binary=binary)]), [])

    def test_wine_lookalike_binary_is_not_ignored(self) -> None:
        meeting = stream(binary="winecfg-helper", pid=100)
        self.assertEqual(self.active([meeting]), [meeting])

    def test_steam_game_is_ignored(self) -> None:
        self.assertEqual(self.active([stream(binary="game", pid=200)]), [])

    def test_wine_prefix_is_ignored(self) -> None:
        self.assertEqual(self.active([stream(binary="game", pid=300)]), [])

    def test_mismatched_process_is_not_trusted(self) -> None:
        # Inside a Flatpak sandbox, the reported PID may belong to an unrelated process on the host.
        meeting = stream(binary="zoom", pid=200)
        self.assertEqual(self.active([meeting]), [meeting])

    def test_truncated_command_name_matches(self) -> None:
        self.assertEqual(self.active([stream(binary="averylongbinaryname", pid=400)]), [])

    def test_executable_matches_binary(self) -> None:
        # A binary run through a symlink has the symlink's name as its command name.
        self.assertEqual(self.active([stream(binary="game-binary", pid=500)]), [])

    def test_missing_process_counts_as_microphone(self) -> None:
        meeting = stream(binary="zoom", pid=999)
        self.assertEqual(self.active([meeting]), [meeting])

    def test_stream_without_pid_counts_as_microphone(self) -> None:
        meeting = stream(binary="zoom")
        self.assertEqual(self.active([meeting]), [meeting])

    def test_game_alongside_meeting(self) -> None:
        game = stream(index=1, client="1", binary="Game.exe")
        meeting = stream(index=2, client="2", binary="zoom", pid=100)
        self.assertEqual(self.active([game, meeting]), [meeting])


SCREENSAVER = DBusAddress("/org/freedesktop/ScreenSaver", "org.freedesktop.ScreenSaver", "org.freedesktop.ScreenSaver")
DBUS = DBusAddress("/org/freedesktop/DBus", "org.freedesktop.DBus", "org.freedesktop.DBus")


class ScreenSaverMonitorTest(unittest.TestCase):
    def setUp(self) -> None:
        self.proc = FakeProc()
        self.addCleanup(self.proc.cleanup)
        self.proc.add(100, {"HOME": "/home/user"}, comm="firefox", exe="/usr/lib64/firefox/firefox")
        self.proc.add(200, {"SteamAppId": "1245620"}, comm="game", exe="/games/game")
        self.proc.add(300, {"HOME": "/home/user"}, comm="steam", exe="/home/user/.steam/ubuntu12_32/steam")
        self.inhibitions = si.ScreenInhibitions(self.proc.path)
        self.pids = {":1.100": 100, ":1.200": 200, ":1.300": 300}
        self.monitor = si.ScreenSaverMonitor(self.inhibitions, self.pids.get)
        self.serial = 0

    def inhibit(
        self, sender: str, application: str = "Firefox", reason: str = "video-playing", cookie: int | None = None
    ) -> bool:
        self.serial += 1
        call = new_method_call(SCREENSAVER, "Inhibit", "ss", (application, reason))
        call.header.serial = self.serial
        call.header.fields[HeaderFields.sender] = sender
        self.assertFalse(self.monitor.handle(call))
        reply = new_method_return(call, "u", (cookie if cookie is not None else self.serial,))
        reply.header.fields[HeaderFields.sender] = ":1.1"
        return self.monitor.handle(reply)

    def uninhibit(self, sender: str, cookie: int) -> bool:
        call = new_method_call(SCREENSAVER, "UnInhibit", "u", (cookie,))
        call.header.fields[HeaderFields.sender] = sender
        return self.monitor.handle(call)

    def name_owner_changed(self, name: str, old: str, new: str) -> bool:
        return self.monitor.handle(new_signal(DBUS, "NameOwnerChanged", "sss", (name, old, new)))

    def videos(self) -> list[tuple[str, str]]:
        return [(inhibition.application, inhibition.reason) for inhibition in self.inhibitions.videos()]

    def ignored(self) -> list[str]:
        return [inhibition.ignored for inhibition in self.inhibitions.active.values() if inhibition.ignored is not None]

    def test_video_keeps_screen_on(self) -> None:
        self.assertTrue(self.inhibit(":1.100", cookie=7))
        self.assertEqual(self.videos(), [("Firefox", "video-playing")])
        self.assertTrue(self.uninhibit(":1.100", 7))
        self.assertEqual(self.videos(), [])

    def test_game_process_is_ignored(self) -> None:
        self.inhibit(":1.200", application="My SDL application", reason="Steam game")
        self.assertEqual(self.videos(), [])

    def test_game_reason_is_ignored(self) -> None:
        self.inhibit(":1.999", application="My SDL application", reason="Playing a game")
        self.assertEqual(self.videos(), [])

    def test_steam_is_ignored(self) -> None:
        self.inhibit(":1.300", application="Steam", reason="Big Picture")
        self.inhibit(":1.999", application="Steam", reason="Big Picture")
        self.assertEqual(self.videos(), [])

    def test_unknown_process_counts_as_video(self) -> None:
        self.inhibit(":1.999", application="Jellyfin Desktop", reason="Playing media")
        self.assertEqual(self.videos(), [("Jellyfin Desktop", "Playing media")])

    def test_wake_daemon_is_ignored(self) -> None:
        # joystickwake keeps the screen on whenever a controller is in use, which is when breaks must keep running.
        # Its reason doesn't mention a game and its process is an unrelated Python interpreter,
        # so only the name it reports identifies it.
        self.inhibit(":1.999", application="joystickwake", reason="Active joystick")
        self.assertEqual(self.videos(), [])
        self.assertEqual(self.ignored(), ["a wake daemon"])

    def test_wake_daemon_lookalike_is_not_ignored(self) -> None:
        self.inhibit(":1.999", application="joystickwaker", reason="Active joystick")
        self.assertEqual(self.videos(), [("joystickwaker", "Active joystick")])

    def test_video_still_pauses_breaks_while_a_controller_is_in_use(self) -> None:
        self.inhibit(":1.999", application="joystickwake", reason="Active joystick")
        self.inhibit(":1.999", application="Jellyfin Desktop", reason="Playing media")
        self.assertEqual(self.videos(), [("Jellyfin Desktop", "Playing media")])

    def test_games_are_still_reported_as_games(self) -> None:
        self.inhibit(":1.200", application="My SDL application", reason="Steam game")
        self.assertEqual(self.ignored(), ["a game"])

    def test_unrelated_reply_is_ignored(self) -> None:
        call = new_method_call(DBusAddress("/", "org.example", "org.example"), "Hello")
        call.header.serial = 99
        call.header.fields[HeaderFields.sender] = ":1.100"
        self.assertFalse(self.monitor.handle(new_method_return(call, "u", (1,))))
        self.assertEqual(self.videos(), [])

    def test_unknown_cookie_is_ignored(self) -> None:
        self.inhibit(":1.100", cookie=7)
        self.assertFalse(self.uninhibit(":1.100", 8))
        self.assertEqual(len(self.videos()), 1)

    def test_disconnecting_drops_requests(self) -> None:
        self.inhibit(":1.100")
        self.inhibit(":1.999", application="mpv")
        self.assertFalse(self.name_owner_changed(":1.555", ":1.555", ""))
        self.assertFalse(self.name_owner_changed(":1.556", "", ":1.556"))
        self.assertTrue(self.name_owner_changed(":1.100", ":1.100", ""))
        self.assertEqual(self.videos(), [("mpv", "video-playing")])

    def test_service_restart_drops_requests(self) -> None:
        self.inhibit(":1.100")
        self.assertTrue(self.name_owner_changed("org.freedesktop.ScreenSaver", ":1.1", ":1.2"))
        self.assertEqual(self.videos(), [])


# The key capabilities of an Xbox controller, which includes BTN_SOUTH, from /sys/class/input/input*/capabilities/key
GAMEPAD_KEYS = "7cdb000000000000 0 0 0 0"
# The key capabilities of the touchpad on a laptop
TOUCHPAD_KEYS = "e520 30000 0 0 0 0"


class FakeSysfs:
    """A temporary directory laid out like /sys with input devices."""

    def __init__(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.root = self.directory.name
        self.input = os.path.join(self.root, "class", "input")
        os.makedirs(self.input)

    def add(self, number: int, parent: str, name: str, keys: str, vendor: int = 0x045E, product: int = 0x028E) -> None:
        device = os.path.join(self.root, "devices", parent, "input", f"input{number}")
        os.makedirs(os.path.join(device, "capabilities"))
        os.makedirs(os.path.join(device, "id"))
        for path, content in (
            ("name", name),
            ("capabilities/key", keys),
            ("id/vendor", f"{vendor:04x}"),
            ("id/product", f"{product:04x}"),
        ):
            with open(os.path.join(device, path), "w") as file:
                file.write(content + "\n")
        os.symlink(device, os.path.join(self.input, f"input{number}"))

    def cleanup(self) -> None:
        self.directory.cleanup()


class GamepadsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.sysfs = FakeSysfs()
        self.addCleanup(self.sysfs.cleanup)

    def names(self) -> list[str]:
        return [gamepad.name for gamepad in si.gamepads(self.sysfs.input)]

    def test_has_key(self) -> None:
        self.assertTrue(si.has_key(GAMEPAD_KEYS, si.BTN_SOUTH))
        self.assertFalse(si.has_key(TOUCHPAD_KEYS, si.BTN_SOUTH))
        self.assertFalse(si.has_key("0", si.BTN_SOUTH))

    def test_no_input_devices(self) -> None:
        self.assertEqual(self.names(), [])

    def test_missing_sysfs(self) -> None:
        self.assertEqual(si.gamepads(os.path.join(self.sysfs.root, "nonexistent")), [])

    def test_finds_usb_and_bluetooth_gamepads(self) -> None:
        self.sysfs.add(1, "pci0000:00/usb1/1-1/1-1:1.0", "Microsoft X-Box 360 pad", GAMEPAD_KEYS)
        # Bluetooth LE controllers are under the virtual uhid device.
        self.sysfs.add(
            2, "virtual/misc/uhid/0005:045E:0B13.0001", "Xbox Wireless Controller", GAMEPAD_KEYS, product=0x0B13
        )
        self.assertEqual(self.names(), ["Microsoft X-Box 360 pad", "Xbox Wireless Controller"])

    def test_ignores_other_input_devices(self) -> None:
        self.sysfs.add(1, "platform/i2c-1/touchpad", "Touchpad", TOUCHPAD_KEYS, vendor=0x044E, product=0x121F)
        self.assertEqual(self.names(), [])

    def test_ignores_virtual_gamepads(self) -> None:
        # Steam Input creates a virtual gamepad for each physical controller with uinput.
        self.sysfs.add(1, "virtual", "Microsoft X-Box 360 pad 0", GAMEPAD_KEYS)
        self.assertEqual(self.names(), [])

    def test_ignores_the_steam_decks_controls(self) -> None:
        self.sysfs.add(1, "pci0000:00/usb3/3-3/3-3:1.2/0003:28DE:1205.0003", "Steam Deck", GAMEPAD_KEYS, 0x28DE, 0x1205)
        self.assertEqual(self.names(), [])

    def test_counts_each_controller_once(self) -> None:
        parent = "pci0000:00/usb1/1-2/1-2:1.3/0003:054C:0CE6.0004"
        self.sysfs.add(1, parent, "DualSense Wireless Controller", GAMEPAD_KEYS, 0x054C, 0x0CE6)
        self.sysfs.add(2, parent, "DualSense Wireless Controller Motion Sensors", "0", 0x054C, 0x0CE6)
        self.sysfs.add(3, parent, "DualSense Wireless Controller Touchpad", TOUCHPAD_KEYS, 0x054C, 0x0CE6)
        self.assertEqual(self.names(), ["DualSense Wireless Controller"])

    def test_skips_malformed_capabilities(self) -> None:
        self.sysfs.add(1, "pci0000:00/usb1/1-1/1-1:1.0", "Broken", "not hexadecimal")
        self.assertEqual(self.names(), [])


class ParseEventTest(unittest.TestCase):
    def test_source_output(self) -> None:
        self.assertEqual(si.parse_event("Event 'new' on source-output #258\n"), ("new", "source-output"))

    def test_other_facility(self) -> None:
        self.assertEqual(si.parse_event("Event 'change' on sink-input #12"), ("change", "sink-input"))

    def test_garbage(self) -> None:
        self.assertIsNone(si.parse_event("Connection failure"))


class InhibitorTest(unittest.TestCase):
    def setUp(self) -> None:
        self.streams: list[dict[str, Any]] = []
        self.commands: list[list[str]] = []
        self.inhibitions = si.ScreenInhibitions("/nonexistent")
        self.gamepads: list[si.Gamepad] = []
        self.inhibitor = si.Inhibitor(
            proc="/nonexistent",
            list_=self.fake_list,
            run=self.fake_run,
            inhibitions=self.inhibitions,
            list_gamepads=lambda: self.gamepads,
        )

    def fake_list(self, kind: str) -> list[dict[str, Any]]:
        return {"source-outputs": self.streams, "sources": SOURCES}[kind]

    def fake_run(self, command: list[str], **_kwargs: object) -> None:
        self.commands.append(command)

    def test_resumes_initially_when_idle(self) -> None:
        self.inhibitor.update()
        self.assertEqual(self.commands, [["stretchly", "resume"]])

    def test_pauses_and_resumes_only_on_transitions(self) -> None:
        self.inhibitor.update()
        self.streams.append(stream(binary="zoom"))
        self.inhibitor.update()
        self.inhibitor.update()
        self.streams.append(stream(index=259, binary="teams"))
        self.inhibitor.update()
        self.streams.clear()
        self.inhibitor.update()
        self.inhibitor.update()
        self.assertEqual(
            self.commands,
            [["stretchly", "resume"], ["stretchly", "pause"], ["stretchly", "resume"]],
        )

    def test_game_does_not_pause(self) -> None:
        self.inhibitor.update()
        self.streams.append(stream(binary="wine64-preloader"))
        self.inhibitor.update()
        self.assertEqual(self.commands, [["stretchly", "resume"]])

    def test_uncorking_pauses(self) -> None:
        self.streams.append(stream(binary="zoom", corked=True))
        self.inhibitor.update()
        self.streams[0]["corked"] = False
        self.inhibitor.update()
        self.assertEqual(self.commands, [["stretchly", "resume"], ["stretchly", "pause"]])

    def play_video(self, cookie: int = 1, reason: str = "video-playing") -> None:
        self.inhibitions.inhibit_called(":1.100", cookie, "Firefox", reason, None)
        self.inhibitions.reply_received(":1.100", cookie, (cookie,))

    def test_video_pauses(self) -> None:
        self.inhibitor.update()
        self.play_video()
        self.inhibitor.update()
        self.inhibitions.uninhibit_called(1)
        self.inhibitor.update()
        self.assertEqual(
            self.commands,
            [["stretchly", "resume"], ["stretchly", "pause"], ["stretchly", "resume"]],
        )

    def test_stays_paused_while_video_or_microphone_is_in_use(self) -> None:
        self.play_video()
        self.inhibitor.update()
        self.streams.append(stream(binary="zoom"))
        self.inhibitor.update()
        self.inhibitions.uninhibit_called(1)
        self.inhibitor.update()
        self.streams.clear()
        self.inhibitor.update()
        self.assertEqual(self.commands, [["stretchly", "pause"], ["stretchly", "resume"]])

    def test_game_keeping_screen_on_does_not_pause(self) -> None:
        self.play_video(reason="Playing a game")
        self.inhibitor.update()
        self.assertEqual(self.commands, [["stretchly", "resume"]])

    def connect_gamepads(self, count: int) -> None:
        self.gamepads = [si.Gamepad(f"Gamepad {number}", f"/sys/devices/gamepad{number}") for number in range(count)]

    def test_gamepads_are_ignored_by_default(self) -> None:
        self.connect_gamepads(4)
        self.inhibitor.update()
        self.assertEqual(self.commands, [["stretchly", "resume"]])

    def test_pauses_while_enough_gamepads_are_connected(self) -> None:
        self.inhibitor.gamepad_threshold = 2
        self.connect_gamepads(1)
        self.inhibitor.update()
        self.connect_gamepads(2)
        self.inhibitor.update()
        self.connect_gamepads(3)
        self.inhibitor.update()
        self.connect_gamepads(1)
        self.inhibitor.update()
        self.assertEqual(
            self.commands,
            [["stretchly", "resume"], ["stretchly", "pause"], ["stretchly", "resume"]],
        )

    def test_dry_run_runs_nothing(self) -> None:
        self.inhibitor.dry_run = True
        self.streams.append(stream(binary="zoom"))
        self.inhibitor.update()
        self.assertEqual(self.commands, [])


if __name__ == "__main__":
    unittest.main()
