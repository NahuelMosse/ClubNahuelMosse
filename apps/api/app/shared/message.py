from dataclasses import dataclass


@dataclass(frozen=True)
class Message:
    recipient: str
    subject: str
    body: str
    html: str | None = None
