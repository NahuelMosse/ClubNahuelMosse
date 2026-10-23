"""El barrido que manda los recordatorios cuando les toca, en segundo plano."""

import argparse
import asyncio
import logging
import sys
from datetime import UTC, datetime

from app.aplicacion.notificaciones import CanalPush, despachar_pendientes, enviar_recordatorios
from app.dependencias import NotificacionesSql, canal_push, motor

_registro = logging.getLogger(__name__)


def barrer_una_vez() -> int:
    with motor().connect() as conn:
        notificaciones = NotificacionesSql(conn)
        canal = canal_push()
        # Lo que se registró con un hecho y no llegó a salir, por ejemplo si el servidor se
        # cayó justo después de cancelar. Si falla, los recordatorios salen igual.
        try:
            despachar_pendientes(notificaciones, canal)
        except Exception:
            _registro.exception("el despacho de avisos pendientes falló")
        return enviar_recordatorios(notificaciones, canal, datetime.now(UTC))


def despachar_de(usuario_id: int, canal: CanalPush) -> None:
    """Manda lo que quedó pendiente de [usuario_id], con su propia conexión: corre cuando la
    respuesta ya salió. Un fallo acá no cambia lo que la persona hizo; el barrido lo retoma."""
    try:
        with motor().connect() as conn:
            despachar_pendientes(NotificacionesSql(conn), canal, usuario_id)
    except Exception:
        _registro.exception("el despacho de avisos falló")


def main(argumentos: list[str] | None = None) -> int:
    """Corre un barrido y termina: lo lanza un cron aparte del servicio web, que en el plan
    gratuito duerme."""
    parser = argparse.ArgumentParser(description="Manda los recordatorios que ya les toca.")
    parser.add_argument("--una-vez", action="store_true", required=True)
    parser.parse_args(argumentos)
    logging.basicConfig(level=logging.INFO)
    try:
        enviados = barrer_una_vez()
    except Exception:
        _registro.exception("barrido_fallido")
        return 1
    _registro.info("barrido_ok recordatorios=%s", enviados)
    return 0


async def barrer_cada(segundos: int) -> None:
    while True:
        await asyncio.sleep(segundos)
        try:
            await asyncio.to_thread(barrer_una_vez)
        except Exception:
            # Un barrido que falla (la base un instante caída) no tiene que matar al siguiente.
            _registro.exception("el barrido de recordatorios falló")


if __name__ == "__main__":
    sys.exit(main())
