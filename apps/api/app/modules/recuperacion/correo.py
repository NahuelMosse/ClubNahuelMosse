import logging
import smtplib
import ssl
from email.message import EmailMessage

from sqlalchemy import text

from app.modules.recuperacion.reglas import Mensaje
from app.shared.config import config
from app.shared.db import engine

correo_log = logging.getLogger("clubnahuelmosse.correo")


def _al_buzon(mensaje: Mensaje) -> None:
    with engine().begin() as conn:
        conn.execute(
            text("INSERT INTO correo_saliente (para, asunto, cuerpo) VALUES (:p, :a, :c)"),
            {"p": mensaje.para, "a": mensaje.asunto, "c": mensaje.cuerpo},
        )


def _por_smtp(mensaje: Mensaje) -> None:
    if not config.smtp_host or not config.email_sender:
        raise RuntimeError("faltan SMTP_HOST y CORREO_REMITENTE para enviar correos")
    correo = EmailMessage()
    correo["From"] = config.email_sender
    correo["To"] = mensaje.para
    correo["Subject"] = mensaje.asunto
    correo.set_content(mensaje.cuerpo)
    with smtplib.SMTP(config.smtp_host, config.smtp_port, timeout=10) as smtp:
        smtp.starttls(context=ssl.create_default_context())
        smtp.login(config.smtp_user, config.smtp_password)
        smtp.send_message(correo)


def enviar(mensaje: Mensaje) -> None:
    """Se corre después de responder. Si falla queda en el log: la respuesta ya fue la misma
    que para un correo sin cuenta, y un error contaría que la cuenta existe."""
    try:
        (_al_buzon if config.email_mode == "outbox" else _por_smtp)(mensaje)
    except Exception as e:
        # Sin traceback ni texto de la excepción: ambos pueden traer la dirección del destinatario.
        correo_log.error("no se pudo enviar el correo «%s»: %s", mensaje.asunto, type(e).__name__)
