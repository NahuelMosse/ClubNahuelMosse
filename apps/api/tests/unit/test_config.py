import pytest

from app.shared.config import Settings


@pytest.mark.parametrize("scheme", ["postgres", "postgresql"])
def test_the_render_url_gets_the_psycopg_driver(scheme: str) -> None:
    config = Settings(_env_file=None, database_url=f"{scheme}://u:p@host:5432/base")

    assert config.database_url == "postgresql+psycopg://u:p@host:5432/base"


def test_a_url_that_already_names_the_driver_does_not_change() -> None:
    url = "postgresql+psycopg://club:club@localhost:5432/club"

    assert Settings(_env_file=None, database_url=url).database_url == url
