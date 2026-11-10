from fastapi.testclient import TestClient

from app.main import app


def test_head_on_a_get_route_answers_405() -> None:
    """HEAD on a GET route answers 405, as on main @assumption:ENG-22-ASM-08"""
    response = TestClient(app).head("/health")
    assert response.status_code == 405
