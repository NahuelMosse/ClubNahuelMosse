"""El barrido que manda los recordatorios cuando les toca, en segundo plano."""

import asyncio
import logging
from datetime import UTC, datetime

from app.aplicacion.notificaciones import enviar_recordatorios
from app.infraestructura.db import motor
from app.infraestructura.notificaciones import NotificacionesSql
from app.infraestructura.push import canal_push

_registro = logging.getLogger(__name__)


def barrer_una_vez() -> int:
    with motor().connect() as conn:
        return enviar_recordatorios(NotificacionesSql(conn), canal_push(), datetime.now(UTC))


async def barrer_cada(segundos: int) -> None:
    while True:
        await asyncio.sleep(segundos)
        try:
            await asyncio.to_thread(barrer_una_vez)
        except Exception:
            # Un barrido que falla (la base un instante caída) no tiene que matar al siguiente.
            _registro.exception("el barrido de recordatorios falló")
