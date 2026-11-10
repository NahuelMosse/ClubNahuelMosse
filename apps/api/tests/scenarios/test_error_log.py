"""Minimal scenario the Firebase emulator needs: the reliable suite tests use it."""

from fastapi.testclient import TestClient


def test_a_request_without_a_session_is_rejected_with_401(api: TestClient) -> None:
    assert api.get("/me").status_code == 401
