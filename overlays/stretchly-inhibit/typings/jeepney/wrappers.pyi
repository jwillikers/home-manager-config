from typing import Any

from .low_level import Message

class DBusAddress:
    object_path: str
    bus_name: str | None
    interface: str | None
    def __init__(self, object_path: str, bus_name: str | None = None, interface: str | None = None) -> None: ...

class MessageGenerator:
    interface: str | None
    object_path: str
    bus_name: str
    def __init__(self, object_path: str, bus_name: str) -> None: ...

def new_method_call(
    remote_obj: DBusAddress | MessageGenerator,
    method: str,
    signature: str | None = None,
    body: tuple[Any, ...] = (),
) -> Message: ...
def new_method_return(parent_msg: Message, signature: str | None = None, body: tuple[Any, ...] = ()) -> Message: ...
def new_signal(
    emitter: DBusAddress, signal: str, signature: str | None = None, body: tuple[Any, ...] = ()
) -> Message: ...
