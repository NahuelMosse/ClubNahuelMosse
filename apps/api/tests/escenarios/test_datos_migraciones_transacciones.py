"""Datos: cada migración corre en su propia transacción, en una base propia por corrida."""

from typing import Any

from alembic import command
from alembic.config import Config as AlembicConfig
from sqlalchemy import Engine, event
from test_datos_migraciones_lock import base_propia  # noqa: F401 — fixture


def test_cada_migracion_hace_su_propio_commit(
    base_propia: tuple[Engine, AlembicConfig],  # noqa: F811
) -> None:
    """el upgrade commitea una vez por migración, no una sola al final
    @REV-03-S7 @assumption:REV-03-ASM-15
    """
    _, alembic = base_propia
    commits: list[Any] = []

    def contar(conn: Any) -> None:
        commits.append(conn)

    event.listen(Engine, "commit", contar)
    try:
        command.upgrade(alembic, "0006")
    finally:
        event.remove(Engine, "commit", contar)

    assert len(commits) >= 6
