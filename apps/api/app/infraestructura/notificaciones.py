from collections.abc import Sequence
from datetime import datetime

from sqlalchemy import Connection, text

from app.aplicacion.notificaciones import Pendiente
from app.dominio.notificaciones import (
    Aviso,
    Envio,
    Notificacion,
    Recordatorio,
    ReservaAnulada,
    datos_del_aviso,
    mensaje_cancelacion_forzosa,
    mensaje_cancelaciones_forzosas,
)

# Cuántas notificaciones trae el centro: las más nuevas.
LIMITE_DEL_CENTRO = 100


# Primer número del par de `pg_advisory_xact_lock` con que se serializa, por persona, el
# agrupado de avisos de anulación.
_BLOQUEO_DE_ANULACIONES = 2402


def encolar_cancelacion_forzosa(
    conn: Connection, usuario_id: int, reserva_ids: Sequence[int]
) -> None:
    """Registra en el centro de [usuario_id] el aviso de las reservas que el club canceló, con
    el envío pendiente, dentro de la transacción de quien llama: sin commit, así que si la
    cancelación no se completa no queda aviso.

    Una reserva que ya tiene aviso se salta. Si la persona tiene un aviso de anulación sin leer,
    se abre un aviso nuevo con la cantidad total y el anterior queda reemplazado, esté o no
    saliendo en este momento: cada reserva sigue ligada al aviso que se lo informó. Si el
    anterior no había salido, sus reservas pasan al nuevo.
    """
    # Es el último bloqueo de la transacción: las anulaciones simultáneas de una misma persona
    # se esperan acá, después de los bloqueos de la cuenta, la sede, el espacio y la reserva.
    conn.execute(
        text("SELECT pg_advisory_xact_lock(:ns, CAST(:usuario AS integer))"),
        {"ns": _BLOQUEO_DE_ANULACIONES, "usuario": usuario_id},
    )
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
    if not filas:
        return
    nuevas = [
        ReservaAnulada(
            reserva_id=int(f.id),
            inicio=f.inicio,
            deporte=f.deporte,
            tipo=f.tipo,
            sede=f.sede,
            motivo=f.motivo or "",
        )
        for f in filas
    ]
    previo = conn.execute(
        text(
            "SELECT n.id, n.envio, coalesce(n.cantidad, 1) AS cantidad FROM notificacion n"
            " WHERE n.usuario_id = :usuario AND n.tipo = 'cancelacion_forzosa'"
            " AND n.leida_en IS NULL AND n.reemplazada_por IS NULL"
            " ORDER BY n.id DESC LIMIT 1 FOR UPDATE"
        ),
        {"usuario": usuario_id},
    ).first()
    # Uno que está saliendo también se reemplaza: sale igual y su push lo pisa el del nuevo en
    # la bandeja, pero el centro tiene que mostrar uno solo.
    reemplaza = previo
    total = len(nuevas) + (0 if reemplaza is None else int(reemplaza.cantidad))
    aviso = (
        mensaje_cancelaciones_forzosas(total) if total > 1 else mensaje_cancelacion_forzosa(nuevas)
    )
    unica = nuevas[0] if total == 1 else None
    notificacion_id = int(
        conn.execute(
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
    )
    if reemplaza is not None:
        conn.execute(
            text("UPDATE notificacion SET reemplazada_por = :nuevo WHERE id = :id"),
            {"nuevo": notificacion_id, "id": reemplaza.id},
        )
        if reemplaza.envio == "pendiente":
            conn.execute(
                text(
                    "UPDATE notificacion_reserva SET notificacion_id = :nuevo"
                    " WHERE notificacion_id = :id"
                ),
                {"nuevo": notificacion_id, "id": reemplaza.id},
            )
    for r in nuevas:
        conn.execute(
            text(
                "INSERT INTO notificacion_reserva (notificacion_id, reserva_id)"
                " VALUES (:notificacion, :reserva)"
            ),
            {"notificacion": notificacion_id, "reserva": r.reserva_id},
        )


class NotificacionesSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def vencidos(self, ahora: datetime, usuario_id: int | None) -> list[Recordatorio]:
        filas = self._conn.execute(
            text(
                "SELECT r.id, r.usuario_id, r.inicio, r.fin, e.deporte, e.tipo, s.nombre AS sede"
                " FROM reserva r JOIN espacio e ON e.id = r.espacio_id"
                " JOIN sede s ON s.id = e.sede_id JOIN usuario u ON u.id = r.usuario_id"
                " WHERE r.estado = 'activa' AND u.activo"
                " AND r.inicio > :ahora AND r.inicio <= :ahora + interval '1 hour'"
                # Una reserva hecha o movida con menos de una hora de anticipación no avisa.
                " AND greatest(r.creado_en, r.modificado_en) <= r.inicio - interval '1 hour'"
                " AND (CAST(:usuario AS bigint) IS NULL OR r.usuario_id = :usuario)"
                " AND NOT EXISTS (SELECT 1 FROM notificacion n WHERE n.reserva_id = r.id"
                " AND n.tipo = 'recordatorio' AND n.reserva_inicio = r.inicio)"
                " ORDER BY r.inicio, r.id"
            ),
            {"ahora": ahora, "usuario": usuario_id},
        ).all()
        self._conn.rollback()
        return [
            Recordatorio(
                reserva_id=int(f.id),
                usuario_id=int(f.usuario_id),
                inicio=f.inicio,
                fin=f.fin,
                deporte=f.deporte,
                tipo=f.tipo,
                sede=f.sede,
            )
            for f in filas
        ]

    def registrar(self, recordatorio: Recordatorio, aviso: Aviso) -> int | None:
        datos = {
            "usuario": recordatorio.usuario_id,
            "titulo": aviso.titulo,
            "cuerpo": aviso.cuerpo,
            "reserva": recordatorio.reserva_id,
            "inicio": recordatorio.inicio,
        }
        try:
            # Entre que `vencidos` miró y acá, la reserva pudo cancelarse, anularse o moverse, o
            # la cuenta darse de baja. Se vuelve a mirar con la cuenta y la reserva compartidas,
            # en el orden de las reservas, así ninguna de las dos cambia hasta el commit.
            cuenta = self._conn.execute(
                text("SELECT 1 FROM usuario WHERE id = :usuario AND activo FOR SHARE"), datos
            ).first()
            vigente = None
            if cuenta is not None:
                vigente = self._conn.execute(
                    text(
                        "SELECT 1 FROM reserva WHERE id = :reserva AND estado = 'activa'"
                        " AND inicio = :inicio AND inicio > now()"
                        " AND greatest(creado_en, modificado_en) <= inicio - interval '1 hour'"
                        " FOR SHARE"
                    ),
                    datos,
                ).first()
            if vigente is None:
                self._conn.rollback()
                return None
            fila = self._conn.execute(
                text(
                    "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, reserva_id,"
                    " reserva_inicio, envio) VALUES (:usuario, 'recordatorio', :titulo, :cuerpo,"
                    " :reserva, :inicio, 'pendiente')"
                    " ON CONFLICT (reserva_id, reserva_inicio) WHERE tipo = 'recordatorio'"
                    " DO NOTHING RETURNING id"
                ),
                datos,
            ).first()
            self._conn.commit()
        except BaseException:
            self._conn.rollback()
            raise
        return None if fila is None else int(fila.id)

    def tokens_con_permiso(self, usuario_id: int) -> list[str]:
        filas = self._conn.execute(
            text(
                "SELECT token FROM dispositivo WHERE usuario_id = :usuario AND activo"
                " AND permiso ORDER BY id"
            ),
            {"usuario": usuario_id},
        ).all()
        self._conn.rollback()
        return [f.token for f in filas]

    def tiene_dispositivos(self, usuario_id: int) -> bool:
        hay: bool = self._conn.execute(
            text(
                "SELECT EXISTS (SELECT 1 FROM dispositivo WHERE usuario_id = :usuario AND activo)"
            ),
            {"usuario": usuario_id},
        ).scalar_one()
        self._conn.rollback()
        return bool(hay)

    def tomar_siguiente(self, usuario_id: int | None) -> Pendiente | None:
        f = self._conn.execute(
            text(
                "UPDATE notificacion SET envio = 'enviando' WHERE id = ("
                " SELECT id FROM notificacion WHERE envio = 'pendiente'"
                " AND tipo <> 'recordatorio' AND reemplazada_por IS NULL"
                " AND (CAST(:usuario AS bigint) IS NULL OR usuario_id = :usuario)"
                " ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED)"
                " RETURNING id, usuario_id, tipo, titulo, cuerpo, reserva_id"
            ),
            {"usuario": usuario_id},
        ).first()
        self._conn.commit()
        if f is None:
            return None
        return Pendiente(
            notificacion_id=int(f.id),
            usuario_id=int(f.usuario_id),
            aviso=Aviso(
                titulo=f.titulo,
                cuerpo=f.cuerpo,
                datos=datos_del_aviso(f.tipo, None if f.reserva_id is None else int(f.reserva_id)),
            ),
        )

    def marcar_envio(self, notificacion_id: int, envio: Envio) -> None:
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
        self, usuario_id: int, token: str, plataforma: str, permiso: bool
    ) -> bool:
        datos = {
            "usuario": usuario_id,
            "token": token,
            "plataforma": plataforma,
            "permiso": permiso,
        }
        try:
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
                    " permiso = EXCLUDED.permiso, actualizado_en = now()"
                    " WHERE dispositivo.usuario_id = EXCLUDED.usuario_id"
                ),
                datos,
            )
            self._conn.commit()
        except BaseException:
            self._conn.rollback()
            raise
        return True

    def baja_dispositivo(self, usuario_id: int, token: str) -> None:
        self._conn.execute(
            text(
                "UPDATE dispositivo SET activo = false, dado_de_baja_en = now()"
                " WHERE usuario_id = :usuario AND token = :token AND activo"
            ),
            {"usuario": usuario_id, "token": token},
        )
        self._conn.commit()

    def de_usuario(self, usuario_id: int) -> tuple[list[Notificacion], int]:
        filas = self._conn.execute(
            text(
                "SELECT id, tipo, titulo, cuerpo, reserva_id, creada_en,"
                " leida_en IS NOT NULL AS leida FROM notificacion WHERE usuario_id = :usuario"
                " AND reemplazada_por IS NULL"
                f" ORDER BY creada_en DESC, id DESC LIMIT {LIMITE_DEL_CENTRO}"
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
                    id=int(f.id),
                    tipo=f.tipo,
                    titulo=f.titulo,
                    cuerpo=f.cuerpo,
                    reserva_id=None if f.reserva_id is None else int(f.reserva_id),
                    creada_en=f.creada_en,
                    leida=bool(f.leida),
                )
                for f in filas
            ],
            int(sin_leer),
        )

    def leer(self, usuario_id: int, notificacion_id: int) -> bool:
        fila = self._conn.execute(
            text(
                "UPDATE notificacion SET leida_en = coalesce(leida_en, now())"
                " WHERE id = :id AND usuario_id = :usuario RETURNING id"
            ),
            {"id": notificacion_id, "usuario": usuario_id},
        ).first()
        self._conn.commit()
        return fila is not None

    def leer_todas(self, usuario_id: int) -> None:
        self._conn.execute(
            text(
                "UPDATE notificacion SET leida_en = now()"
                " WHERE usuario_id = :usuario AND leida_en IS NULL"
            ),
            {"usuario": usuario_id},
        )
        self._conn.commit()
