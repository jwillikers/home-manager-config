#!/usr/bin/env python3
"""Pause Stretchly breaks during online meetings and while watching videos, but not while gaming.

Breaks are paused while a microphone is in use or a video is playing, and resumed once neither is the case.

Microphone use is detected through recording streams on the PulseAudio server, which is pipewire-pulse in practice.
Games often open recording streams without ever using the microphone.
Wine and Proton open the capture device as part of initializing audio,
and games with voice chat may record continuously even when nobody speaks.
To keep breaks running while playing, recording streams are ignored when:

* The stream is corked, i.e. opened but not actually recording.
* The stream records a monitor source, which captures audio output rather than a microphone.
  Screen recorders, such as Steam's game recording, do this.
* The stream belongs to a game.

Videos are detected through requests to keep the screen on with the org.freedesktop.ScreenSaver D-Bus interface,
which is how browsers and media players prevent the screen from blanking while playing a video.
They don't make these requests when only playing audio.
This monitors the session bus for these requests,
so requests made before this program started are missed.
Games make these requests as well, so they are ignored when they come from a game,
or when their reason mentions a game, like SDL's default reason, "Playing a game".

Games are processes run by Wine, processes launched by Steam or another game launcher, and Steam itself.
"""

import argparse
import json
import logging
import os
import queue
import re
import socket
import subprocess
import sys
import threading
from collections.abc import Callable, Sequence
from dataclasses import dataclass
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from jeepney.io.blocking import DBusConnection
    from jeepney.low_level import Message

log = logging.getLogger("stretchly-inhibit")

# Objects from the JSON output of pactl, such as streams, sources, and clients
PulseObject = dict[str, Any]

# A thread watching for events puts None in the queue when something changes and an error message when it fails.
Events = queue.Queue[str | None]

# Environment variables that game launchers set for the games that they run.
# Steam sets SteamAppId and SteamGameId for native and Proton games, and Proton adds STEAM_COMPAT_APP_ID.
# Wine, Proton, Lutris, Heroic, and Bottles set WINEPREFIX.
GAME_ENVIRONMENT_VARIABLES = (
    "SteamAppId",
    "SteamGameId",
    "STEAM_COMPAT_APP_ID",
    "WINEPREFIX",
)

# Binaries of games, i.e. Windows programs under Wine or Proton, and of Steam itself.
# libpulse names the binary after /proc/self/exe, which is Wine's loader,
# but some versions of Wine report the name of the Windows executable instead.
GAME_BINARY = re.compile(r"^(wine(64)?(-preloader)?|.*\.exe|steam|steamwebhelper|gamescope)$", re.IGNORECASE)

# Reasons for keeping the screen on which indicate a game.
# SDL uses "Playing a game" by default.
GAME_REASON = re.compile(r"\bgam(e|es|ing)\b", re.IGNORECASE)

# Lines from pactl subscribe look like: Event 'new' on source-output #258
EVENT = re.compile(r"^Event '(?P<event>[^']+)' on (?P<facility>[\w-]+) #(?P<index>\d+)$")

# Events which may change whether a microphone is in use.
# A change event on a source-output includes it being corked or uncorked.
# A source can be added or removed after a stream starts recording from it, which affects whether it's a monitor.
RELEVANT_FACILITIES = ("source-output", "source")

SCREENSAVER = "org.freedesktop.ScreenSaver"
DBUS = "org.freedesktop.DBus"

# Match rules for monitoring requests to keep the screen on.
# The cookie identifying a request is in the reply to the Inhibit call.
# Requests are dropped when the client which made them disconnects from the bus.
SCREENSAVER_MATCH_RULES = [
    f"type='method_call',interface='{SCREENSAVER}',member='Inhibit'",
    f"type='method_call',interface='{SCREENSAVER}',member='UnInhibit'",
    f"type='method_return',sender='{SCREENSAVER}'",
    f"type='signal',sender='{DBUS}',interface='{DBUS}',member='NameOwnerChanged'",
]


def pactl_list(kind: str) -> list[PulseObject]:
    output = subprocess.run(
        ["pactl", "--format=json", "list", kind],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    result: list[PulseObject] = json.loads(output) if output.strip() else []
    return result


def read_environment(pid: int | str, proc: str = "/proc") -> set[str] | None:
    """Return the names of the environment variables of a process, or None if they can't be read."""
    try:
        with open(os.path.join(proc, str(pid), "environ"), "rb") as file:
            environ = file.read()
    except OSError:
        return None
    return {entry.split(b"=", 1)[0].decode(errors="replace") for entry in environ.split(b"\0") if entry}


def read_executable(pid: int | str, proc: str = "/proc") -> str | None:
    """Return the name of the executable of a process, or None if it can't be read."""
    try:
        return os.path.basename(os.readlink(os.path.join(proc, str(pid), "exe")))
    except OSError:
        return None


def process_matches_binary(pid: int | str, binary: str, proc: str = "/proc") -> bool:
    """Return whether a process runs the given binary.

    libpulse names the binary after /proc/self/exe,
    which differs from the command name when the binary is run through a symlink.
    The kernel truncates command names to 15 characters.
    """
    if read_executable(pid, proc) == binary:
        return True
    try:
        with open(os.path.join(proc, str(pid), "comm")) as file:
            return file.read().rstrip("\n") == binary[:15]
    except OSError:
        return False


def is_game_process(pid: int | str, proc: str = "/proc") -> bool:
    executable = read_executable(pid, proc)
    if executable and GAME_BINARY.match(executable):
        return True
    environment = read_environment(pid, proc)
    return bool(environment and environment.intersection(GAME_ENVIRONMENT_VARIABLES))


def stream_pid(stream: PulseObject, proc: str = "/proc") -> int | None:
    """Return the process ID of the client which owns a stream, or None if it isn't known.

    PipeWire only knows the process ID of pipewire-pulse itself for PulseAudio clients,
    so this relies on the process ID which the client reports.
    Inside a Flatpak sandbox, the reported process ID is from the sandbox's PID namespace,
    where it may belong to an unrelated process on the host.
    To avoid this, the process must match the stream's binary.
    """
    properties = stream.get("properties", {})
    pid = str(properties.get("application.process.id", ""))
    binary = properties.get("application.process.binary", "")
    if not pid.isdigit() or not binary:
        return None
    if not process_matches_binary(pid, binary, proc):
        log.debug("Process %s doesn't match the binary %s of stream %s", pid, binary, describe_stream(stream))
        return None
    return int(pid)


def is_game_stream(stream: PulseObject, proc: str = "/proc") -> bool:
    binary = str(stream.get("properties", {}).get("application.process.binary", ""))
    if GAME_BINARY.match(binary):
        return True
    pid = stream_pid(stream, proc)
    return pid is not None and is_game_process(pid, proc)


def is_monitor(source: PulseObject | None) -> bool:
    if source is None:
        return False
    return source.get("properties", {}).get("device.class") == "monitor" or str(source.get("name", "")).endswith(
        ".monitor"
    )


def describe_stream(stream: PulseObject) -> str:
    properties = stream.get("properties", {})
    name = properties.get("application.name") or properties.get("application.process.binary") or "unknown"
    return f"#{stream.get('index')} ({name})"


def microphone_streams(
    streams: list[PulseObject], sources: list[PulseObject], proc: str = "/proc"
) -> list[PulseObject]:
    """Return the recording streams which are actively using a microphone."""
    sources_by_index = {source.get("index"): source for source in sources}
    active: list[PulseObject] = []
    for stream in streams:
        if stream.get("corked"):
            log.debug("Ignoring corked stream %s", describe_stream(stream))
        elif is_monitor(sources_by_index.get(stream.get("source"))):
            log.debug("Ignoring stream %s recording a monitor source", describe_stream(stream))
        elif is_game_stream(stream, proc):
            log.debug("Ignoring stream %s from a game", describe_stream(stream))
        else:
            active.append(stream)
    return active


def parse_event(line: str) -> tuple[str, str] | None:
    """Return the event and facility from a line of pactl subscribe output, or None if it doesn't match."""
    match = EVENT.match(line.strip())
    if match is None:
        return None
    return match.group("event"), match.group("facility")


@dataclass(frozen=True)
class ScreenInhibition:
    """A request to keep the screen on."""

    sender: str
    application: str
    reason: str
    pid: int | None
    game: bool

    def __str__(self) -> str:
        return f"{self.application or 'unknown'} ({self.reason or 'no reason given'})"


class ScreenInhibitions:
    """Track requests to keep the screen on from the messages to and from the org.freedesktop.ScreenSaver service."""

    def __init__(self, proc: str = "/proc") -> None:
        self.proc = proc
        self.lock = threading.Lock()
        # Inhibit calls awaiting their reply, keyed by the sender and serial number of the call
        self.pending: dict[tuple[str, int], ScreenInhibition] = {}
        # Active requests, keyed by cookie
        self.active: dict[int, ScreenInhibition] = {}

    def inhibit_called(self, sender: str, serial: int, application: str, reason: str, pid: int | None) -> None:
        game = bool(GAME_REASON.search(reason) or GAME_BINARY.match(application))
        if not game and pid is not None:
            game = is_game_process(pid, self.proc)
        inhibition = ScreenInhibition(sender, application, reason, pid, game)
        log.debug("%s requested to keep the screen on from process %s", inhibition, pid)
        with self.lock:
            self.pending[(sender, serial)] = inhibition

    def reply_received(self, destination: str, reply_serial: int, body: Sequence[Any]) -> bool:
        """Return whether the reply activated a request."""
        with self.lock:
            inhibition = self.pending.pop((destination, reply_serial), None)
            if inhibition is None or len(body) != 1:
                return False
            self.active[body[0]] = inhibition
        if inhibition.game:
            log.info("Ignoring the request from %s to keep the screen on, since it's from a game", inhibition)
        else:
            log.info("%s is keeping the screen on", inhibition)
        return True

    def uninhibit_called(self, cookie: int) -> bool:
        """Return whether a request was removed."""
        with self.lock:
            inhibition = self.active.pop(cookie, None)
        if inhibition is None:
            return False
        log.info("%s stopped keeping the screen on", inhibition)
        return True

    def name_lost(self, name: str) -> bool:
        """Drop requests when the client that made them disconnects or the service is replaced.

        Return whether any requests were removed.
        """
        with self.lock:
            if name == SCREENSAVER:
                removed = list(self.active.values())
                self.active.clear()
                self.pending.clear()
            else:
                removed = [inhibition for inhibition in self.active.values() if inhibition.sender == name]
                self.active = {cookie: i for cookie, i in self.active.items() if i.sender != name}
                self.pending = {key: i for key, i in self.pending.items() if i.sender != name}
        for inhibition in removed:
            log.info("%s stopped keeping the screen on by disconnecting", inhibition)
        return bool(removed)

    def videos(self) -> list[ScreenInhibition]:
        """Return the active requests to keep the screen on which aren't from games."""
        with self.lock:
            return [inhibition for inhibition in self.active.values() if not inhibition.game]


class ScreenSaverMonitor:
    """Feed messages from a D-Bus monitor connection to ScreenInhibitions."""

    def __init__(self, inhibitions: ScreenInhibitions, process_id: Callable[[str], int | None]) -> None:
        self.inhibitions = inhibitions
        # Return the process ID of a bus connection, or None if it's unknown
        self.process_id = process_id

    def handle(self, message: "Message") -> bool:
        """Return whether the message may have changed which requests are active."""
        # Import here so that the rest of the module doesn't require jeepney.
        from jeepney.low_level import HeaderFields, MessageType

        header = message.header
        fields = header.fields
        member = fields.get(HeaderFields.member)
        if header.message_type == MessageType.method_call and fields.get(HeaderFields.interface) == SCREENSAVER:
            sender = fields.get(HeaderFields.sender)
            if member == "Inhibit" and isinstance(sender, str) and len(message.body) == 2:
                application, reason = message.body
                self.inhibitions.inhibit_called(
                    sender, header.serial, str(application), str(reason), self.process_id(sender)
                )
            elif member == "UnInhibit" and len(message.body) == 1:
                return self.inhibitions.uninhibit_called(message.body[0])
        elif header.message_type == MessageType.method_return:
            destination = fields.get(HeaderFields.destination)
            reply_serial = fields.get(HeaderFields.reply_serial)
            if isinstance(destination, str) and isinstance(reply_serial, int):
                return self.inhibitions.reply_received(destination, reply_serial, message.body)
        elif header.message_type == MessageType.signal and member == "NameOwnerChanged" and len(message.body) == 3:
            name, old_owner, _new_owner = message.body
            if old_owner:
                return self.inhibitions.name_lost(str(name))
        return False


def notify(message: str) -> None:
    """Send a message to systemd when running as a notify service."""
    address = os.environ.get("NOTIFY_SOCKET")
    if not address:
        return
    if address.startswith("@"):
        address = "\0" + address[1:]
    with socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM) as sock:
        sock.connect(address)
        sock.sendall(message.encode())


class Inhibitor:
    def __init__(
        self,
        dry_run: bool = False,
        proc: str = "/proc",
        list_: Callable[[str], list[PulseObject]] = pactl_list,
        run: Callable[..., object] = subprocess.run,
        inhibitions: ScreenInhibitions | None = None,
    ) -> None:
        self.dry_run = dry_run
        self.proc = proc
        self.list = list_
        self.run_command = run
        self.inhibitions = inhibitions if inhibitions is not None else ScreenInhibitions(proc)
        self.paused: bool | None = None

    def stretchly(self, action: str) -> None:
        if self.dry_run:
            log.info("Dry run: would run stretchly %s", action)
            return
        self.run_command(["stretchly", action], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)

    def update(self) -> None:
        """Pause or resume Stretchly when microphone use or video playback starts or stops."""
        streams = microphone_streams(self.list("source-outputs"), self.list("sources"), self.proc)
        videos = self.inhibitions.videos()
        pause = bool(streams or videos)
        if pause == self.paused:
            return
        if pause:
            causes: list[str] = []
            if streams:
                causes.append("a microphone is in use by " + ", ".join(map(describe_stream, streams)))
            if videos:
                causes.append("a video is playing in " + ", ".join(map(str, videos)))
            log.info("Pausing Stretchly breaks since %s.", " and ".join(causes))
            self.stretchly("pause")
        else:
            log.info("Resuming Stretchly breaks since no microphones are in use and no videos are playing.")
            self.stretchly("resume")
        self.paused = pause

    def watch_pulseaudio(self, events: Events) -> None:
        with subprocess.Popen(["pactl", "subscribe"], stdout=subprocess.PIPE, text=True, bufsize=1) as subscription:
            assert subscription.stdout is not None
            for line in subscription.stdout:
                parsed = parse_event(line)
                if parsed is not None and parsed[1] in RELEVANT_FACILITIES:
                    events.put(None)
        events.put(f"pactl subscribe exited with status {subscription.returncode}")

    def open_screensaver_monitor(self) -> tuple["DBusConnection", ScreenSaverMonitor]:
        from jeepney.bus_messages import Monitoring, message_bus
        from jeepney.io.blocking import open_dbus_connection

        # Monitor connections can't send messages, so a separate connection looks up process IDs.
        bus = open_dbus_connection(bus="SESSION")
        monitor = open_dbus_connection(bus="SESSION")
        monitor.send_and_get_reply(Monitoring().BecomeMonitor(SCREENSAVER_MATCH_RULES))

        def process_id(sender: str) -> int | None:
            try:
                return int(bus.send_and_get_reply(message_bus.GetConnectionUnixProcessID(sender), timeout=1).body[0])
            except Exception as error:
                log.debug("Failed to get the process ID of %s: %s", sender, error)
                return None

        return monitor, ScreenSaverMonitor(self.inhibitions, process_id)

    def watch_screensaver(self, events: Events, connection: "DBusConnection", monitor: ScreenSaverMonitor) -> None:
        try:
            while True:
                if monitor.handle(connection.receive()):
                    events.put(None)
        except Exception as error:
            events.put(f"Monitoring the session bus failed: {error!r}")

    def run(self) -> int:
        events: Events = queue.Queue()
        connection, monitor = self.open_screensaver_monitor()
        threading.Thread(target=self.watch_screensaver, args=(events, connection, monitor), daemon=True).start()
        threading.Thread(target=self.watch_pulseaudio, args=(events,), daemon=True).start()
        self.update()
        notify("READY=1\nSTATUS=Monitoring microphone use and video playback")
        while True:
            error = events.get()
            if error is not None:
                log.error(error)
                return 1
            self.update()


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0] if __doc__ else None)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Log when breaks would be paused or resumed instead of running Stretchly",
    )
    return parser.parse_args(argv)


def main() -> None:
    args = parse_args()
    logging.basicConfig(
        level=os.environ.get("LOG_LEVEL", "INFO"),
        format="%(levelname)s: %(message)s",
    )
    sys.exit(Inhibitor(args.dry_run).run())


if __name__ == "__main__":
    main()
