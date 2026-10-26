from collections.abc import Sequence
from datetime import datetime
from typing import Protocol

from app.modules.notificaciones.reglas import (
    Aviso,
    AvisoPerdido,
    Envio,
    Notificacion,
    Pendiente,
    Recordatorio,
)


class Notificaciones(Protocol):
    def vencidos(self, ahora: datetime, usuario_id: int | None) -> list[Recordatorio]:
        """Las reservas activas que empiezan dentro de la hora siguiente a [ahora], hechas o
        modificadas con una hora o más de anticipación y sin aviso para su horario actual."""
        ...

    def registrar(self, recordatorio: Recordatorio, aviso: Aviso) -> int | None:
        """Guarda el aviso en el centro. `None` si ya estaba: otro barrido lo registró."""
        ...

    def tokens_con_permiso(self, usuario_id: int) -> list[str]: ...

    def tiene_dispositivos(self, usuario_id: int) -> bool:
        """Si [usuario_id] tiene algún dispositivo registrado, con o sin permiso."""
        ...

    def marcar_varados_fallidos(self, usuario_id: int | None) -> list[AvisoPerdido]:
        """Pasa a `fallida`, y devuelve, los recordatorios registrados de [usuario_id] o de
        todos cuyo turno ya empezó o se canceló: no van a salir."""
        ...

    def tomar_siguiente(self, usuario_id: int | None) -> Pendiente | None:
        """Reserva para quien llama el aviso más viejo de [usuario_id] o de todos que está
        sin enviar —un recordatorio sólo si sigue vigente—: pasa a `enviando`, así dos despachos
        al mismo tiempo no mandan el mismo dos veces. `None` si no queda ninguno."""
        ...

    def marcar_envio(self, notificacion_id: int, envio: Envio) -> None: ...

    def dar_de_baja_tokens(self, tokens: Sequence[str]) -> None: ...

    def registrar_dispositivo(
        self, usuario_id: int, token: str, plataforma: str, permiso: bool
    ) -> bool:
        """Deja el dispositivo a nombre de [usuario_id]. `False` si la cuenta ya no está
        activa."""
        ...

    def baja_dispositivo(self, usuario_id: int, token: str) -> None: ...

    def de_usuario(self, usuario_id: int) -> tuple[list[Notificacion], int]:
        """Las últimas notificaciones, de la más nueva a la más vieja, y cuántas hay sin
        leer en total."""
        ...

    def leer(self, usuario_id: int, notificacion_id: int) -> bool:
        """Marca como leída una notificación propia. `False` si no es de [usuario_id]."""
        ...

    def leer_todas(self, usuario_id: int) -> None: ...
