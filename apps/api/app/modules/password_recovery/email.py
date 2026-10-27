import logging
import smtplib
import ssl
from email.message import EmailMessage

from sqlalchemy import text

from app.modules.password_recovery.rules import Message
from app.shared.config import config
from app.shared.db import engine

email_log = logging.getLogger("clubnahuelmosse.correo")


def _to_outbox(message: Message) -> None:
    with engine().begin() as conn:
        conn.execute(
            text("INSERT INTO correo_saliente (para, asunto, cuerpo) VALUES (:p, :a, :c)"),
            {"p": message.recipient, "a": message.subject, "c": message.body},
        )


def _by_smtp(message: Message) -> None:
    if not config.smtp_host or not config.email_sender:
        raise RuntimeError("faltan SMTP_HOST y CORREO_REMITENTE para enviar correos")
    email_message = EmailMessage()
    email_message["From"] = config.email_sender
    email_message["To"] = message.recipient
    email_message["Subject"] = message.subject
    email_message.set_content(message.body)
    with smtplib.SMTP(config.smtp_host, config.smtp_port, timeout=10) as smtp:
        smtp.starttls(context=ssl.create_default_context())
        smtp.login(config.smtp_user, config.smtp_password)
        smtp.send_message(email_message)


def send(message: Message) -> None:
    """Runs after responding. If it fails it stays in the log: the response was already the same
    as for an email without an account, and an error would reveal that the account exists."""
    try:
        (_to_outbox if config.email_mode == "outbox" else _by_smtp)(message)
    except Exception as e:
        # No traceback or exception text: both may carry the recipient's address.
        email_log.error("no se pudo enviar el correo «%s»: %s", message.subject, type(e).__name__)
