from app.modules.notifications.rules import Notice, Recipient
from app.shared.email_template import html_email
from app.shared.message import Message

BUTTON_TEXT = "Abrir la app"


def notice_email(notice: Notice, recipient: Recipient, public_url: str) -> Message:
    """The notice by email with the app's template: its title and body and, if a public link is
    configured, the button that opens the app."""
    greeting = f"Hola {recipient.name}:" if recipient.name else "Hola:"
    paragraphs = [greeting, notice.body]
    button = (BUTTON_TEXT, public_url) if public_url else None
    return Message(
        recipient=recipient.email,
        subject=notice.title,
        body="\n\n".join([notice.title, *paragraphs]),
        html=html_email(notice.title, paragraphs, button),
    )
