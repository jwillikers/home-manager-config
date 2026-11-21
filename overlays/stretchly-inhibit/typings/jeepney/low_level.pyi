from enum import Enum, IntEnum
from typing import Any

class MessageType(Enum):
    method_call = 1
    method_return = 2
    error = 3
    signal = 4

class HeaderFields(IntEnum):
    path = 1
    interface = 2
    member = 3
    error_name = 4
    reply_serial = 5
    destination = 6
    sender = 7
    signature = 8
    unix_fds = 9

class Header:
    message_type: MessageType
    serial: int
    fields: dict[HeaderFields, Any]

class Message:
    header: Header
    body: tuple[Any, ...]
