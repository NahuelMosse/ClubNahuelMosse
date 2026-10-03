import json

from firebase_admin import credentials

from app.config import config


def credencial_de_servicio(contenido: str | None = None) -> credentials.Base | None:
    """La cuenta de servicio de `FIREBASE_CREDENCIALES_JSON`; sin ella, `None` y firebase-admin
    usa las credenciales por defecto del entorno (`GOOGLE_APPLICATION_CREDENTIALS`)."""
    contenido = config.firebase_credenciales_json if contenido is None else contenido
    if not contenido:
        return None
    try:
        return credentials.Certificate(json.loads(contenido))
    except ValueError as error:
        # Sin el texto de la causa: podría traer pedazos de la clave.
        raise RuntimeError(
            "FIREBASE_CREDENCIALES_JSON no es el JSON de una cuenta de servicio válida"
        ) from error
