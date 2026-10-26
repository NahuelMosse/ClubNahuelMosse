from sqlalchemy import Connection, text

from app.dominio.recuperacion import Destinatario, EnlaceReclamado
from app.infraestructura.db import en_transaccion

# Un enlace vale si no se usó ni se reemplazó, no venció, la cuenta sigue activa y la
# contraseña no cambió después de emitirlo.
_VIGENTE = """
    e.usado_en IS NULL
    AND e.invalidado_en IS NULL
    AND e.vence_en > clock_timestamp()
    AND u.activo
    AND (u.contrasena_cambiada_en IS NULL OR u.contrasena_cambiada_en < e.emitido_en)
"""


class EnlacesSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def destinatario(self, correo: str) -> Destinatario | None:
        fila = self._conn.execute(
            text("SELECT id, nombre, correo FROM usuario WHERE lower(correo) = :c AND activo"),
            {"c": correo},
        ).first()
        self._conn.rollback()
        return None if fila is None else Destinatario(fila.id, fila.nombre, fila.correo)

    def emitir(
        self, usuario_id: int, codigo_hash: str, vigencia_minutos: int, maximo_por_hora: int
    ) -> bool:
        with en_transaccion(self._conn):
            # El candado ordena los pedidos simultáneos de la misma cuenta: el segundo cuenta
            # e invalida recién cuando el primero terminó.
            self._conn.execute(text("SELECT pg_advisory_xact_lock(:u)"), {"u": usuario_id})
            emitidos: int = self._conn.execute(
                text(
                    "SELECT count(*) FROM enlace_recuperacion WHERE usuario_id = :u"
                    " AND emitido_en > clock_timestamp() - interval '1 hour'"
                ),
                {"u": usuario_id},
            ).scalar_one()
            if emitidos >= maximo_por_hora:
                self._conn.rollback()
                return False
            # También el que está en uso: si el cambio falla y se libera, ya no vale.
            self._conn.execute(
                text(
                    "UPDATE enlace_recuperacion SET invalidado_en = clock_timestamp()"
                    " WHERE usuario_id = :u AND invalidado_en IS NULL"
                ),
                {"u": usuario_id},
            )
            # El vencimiento sale del reloj de la base, el mismo con el que se compara.
            self._conn.execute(
                text(
                    "INSERT INTO enlace_recuperacion (usuario_id, codigo_hash, vence_en)"
                    " VALUES (:u, :h, clock_timestamp() + make_interval(mins => :m))"
                ),
                {"u": usuario_id, "h": codigo_hash, "m": vigencia_minutos},
            )
        return True

    def vigente(self, codigo_hash: str) -> bool:
        fila = self._conn.execute(
            text(
                "SELECT 1 FROM enlace_recuperacion e JOIN usuario u ON u.id = e.usuario_id"
                f" WHERE e.codigo_hash = :h AND {_VIGENTE}"
            ),
            {"h": codigo_hash},
        ).first()
        self._conn.rollback()
        return fila is not None

    def reclamar(self, codigo_hash: str) -> EnlaceReclamado | None:
        with en_transaccion(self._conn):
            fila = self._conn.execute(
                text(
                    "UPDATE enlace_recuperacion e SET usado_en = clock_timestamp()"
                    " FROM usuario u WHERE u.id = e.usuario_id AND e.codigo_hash = :h"
                    f" AND {_VIGENTE}"
                    " RETURNING e.id, u.id AS usuario_id, u.firebase_uid"
                ),
                {"h": codigo_hash},
            ).first()
        if fila is None:
            return None
        return EnlaceReclamado(fila.id, fila.usuario_id, fila.firebase_uid)

    def liberar(self, enlace_id: int) -> None:
        self._conn.execute(
            text("UPDATE enlace_recuperacion SET usado_en = NULL WHERE id = :id"), {"id": enlace_id}
        )
        self._conn.commit()
