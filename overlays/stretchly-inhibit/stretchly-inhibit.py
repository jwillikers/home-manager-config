#!/usr/bin/env python3
"""Pause Stretchly breaks while a microphone is in use, such as during an online meeting.

Breaks are paused while any application records from a microphone and resumed once none do.
This watches the PulseAudio server, which is PipeWire's pipewire-pulse in practice, for recording streams.

Games often open recording streams without ever using the microphone.
Wine and Proton open the capture device as part of initializing audio,
and games with voice chat may record continuously even when nobody speaks.
To keep breaks running while playing, recording streams are ignored when:

* The stream is corked, i.e. opened but not actually recording.
* The stream records a monitor source, which captures audio output rather than a microphone.
  Screen recorders, such as Steam's game recording, do this.
* The stream belongs to a game, which is a process run by Wine or launched by Steam or another game launcher.
"""

import argparse
import json
import logging
import os
import re
import socket
import subprocess
import sys

log = logging.getLogger("stretchly-inhibit")

# Environment variables that game launchers set for the games that they run.
# Steam sets SteamAppId and SteamGameId for native and Proton games, and Proton adds STEAM_COMPAT_APP_ID.
# Wine, Proton, Lutris, Heroic, and Bottles set WINEPREFIX.
GAME_ENVIRONMENT_VARIABLES = (
    "SteamAppId",
    "SteamGameId",
    "STEAM_COMPAT_APP_ID",
    "WINEPREFIX",
)

# Binaries of processes running Windows programs under Wine or Proton.
# libpulse names the binary after /proc/self/exe, which is Wine's loader,
# but some versions of Wine report the name of the Windows executable instead.
WINE_BINARY = re.compile(r"^(wine(64)?(-preloader)?|.*\.exe)$", re.IGNORECASE)

# Lines from pactl subscribe look like: Event 'new' on source-output #258
EVENT = re.compile(r"^Event '(?P<event>[^']+)' on (?P<facility>[\w-]+) #(?P<index>\d+)$")

# Events which may change whether a microphone is in use.
# A change event on a source-output includes it being corked or uncorked.
# A source can be added or removed after a stream starts recording from it, which affects whether it's a monitor.
RELEVANT_FACILITIES = ("source-output", "source")


def pactl_list(kind):
    output = subprocess.run(
        ["pactl", "--format=json", "list", kind],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    return json.loads(output) if output.strip() else []


def read_environment(pid, proc="/proc"):
    """Return the names of the environment variables of a process, or None if they can't be read."""
    try:
        with open(os.path.join(proc, str(pid), "environ"), "rb") as file:
            environ = file.read()
    except OSError:
        return None
    return {entry.split(b"=", 1)[0].decode(errors="replace") for entry in environ.split(b"\0") if entry}


def process_matches_binary(pid, binary, proc="/proc"):
    """Return whether a process runs the given binary.

    libpulse names the binary after /proc/self/exe,
    which differs from the command name when the binary is run through a symlink.
    The kernel truncates command names to 15 characters.
    """
    try:
        if os.path.basename(os.readlink(os.path.join(proc, str(pid), "exe"))) == binary:
            return True
    except OSError:
        pass
    try:
        with open(os.path.join(proc, str(pid), "comm")) as file:
            return file.read().rstrip("\n") == binary[:15]
    except OSError:
        return False


def stream_pid(stream, proc="/proc"):
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
        log.debug("Process %s doesn't match the binary %s of stream %s", pid, binary, describe(stream))
        return None
    return int(pid)


def is_game(stream, proc="/proc"):
    binary = stream.get("properties", {}).get("application.process.binary", "")
    if WINE_BINARY.match(binary):
        return True
    pid = stream_pid(stream, proc)
    if pid is None:
        return False
    environment = read_environment(pid, proc)
    return bool(environment and environment.intersection(GAME_ENVIRONMENT_VARIABLES))


def is_monitor(source):
    if source is None:
        return False
    return source.get("properties", {}).get("device.class") == "monitor" or source.get("name", "").endswith(".monitor")


def describe(stream):
    properties = stream.get("properties", {})
    name = properties.get("application.name") or properties.get("application.process.binary") or "unknown"
    return f"#{stream.get('index')} ({name})"


def microphone_streams(streams, sources, proc="/proc"):
    """Return the recording streams which are actively using a microphone."""
    sources_by_index = {source.get("index"): source for source in sources}
    active = []
    for stream in streams:
        if stream.get("corked"):
            log.debug("Ignoring corked stream %s", describe(stream))
        elif is_monitor(sources_by_index.get(stream.get("source"))):
            log.debug("Ignoring stream %s recording a monitor source", describe(stream))
        elif is_game(stream, proc):
            log.debug("Ignoring stream %s from a game", describe(stream))
        else:
            active.append(stream)
    return active


def parse_event(line):
    """Return the event and facility from a line of pactl subscribe output, or None if it doesn't match."""
    match = EVENT.match(line.strip())
    if match is None:
        return None
    return match.group("event"), match.group("facility")


def notify(message):
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
    def __init__(self, dry_run=False, proc="/proc", list_=pactl_list, run=subprocess.run):
        self.dry_run = dry_run
        self.proc = proc
        self.list = list_
        self.run_command = run
        self.paused = None

    def stretchly(self, action):
        if self.dry_run:
            log.info("Dry run: would run stretchly %s", action)
            return
        self.run_command(["stretchly", action], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)

    def update(self):
        """Pause or resume Stretchly when microphone use starts or stops."""
        streams = microphone_streams(
            self.list("source-outputs"),
            self.list("sources"),
            self.proc,
        )
        in_use = bool(streams)
        if in_use == self.paused:
            return
        if in_use:
            log.info(
                "A microphone is in use by %s. Pausing Stretchly breaks.",
                ", ".join(describe(stream) for stream in streams),
            )
            self.stretchly("pause")
        else:
            log.info("No microphones are in use. Resuming Stretchly breaks.")
            self.stretchly("resume")
        self.paused = in_use

    def run(self):
        with subprocess.Popen(["pactl", "subscribe"], stdout=subprocess.PIPE, text=True, bufsize=1) as subscription:
            # Check the initial state after subscribing so that no events are missed in between.
            self.update()
            notify("READY=1\nSTATUS=Monitoring the PulseAudio server for microphone use")
            for line in subscription.stdout:
                parsed = parse_event(line)
                if parsed is not None and parsed[1] in RELEVANT_FACILITIES:
                    self.update()
        return subscription.returncode


def parse_args(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Log when breaks would be paused or resumed instead of running Stretchly",
    )
    return parser.parse_args(argv)


def main():
    args = parse_args()
    logging.basicConfig(
        level=os.environ.get("LOG_LEVEL", "INFO"),
        format="%(levelname)s: %(message)s",
    )
    returncode = Inhibitor(args.dry_run).run()
    log.error("pactl subscribe exited with status %s", returncode)
    sys.exit(returncode or 1)


if __name__ == "__main__":
    main()
