import json

from firebase_admin import credentials

from app.shared.config import config


def service_credential(content: str | None = None) -> credentials.Base | None:
    """The service account in `FIREBASE_CREDENTIALS_JSON`; without it, `None` and firebase-admin
    uses the environment default credentials (`GOOGLE_APPLICATION_CREDENTIALS`)."""
    content = config.firebase_credentials_json if content is None else content
    if not content:
        return None
    try:
        return credentials.Certificate(json.loads(content))
    except ValueError as error:
        # Without the cause text: it could carry pieces of the key.
        raise RuntimeError(
            "FIREBASE_CREDENCIALES_JSON no es el JSON de una cuenta de servicio válida"
        ) from error
