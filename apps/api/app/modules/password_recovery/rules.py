# kit-shape: the types of the message, the recipient and the claimed link are a single concept
from dataclasses import dataclass
from uuid import UUID


@dataclass(frozen=True)
class Message:
    recipient: str
    subject: str
    body: str


@dataclass(frozen=True)
class Recipient:
    """The active account the link is sent to."""

    id: UUID
    first_name: str
    email: str


@dataclass(frozen=True)
class ClaimedLink:
    """A link that was just marked as used, with the account it belongs to."""

    id: UUID
    user_id: UUID
    uid: str
