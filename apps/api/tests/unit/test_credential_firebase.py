import json

import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from firebase_admin import credentials

from app.shared.firebase_credential import service_credential


def _service_account() -> str:
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    pem = key.private_bytes(
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


def test_the_service_account_json_becomes_a_credential() -> None:
    credential = service_credential(_service_account())

    assert isinstance(credential, credentials.Certificate)
    assert credential.project_id == "demo"


def test_without_json_there_is_no_own_credential() -> None:
    assert service_credential("") is None


def test_a_broken_json_fails_without_showing_its_content() -> None:
    with pytest.raises(RuntimeError) as error:
        service_credential('{"private_key": "secreto-123"')

    assert "secreto-123" not in str(error.value)
    assert "secreto-123" not in repr(error.value.__cause__)
