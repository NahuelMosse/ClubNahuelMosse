import json
import logging
import smtplib
import ssl
import urllib.request
from email.message import EmailMessage

from sqlalchemy import text

from app.shared.config import config
from app.shared.db import engine
from app.shared.message import Message

email_log = logging.getLogger("clubnahuelmosse.correo")

BREVO_URL = "https://api.brevo.com/v3/smtp/email"
SENDER_NAME = "Club Nahuel Mosse"


def _to_outbox(message: Message) -> None:
    with engine().begin() as conn:
        conn.execute(
            text(
                "INSERT INTO outgoing_email (recipient, subject, body)"
                " VALUES (:recipient, :subject, :body)"
            ),
            {"recipient": message.recipient, "subject": message.subject, "body": message.body},
        )


def _by_smtp(message: Message) -> None:
    if not config.smtp_host or not config.email_sender:
        raise RuntimeError("faltan SMTP_HOST y CORREO_REMITENTE para enviar correos")
    email_message = EmailMessage()
    email_message["From"] = config.email_sender
    email_message["To"] = message.recipient
    email_message["Subject"] = message.subject
    email_message.set_content(message.body)
    if message.html is not None:
        email_message.add_alternative(message.html, subtype="html")
    with smtplib.SMTP(config.smtp_host, config.smtp_port, timeout=10) as smtp:
        smtp.starttls(context=ssl.create_default_context())
        smtp.login(config.smtp_user, config.smtp_password)
        smtp.send_message(email_message)


def _by_brevo(message: Message) -> None:
    payload = {
        "sender": {"email": config.email_sender, "name": SENDER_NAME},
        "to": [{"email": message.recipient}],
        "subject": message.subject,
        "textContent": message.body,
    }
    if message.html is not None:
        payload["htmlContent"] = message.html
    request = urllib.request.Request(
        BREVO_URL,
        data=json.dumps(payload).encode(),
        headers={
            "api-key": config.brevo_api_key,
            "content-type": "application/json",
            "accept": "application/json",
        },
        method="POST",
    )
    # urlopen already raises HTTPError on a 4xx or 5xx; any other 2xx is fine.
    with urllib.request.urlopen(request, timeout=10):  # noqa: S310 - the URL is fixed and https
        pass


_SENDERS = {"outbox": _to_outbox, "smtp": _by_smtp, "brevo": _by_brevo}


def send(message: Message) -> None:
    """Runs after responding. If it fails it stays in the log: the response was already the same
    as for an email without an account, and an error would reveal that the account exists."""
    try:
        _SENDERS[config.email_mode](message)
    except Exception as e:
        # No traceback or exception text: both may carry the recipient's address.
        email_log.error("no se pudo enviar el correo «%s»: %s", message.subject, type(e).__name__)
