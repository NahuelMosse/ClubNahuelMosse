import json
import logging
import smtplib
import ssl
import urllib.request
from email.message import EmailMessage

from sqlalchemy import text

from app.modules.recuperacion.reglas import Mensaje
from app.shared.config import config
from app.shared.db import motor

correo_log = logging.getLogger("clubnahuelmosse.correo")

BREVO_URL = "https://api.brevo.com/v3/smtp/email"
REMITENTE_NOMBRE = "Club Nahuel Mosse"


def _al_buzon(mensaje: Mensaje) -> None:
    with motor().begin() as conn:
        conn.execute(
            text("INSERT INTO correo_saliente (para, asunto, cuerpo) VALUES (:p, :a, :c)"),
            {"p": mensaje.para, "a": mensaje.asunto, "c": mensaje.cuerpo},
        )


def _por_smtp(mensaje: Mensaje) -> None:
    if not config.smtp_host or not config.correo_remitente:
        raise RuntimeError("faltan SMTP_HOST y CORREO_REMITENTE para enviar correos")
    correo = EmailMessage()
    correo["From"] = config.correo_remitente
    correo["To"] = mensaje.para
    correo["Subject"] = mensaje.asunto
    correo.set_content(mensaje.cuerpo)
    if mensaje.html is not None:
        correo.add_alternative(mensaje.html, subtype="html")
    with smtplib.SMTP(config.smtp_host, config.smtp_puerto, timeout=10) as smtp:
        smtp.starttls(context=ssl.create_default_context())
        smtp.login(config.smtp_usuario, config.smtp_contrasena)
        smtp.send_message(correo)


def _por_brevo(mensaje: Mensaje) -> None:
    contenido = {
        "sender": {"email": config.correo_remitente, "name": REMITENTE_NOMBRE},
        "to": [{"email": mensaje.para}],
        "subject": mensaje.asunto,
        "textContent": mensaje.cuerpo,
    }
    if mensaje.html is not None:
        contenido["htmlContent"] = mensaje.html
    pedido = urllib.request.Request(
        BREVO_URL,
        data=json.dumps(contenido).encode(),
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


_ENVIADORES = {"buzon": _al_buzon, "smtp": _por_smtp, "brevo": _por_brevo}


def enviar(mensaje: Mensaje) -> None:
    """Se corre después de responder. Si falla queda en el log: la respuesta ya fue la misma
    que para un correo sin cuenta, y un error contaría que la cuenta existe."""
    try:
        _ENVIADORES[config.correo_modo](mensaje)
    except Exception as e:
        # Sin traceback ni texto de la excepción: ambos pueden traer la dirección del destinatario.
        correo_log.error("no se pudo enviar el correo «%s»: %s", mensaje.asunto, type(e).__name__)
