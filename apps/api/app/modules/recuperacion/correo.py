import json
import logging
import smtplib
import ssl
import urllib.request
from email.message import EmailMessage

from sqlalchemy import text

from app.modules.recuperacion.reglas import Mensaje
from app.shared.config import config
from app.shared.db import engine

correo_log = logging.getLogger("clubnahuelmosse.correo")

BREVO_URL = "https://api.brevo.com/v3/smtp/email"
REMITENTE_NOMBRE = "Club Nahuel Mosse"


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


def _por_brevo(mensaje: Mensaje) -> None:
    pedido = urllib.request.Request(
        BREVO_URL,
        data=json.dumps(
            {
                "sender": {"email": config.email_sender, "name": REMITENTE_NOMBRE},
                "to": [{"email": mensaje.para}],
                "subject": mensaje.asunto,
                "textContent": mensaje.cuerpo,
            }
        ).encode(),
        headers={
            "api-key": config.brevo_api_key,
            "content-type": "application/json",
            "accept": "application/json",
        },
        method="POST",
    )
    # urlopen ya levanta HTTPError ante un 4xx o 5xx; el resto de los 2xx sirve.
    with urllib.request.urlopen(pedido, timeout=10):  # noqa: S310 - la URL es fija y https
        pass


_ENVIADORES = {"outbox": _al_buzon, "smtp": _por_smtp, "brevo": _por_brevo}


def enviar(mensaje: Mensaje) -> None:
    """Se corre después de responder. Si falla queda en el log: la respuesta ya fue la misma
    que para un correo sin cuenta, y un error contaría que la cuenta existe."""
    try:
        _ENVIADORES[config.email_mode](mensaje)
    except Exception as e:
        # Sin traceback ni texto de la excepción: ambos pueden traer la dirección del destinatario.
        correo_log.error("no se pudo enviar el correo «%s»: %s", mensaje.asunto, type(e).__name__)
