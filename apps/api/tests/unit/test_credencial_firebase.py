import json

import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from firebase_admin import credentials

from app.shared.credencial_firebase import credencial_de_servicio


def _cuenta_de_servicio() -> str:
    clave = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    pem = clave.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    ).decode()
    return json.dumps(
        {
            "type": "service_account",
            "project_id": "demo",
            "private_key_id": "k",
            "private_key": pem,
            "client_email": "firebase@demo.iam.gserviceaccount.com",
            "client_id": "1",
            "token_uri": "https://oauth2.googleapis.com/token",
        }
    )


def test_el_json_de_la_cuenta_de_servicio_se_convierte_en_credencial() -> None:
    credencial = credencial_de_servicio(_cuenta_de_servicio())

    assert isinstance(credencial, credentials.Certificate)
    assert credencial.project_id == "demo"


def test_sin_json_no_hay_credencial_propia() -> None:
    assert credencial_de_servicio("") is None


def test_un_json_roto_falla_sin_mostrar_su_contenido() -> None:
    with pytest.raises(RuntimeError) as error:
        credencial_de_servicio('{"private_key": "secreto-123"')

    assert "secreto-123" not in str(error.value)
    assert "secreto-123" not in repr(error.value.__cause__)
