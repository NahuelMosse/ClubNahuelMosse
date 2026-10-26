import pytest

from app.shared.config import Config


@pytest.mark.parametrize("esquema", ["postgres", "postgresql"])
def test_la_url_de_render_recibe_el_driver_de_psycopg(esquema: str) -> None:
    config = Config(_env_file=None, database_url=f"{esquema}://u:p@host:5432/base")

    assert config.database_url == "postgresql+psycopg://u:p@host:5432/base"


def test_una_url_que_ya_nombra_el_driver_no_cambia() -> None:
    url = "postgresql+psycopg://club:club@localhost:5432/club"

    assert Config(_env_file=None, database_url=url).database_url == url
