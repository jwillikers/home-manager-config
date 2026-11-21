"""Unit tests for stretchly-inhibit."""

import importlib.machinery
import importlib.util
import os
import tempfile
import unittest


def load_module():
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "stretchly-inhibit.py")
    loader = importlib.machinery.SourceFileLoader("stretchly_inhibit", path)
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


si = load_module()

MICROPHONE = {"index": 92, "name": "alsa_input.usb-webcam.analog-stereo", "properties": {"device.class": "sound"}}
MONITOR = {
    "index": 63,
    "name": "alsa_output.pci-0000_00_1f.3.analog-stereo.monitor",
    "properties": {"device.class": "monitor"},
}
SOURCES = [MICROPHONE, MONITOR]


def stream(index=258, client="257", source=MICROPHONE["index"], corked=False, binary="zoom", pid=None):
    properties = {"application.name": binary, "application.process.binary": binary}
    if pid is not None:
        properties["application.process.id"] = str(pid)
    return {"index": index, "client": client, "source": source, "corked": corked, "properties": properties}


class FakeProc:
    """A temporary directory laid out like /proc with environ files."""

    def __init__(self):
        self.directory = tempfile.TemporaryDirectory()
        self.path = self.directory.name

    def add(self, pid, environment, comm="zoom", exe=None):
        os.makedirs(os.path.join(self.path, str(pid)))
        if exe is not None:
            os.symlink(exe, os.path.join(self.path, str(pid), "exe"))
        with open(os.path.join(self.path, str(pid), "comm"), "w") as file:
            file.write(comm + "\n")
        with open(os.path.join(self.path, str(pid), "environ"), "wb") as file:
            file.write(b"".join(f"{name}={value}".encode() + b"\0" for name, value in environment.items()))

    def cleanup(self):
        self.directory.cleanup()


class MicrophoneStreamsTest(unittest.TestCase):
    def setUp(self):
        self.proc = FakeProc()
        self.addCleanup(self.proc.cleanup)
        self.proc.add(100, {"HOME": "/home/user", "PATH": "/usr/bin"})
        self.proc.add(200, {"HOME": "/home/user", "SteamAppId": "1245620", "SteamGameId": "1245620"}, comm="game")
        self.proc.add(300, {"HOME": "/home/user", "WINEPREFIX": "/home/user/Games/prefix"}, comm="game")
        self.proc.add(400, {"SteamAppId": "1245620"}, comm="averylongbinary")
        self.proc.add(500, {"SteamAppId": "1245620"}, comm="launcher", exe="/usr/bin/game-binary")

    def active(self, streams):
        return si.microphone_streams(streams, SOURCES, self.proc.path)

    def test_no_streams(self):
        self.assertEqual(self.active([]), [])

    def test_meeting_application_uses_the_microphone(self):
        meeting = stream(binary="zoom", pid=100)
        self.assertEqual(self.active([meeting]), [meeting])

    def test_corked_stream_is_ignored(self):
        self.assertEqual(self.active([stream(corked=True, pid=100)]), [])

    def test_monitor_source_is_ignored(self):
        self.assertEqual(self.active([stream(source=MONITOR["index"], pid=100)]), [])

    def test_monitor_detected_by_name(self):
        monitor = {"index": 7, "name": "some_sink.monitor", "properties": {}}
        streams = [stream(source=7, pid=100)]
        self.assertEqual(si.microphone_streams(streams, [monitor], self.proc.path), [])

    def test_unknown_source_counts_as_microphone(self):
        meeting = stream(source=999, pid=100)
        self.assertEqual(self.active([meeting]), [meeting])

    def test_wine_binaries_are_ignored(self):
        for binary in ("wine", "wine64", "wine-preloader", "wine64-preloader", "Game.exe", "GAME.EXE"):
            with self.subTest(binary=binary):
                self.assertEqual(self.active([stream(binary=binary)]), [])

    def test_wine_lookalike_binary_is_not_ignored(self):
        meeting = stream(binary="winecfg-helper", pid=100)
        self.assertEqual(self.active([meeting]), [meeting])

    def test_steam_game_is_ignored(self):
        self.assertEqual(self.active([stream(binary="game", pid=200)]), [])

    def test_wine_prefix_is_ignored(self):
        self.assertEqual(self.active([stream(binary="game", pid=300)]), [])

    def test_mismatched_process_is_not_trusted(self):
        # Inside a Flatpak sandbox, the reported PID may belong to an unrelated process on the host.
        meeting = stream(binary="zoom", pid=200)
        self.assertEqual(self.active([meeting]), [meeting])

    def test_truncated_command_name_matches(self):
        self.assertEqual(self.active([stream(binary="averylongbinaryname", pid=400)]), [])

    def test_executable_matches_binary(self):
        # A binary run through a symlink has the symlink's name as its command name.
        self.assertEqual(self.active([stream(binary="game-binary", pid=500)]), [])

    def test_missing_process_counts_as_microphone(self):
        meeting = stream(binary="zoom", pid=999)
        self.assertEqual(self.active([meeting]), [meeting])

    def test_stream_without_pid_counts_as_microphone(self):
        meeting = stream(binary="zoom")
        self.assertEqual(self.active([meeting]), [meeting])

    def test_game_alongside_meeting(self):
        game = stream(index=1, client="1", binary="Game.exe")
        meeting = stream(index=2, client="2", binary="zoom", pid=100)
        self.assertEqual(self.active([game, meeting]), [meeting])


class ParseEventTest(unittest.TestCase):
    def test_source_output(self):
        self.assertEqual(si.parse_event("Event 'new' on source-output #258\n"), ("new", "source-output"))

    def test_other_facility(self):
        self.assertEqual(si.parse_event("Event 'change' on sink-input #12"), ("change", "sink-input"))

    def test_garbage(self):
        self.assertIsNone(si.parse_event("Connection failure"))


class InhibitorTest(unittest.TestCase):
    def setUp(self):
        self.streams = []
        self.commands = []
        self.inhibitor = si.Inhibitor(proc="/nonexistent", list_=self.fake_list, run=self.fake_run)

    def fake_list(self, kind):
        return {"source-outputs": self.streams, "sources": SOURCES}[kind]

    def fake_run(self, command, **_kwargs):
        self.commands.append(command)

    def test_resumes_initially_when_idle(self):
        self.inhibitor.update()
        self.assertEqual(self.commands, [["stretchly", "resume"]])

    def test_pauses_and_resumes_only_on_transitions(self):
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

    def test_game_does_not_pause(self):
        self.inhibitor.update()
        self.streams.append(stream(binary="wine64-preloader"))
        self.inhibitor.update()
        self.assertEqual(self.commands, [["stretchly", "resume"]])

    def test_uncorking_pauses(self):
        self.streams.append(stream(binary="zoom", corked=True))
        self.inhibitor.update()
        self.streams[0]["corked"] = False
        self.inhibitor.update()
        self.assertEqual(self.commands, [["stretchly", "resume"], ["stretchly", "pause"]])

    def test_dry_run_runs_nothing(self):
        self.inhibitor.dry_run = True
        self.streams.append(stream(binary="zoom"))
        self.inhibitor.update()
        self.assertEqual(self.commands, [])


if __name__ == "__main__":
    unittest.main()
