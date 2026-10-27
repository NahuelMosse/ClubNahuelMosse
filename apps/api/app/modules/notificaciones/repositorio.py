# kit-shape: el repositorio de avisos y la función que arma su fila van juntos
from collections.abc import Sequence
from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, Row, text

from app.modules.notificaciones.reglas import (
    ANTICIPACION_POR_CLASE,
    ESPERA_DEL_ENVIO,
    ESPERA_DEL_RECORDATORIO,
    Aviso,
    AvisoPerdido,
    ClaseDeRecordatorio,
    Destinatario,
    Envio,
    Notificacion,
    Pendiente,
    Recordatorio,
    ReservaAnulada,
    datos_del_aviso,
    mensaje_cancelacion_forzosa,
    mensaje_cancelaciones_forzosas,
)
from app.shared.db import Conexion, en_transaccion

# Cuántas notificaciones trae el centro: las más nuevas.
LIMITE_DEL_CENTRO = 100


# Primer número del par de `pg_advisory_xact_lock` con que se serializa, por persona, el
# agrupado de avisos de anulación.
_BLOQUEO_DE_ANULACIONES = 2402


def encolar_cancelacion_forzosa(
    conn: Connection, usuario_id: UUID, reserva_ids: Sequence[UUID]
) -> None:
    """Registra en el centro de [usuario_id] el aviso de las reservas que el club canceló, con
    el envío pendiente, dentro de la transacción de quien llama: sin commit, así que si la
    cancelación no se completa no queda aviso.

    Una reserva que ya tiene aviso se salta. Si la persona tiene un aviso de anulación sin leer,
    se abre un aviso nuevo con la cantidad total y el anterior queda reemplazado, esté o no
    saliendo en este momento: cada reserva sigue ligada al aviso que se lo informó. Si el
    anterior no había salido, sus reservas pasan al nuevo.
    """
    _bloquear_anulaciones(conn, usuario_id)
    nuevas = _anuladas_sin_aviso(conn, usuario_id, reserva_ids)
    if not nuevas:
        return
    previo = _aviso_sin_leer(conn, usuario_id)
    # Uno que está saliendo también se reemplaza: sale igual y su push lo pisa el del nuevo en
    # la bandeja, pero el centro tiene que mostrar uno solo.
    total = len(nuevas) + (0 if previo is None else int(previo.cantidad))
    notificacion_id = _abrir_aviso(conn, usuario_id, nuevas, total)
    if previo is not None:
        _reemplazar_aviso(conn, previo, notificacion_id)
    for r in nuevas:
        conn.execute(
            text(
                "INSERT INTO notificacion_reserva (notificacion_id, reserva_id)"
                " VALUES (:notificacion, :reserva)"
            ),
            {"notificacion": notificacion_id, "reserva": r.reserva_id},
        )


def _bloquear_anulaciones(conn: Connection, usuario_id: UUID) -> None:
    # Es el último bloqueo de la transacción: las anulaciones simultáneas de una misma persona
    # se esperan acá, después de los bloqueos de la cuenta, la sede, el espacio y la reserva.
    conn.execute(
        text("SELECT pg_advisory_xact_lock(:ns, hashtext(CAST(:usuario AS text)))"),
        {"ns": _BLOQUEO_DE_ANULACIONES, "usuario": usuario_id},
    )


def _anuladas_sin_aviso(
    conn: Connection, usuario_id: UUID, reserva_ids: Sequence[UUID]
) -> list[ReservaAnulada]:
    filas = conn.execute(
        text(
            "SELECT r.id, r.inicio, e.deporte, e.tipo, s.nombre AS sede, r.motivo"
            " FROM reserva r JOIN espacio e ON e.id = r.espacio_id"
            " JOIN sede s ON s.id = e.sede_id"
            " WHERE r.id = ANY(:ids) AND r.usuario_id = :usuario AND r.estado = 'anulada'"
            " AND NOT EXISTS (SELECT 1 FROM notificacion_reserva nr WHERE nr.reserva_id = r.id)"
            " ORDER BY r.inicio, r.id"
        ),
        {"ids": list(reserva_ids), "usuario": usuario_id},
    ).all()
    return [
        ReservaAnulada(
            reserva_id=f.id,
            inicio=f.inicio,
            deporte=f.deporte,
            tipo=f.tipo,
            sede=f.sede,
            motivo=f.motivo or "",
        )
        for f in filas
    ]


def _aviso_sin_leer(conn: Connection, usuario_id: UUID) -> Row[Any] | None:
    return conn.execute(
        text(
            "SELECT n.id, n.envio, coalesce(n.cantidad, 1) AS cantidad FROM notificacion n"
            " WHERE n.usuario_id = :usuario AND n.tipo = 'cancelacion_forzosa'"
            " AND n.leida_en IS NULL AND n.reemplazada_por IS NULL"
            " ORDER BY n.id DESC LIMIT 1 FOR UPDATE"
        ),
        {"usuario": usuario_id},
    ).first()


def _abrir_aviso(
    conn: Connection, usuario_id: UUID, nuevas: list[ReservaAnulada], total: int
) -> UUID:
    aviso = (
        mensaje_cancelaciones_forzosas(total) if total > 1 else mensaje_cancelacion_forzosa(nuevas)
    )
    unica = nuevas[0] if total == 1 else None
    notificacion_id: UUID = conn.execute(
        text(
            "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, reserva_id,"
            " reserva_inicio, envio, cantidad) VALUES (:usuario, 'cancelacion_forzosa',"
            " :titulo, :cuerpo, :reserva, :inicio, 'pendiente', :cantidad) RETURNING id"
        ),
        {
            "usuario": usuario_id,
            "titulo": aviso.titulo,
            "cuerpo": aviso.cuerpo,
            "reserva": None if unica is None else unica.reserva_id,
            "inicio": None if unica is None else unica.inicio,
            "cantidad": total,
        },
    ).scalar_one()
    return notificacion_id


def _reemplazar_aviso(conn: Connection, previo: Row[Any], notificacion_id: UUID) -> None:
    conn.execute(
        text("UPDATE notificacion SET reemplazada_por = :nuevo WHERE id = :id"),
        {"nuevo": notificacion_id, "id": previo.id},
    )
    if previo.envio == "pendiente":
        conn.execute(
            text(
                "UPDATE notificacion_reserva SET notificacion_id = :nuevo"
                " WHERE notificacion_id = :id"
            ),
            {"nuevo": notificacion_id, "id": previo.id},
        )


class NotificacionesSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def encolar_cancelacion_usuario(
        self, usuario_id: UUID, reserva_id: UUID, inicio: datetime, aviso: Aviso
    ) -> None:
        """Deja el aviso de la cancelación que hizo la persona, dentro de la transacción de quien
        llama: sin commit. El índice único evita repetirlo."""
        self._conn.execute(
            text(
                "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, reserva_id,"
                " reserva_inicio, envio) VALUES (:usuario, 'cancelacion_usuario', :titulo,"
                " :cuerpo, :id, :inicio, 'pendiente')"
                " ON CONFLICT (reserva_id) WHERE tipo = 'cancelacion_usuario' DO NOTHING"
            ),
            {
                "usuario": usuario_id,
                "id": reserva_id,
                "titulo": aviso.titulo,
                "cuerpo": aviso.cuerpo,
                "inicio": inicio,
            },
        )

    def vencidos(self, ahora: datetime, usuario_id: UUID | None) -> list[Recordatorio]:
        return [
            r
            for clase in ANTICIPACION_POR_CLASE
            for r in self._vencidos_de(clase, ahora, usuario_id)
        ]

    def _vencidos_de(
        self, clase: ClaseDeRecordatorio, ahora: datetime, usuario_id: UUID | None
    ) -> list[Recordatorio]:
        filas = self._conn.execute(
            text(
                "SELECT r.id, r.usuario_id, r.inicio, r.fin, e.deporte, e.tipo, s.nombre AS sede,"
                " u.correo, u.nombre AS nombre_usuario"
                " FROM reserva r JOIN espacio e ON e.id = r.espacio_id"
                " JOIN sede s ON s.id = e.sede_id JOIN usuario u ON u.id = r.usuario_id"
                " WHERE r.estado = 'activa' AND u.activo"
                " AND r.inicio > :ahora"
                " AND r.inicio <= :ahora + CAST(:anticipacion AS interval)"
                # Una reserva hecha o movida con menos anticipación que el aviso no avisa.
                " AND greatest(r.creado_en, r.modificado_en)"
                " <= r.inicio - CAST(:anticipacion AS interval)"
                " AND (CAST(:usuario AS uuid) IS NULL OR r.usuario_id = :usuario)"
                " AND NOT EXISTS (SELECT 1 FROM notificacion n WHERE n.reserva_id = r.id"
                " AND n.tipo = :clase AND n.reserva_inicio = r.inicio)"
                " ORDER BY r.inicio, r.id"
            ),
            {
                "ahora": ahora,
                "usuario": usuario_id,
                "anticipacion": ANTICIPACION_POR_CLASE[clase],
                "clase": clase,
            },
        ).all()
        self._conn.rollback()
        return [
            Recordatorio(
                reserva_id=f.id,
                usuario_id=f.usuario_id,
                inicio=f.inicio,
                fin=f.fin,
                deporte=f.deporte,
                tipo=f.tipo,
                sede=f.sede,
                correo=f.correo,
                nombre=f.nombre_usuario,
                clase=clase,
            )
            for f in filas
        ]

    def registrar(self, recordatorio: Recordatorio, aviso: Aviso) -> UUID | None:
        datos = {
            "usuario": recordatorio.usuario_id,
            "titulo": aviso.titulo,
            "cuerpo": aviso.cuerpo,
            "reserva": recordatorio.reserva_id,
            "inicio": recordatorio.inicio,
            "anticipacion": ANTICIPACION_POR_CLASE[recordatorio.clase],
            "clase": recordatorio.clase,
        }
        with en_transaccion(self._conn):
            # Entre que `vencidos` miró y acá, la reserva pudo cancelarse, anularse o moverse, o
            # la cuenta darse de baja. Se vuelve a mirar con la cuenta y la reserva compartidas,
            # en el orden de las reservas, así ninguna de las dos cambia hasta el commit.
            if not self._sigue_vigente(datos):
                self._conn.rollback()
                return None
            fila = self._conn.execute(
                text(
                    "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, reserva_id,"
                    " reserva_inicio, envio) VALUES (:usuario, :clase, :titulo, :cuerpo,"
                    " :reserva, :inicio, 'pendiente')"
                    " ON CONFLICT (reserva_id, reserva_inicio)"
                    " WHERE tipo = CAST(:clase AS text) DO NOTHING RETURNING id"
                ),
                datos,
            ).first()
        return None if fila is None else fila.id

    def _sigue_vigente(self, datos: dict[str, Any]) -> bool:
        cuenta = self._conn.execute(
            text("SELECT 1 FROM usuario WHERE id = :usuario AND activo FOR SHARE"), datos
        ).first()
        if cuenta is None:
            return False
        vigente = self._conn.execute(
            text(
                "SELECT 1 FROM reserva WHERE id = :reserva AND estado = 'activa'"
                " AND inicio = :inicio AND inicio > now()"
                " AND greatest(creado_en, modificado_en)"
                " <= inicio - CAST(:anticipacion AS interval)"
                " FOR SHARE"
            ),
            datos,
        ).first()
        return vigente is not None

    def destinatario(self, usuario_id: UUID) -> Destinatario | None:
        fila = self._conn.execute(
            text("SELECT correo, nombre FROM usuario WHERE id = :usuario AND activo"),
            {"usuario": usuario_id},
        ).first()
        self._conn.rollback()
        return None if fila is None else Destinatario(correo=fila.correo, nombre=fila.nombre)

    def tokens_con_permiso(self, usuario_id: UUID) -> list[str]:
        filas = self._conn.execute(
            text(
                "SELECT token FROM dispositivo WHERE usuario_id = :usuario AND activo"
                " AND permiso ORDER BY id"
            ),
            {"usuario": usuario_id},
        ).all()
        self._conn.rollback()
        return [f.token for f in filas]

    def tiene_dispositivos(self, usuario_id: UUID) -> bool:
        hay: bool = self._conn.execute(
            text(
                "SELECT EXISTS (SELECT 1 FROM dispositivo WHERE usuario_id = :usuario AND activo)"
            ),
            {"usuario": usuario_id},
        ).scalar_one()
        self._conn.rollback()
        return bool(hay)

    def marcar_varados_fallidos(self, usuario_id: UUID | None) -> list[AvisoPerdido]:
        with en_transaccion(self._conn):
            # Un recordatorio registrado cuyo turno ya empezó o se canceló no va a salir nunca.
            muertos = self._conn.execute(
                text(
                    "UPDATE notificacion n SET envio = 'fallida' WHERE n.envio = 'pendiente'"
                    " AND n.tipo IN ('recordatorio', 'recordatorio_cinco')"
                    " AND (CAST(:usuario AS uuid) IS NULL OR n.usuario_id = :usuario)"
                    " AND NOT EXISTS (SELECT 1 FROM reserva r WHERE r.id = n.reserva_id"
                    " AND r.estado = 'activa' AND r.inicio = n.reserva_inicio"
                    " AND r.inicio > now()) RETURNING n.id, n.tipo"
                ),
                {"usuario": usuario_id},
            ).all()
            # Uno que lleva demasiado `enviando` quedó a mitad del envío: no se vuelve a mandar.
            atascados = self._conn.execute(
                text(
                    "UPDATE notificacion SET envio = 'fallida' WHERE envio = 'enviando'"
                    " AND enviando_desde < now() - CAST(:espera AS interval)"
                    " AND (CAST(:usuario AS uuid) IS NULL OR usuario_id = :usuario)"
                    " RETURNING id, tipo"
                ),
                {"usuario": usuario_id, "espera": ESPERA_DEL_ENVIO},
            ).all()
        return [AvisoPerdido(f.id, f.tipo) for f in [*muertos, *atascados]]

    def tomar_siguiente(self, usuario_id: UUID | None) -> Pendiente | None:
        # Los que salen: los pendientes, y los recordatorios sólo si siguen vigentes y ya pasó el
        # minuto de quien los registró. `enviando` es la toma: evita mandarlo dos veces.
        f = self._conn.execute(
            text(
                "UPDATE notificacion SET envio = 'enviando', enviando_desde = now() WHERE id = ("
                " SELECT n.id FROM notificacion n LEFT JOIN reserva r ON r.id = n.reserva_id"
                " WHERE n.reemplazada_por IS NULL"
                " AND (CAST(:usuario AS uuid) IS NULL OR n.usuario_id = :usuario)"
                " AND n.envio = 'pendiente'"
                " AND (n.tipo NOT IN ('recordatorio', 'recordatorio_cinco')"
                " OR (n.creado_en < now() - CAST(:espera AS interval)"
                " AND r.estado = 'activa' AND r.inicio = n.reserva_inicio AND r.inicio > now()))"
                " ORDER BY n.id LIMIT 1 FOR UPDATE OF n SKIP LOCKED)"
                " RETURNING id, usuario_id, tipo, titulo, cuerpo, reserva_id"
            ),
            {"usuario": usuario_id, "espera": ESPERA_DEL_RECORDATORIO},
        ).first()
        self._conn.commit()
        if f is None:
            return None
        return Pendiente(
            notificacion_id=f.id,
            usuario_id=f.usuario_id,
            aviso=Aviso(
                titulo=f.titulo,
                cuerpo=f.cuerpo,
                datos=datos_del_aviso(f.tipo, None if f.reserva_id is None else f.reserva_id),
            ),
        )

    def marcar_envio(self, notificacion_id: UUID, envio: Envio) -> None:
        self._conn.execute(
            text(
                "UPDATE notificacion SET envio = CAST(:envio AS text),"
                " enviada_en = CASE WHEN CAST(:envio AS text) = 'enviada' THEN now() END"
                " WHERE id = :id"
            ),
            {"envio": envio, "id": notificacion_id},
        )
        self._conn.commit()

    def dar_de_baja_tokens(self, tokens: Sequence[str]) -> None:
        if not tokens:
            return
        self._conn.execute(
            text(
                "UPDATE dispositivo SET activo = false, dado_de_baja_en = now()"
                " WHERE token = ANY(:tokens) AND activo"
            ),
            {"tokens": list(tokens)},
        )
        self._conn.commit()

    def registrar_dispositivo(
        self,
        usuario_id: UUID,
        token: str,
        plataforma: str,
        permiso: bool,  # noqa: FBT001
    ) -> bool:
        datos = {
            "usuario": usuario_id,
            "token": token,
            "plataforma": plataforma,
            "permiso": permiso,
        }
        with en_transaccion(self._conn):
            # La cuenta se toma compartida, como al reservar: no se da de baja en el medio.
            cuenta = self._conn.execute(
                text("SELECT 1 FROM usuario WHERE id = :usuario AND activo FOR SHARE"), datos
            ).first()
            if cuenta is None:
                self._conn.rollback()
                return False
            self._conn.execute(
                text(
                    "INSERT INTO dispositivo (usuario_id, token, plataforma, permiso)"
                    " VALUES (:usuario, :token, :plataforma, :permiso)"
                    " ON CONFLICT (token) WHERE activo DO UPDATE SET"
                    " usuario_id = EXCLUDED.usuario_id, plataforma = EXCLUDED.plataforma,"
                    " permiso = EXCLUDED.permiso, modificado_en = now()"
                    " WHERE dispositivo.usuario_id = EXCLUDED.usuario_id"
                ),
                datos,
            )
        return True

    def baja_dispositivo(self, usuario_id: UUID, token: str) -> None:
        self._conn.execute(
            text(
                "UPDATE dispositivo SET activo = false, dado_de_baja_en = now()"
                " WHERE usuario_id = :usuario AND token = :token AND activo"
            ),
            {"usuario": usuario_id, "token": token},
        )
        self._conn.commit()

    def de_usuario(self, usuario_id: UUID) -> tuple[list[Notificacion], int]:
        filas = self._conn.execute(
            text(
                "SELECT id, tipo, titulo, cuerpo, reserva_id, creado_en AS creada_en,"
                " leida_en IS NOT NULL AS leida FROM notificacion WHERE usuario_id = :usuario"
                " AND reemplazada_por IS NULL"
                f" ORDER BY creado_en DESC, id DESC LIMIT {LIMITE_DEL_CENTRO}"
            ),
            {"usuario": usuario_id},
        ).all()
        sin_leer: int = self._conn.execute(
            text(
                "SELECT count(*) FROM notificacion WHERE usuario_id = :usuario AND leida_en IS NULL"
                " AND reemplazada_por IS NULL"
            ),
            {"usuario": usuario_id},
        ).scalar_one()
        self._conn.rollback()
        return (
            [
                Notificacion(
                    id=f.id,
                    tipo=f.tipo,
                    titulo=f.titulo,
                    cuerpo=f.cuerpo,
                    reserva_id=None if f.reserva_id is None else f.reserva_id,
                    creada_en=f.creada_en,
                    leida=bool(f.leida),
                )
                for f in filas
            ],
            int(sin_leer),
        )

    def leer(self, usuario_id: UUID, notificacion_id: UUID) -> bool:
        fila = self._conn.execute(
            text(
                "UPDATE notificacion SET leida_en = coalesce(leida_en, now())"
                " WHERE id = :id AND usuario_id = :usuario RETURNING id"
            ),
            {"id": notificacion_id, "usuario": usuario_id},
        ).first()
        self._conn.commit()
        return fila is not None

    def leer_todas(self, usuario_id: UUID) -> None:
        self._conn.execute(
            text(
                "UPDATE notificacion SET leida_en = now()"
                " WHERE usuario_id = :usuario AND leida_en IS NULL"
            ),
            {"usuario": usuario_id},
        )
        self._conn.commit()


def repositorio_notificaciones(conn: Conexion) -> NotificacionesSql:
    return NotificacionesSql(conn)
