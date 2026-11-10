"""API security: the body that is not JSON."""

from fastapi.testclient import TestClient

HEADERS = {"Content-Type": "application/json"}


def test_a_non_json_body_answers_400_and_an_invalid_shape_422(api: TestClient) -> None:
    """a body that is not valid JSON answers 400 and does not repeat what it received; data with an invalid shape stays at 422 @REV-01-S5 @assumption:REV-01-ASM-16"""
    broken = api.post("/register", content='{"name": "SECRETO-ZZ9', headers=HEADERS)
    assert broken.status_code == 400
    assert broken.json() == {"errors": {"body": "The body is not valid JSON"}}
    assert "SECRETO-ZZ9" not in broken.text

    shape = api.post("/register", json={"name": 5})
    assert shape.status_code == 422
    assert "errors" in shape.json()
