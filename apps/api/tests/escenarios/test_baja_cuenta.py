from collections.abc import Callable
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

ZONA = ZoneInfo("America/Argentina/Buenos_Aires")


def _proxima_hora(dias: int) -> datetime:
    ahora = datetime.now(ZONA).replace(minute=0, second=0, microsecond=0)
    return ahora + timedelta(days=dias, hours=1)


def test_al_eliminar_la_cuenta_el_horario_de_su_reserva_vigente_vuelve_a_estar_disponible(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """al eliminar la cuenta, el horario de su reserva vigente vuelve a estar disponible @CU-07-H01-02"""
    s = unico()
    correo = f"socia.{s}@correo.com"
    assert (
        api.post(
            "/registro",
            json={
                "nombre": "Lucía",
                "apellido": "Gómez",
                "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
                "fecha_nacimiento": "1998-11-02",
                "correo": correo,
                "contrasena": "ClubNahuel1",
            },
        ).status_code
        == 201
    )
    inicio = _proxima_hora(dias=2)
    with motor.begin() as conn:
        usuario = conn.execute(
            text("SELECT id FROM usuario WHERE correo = :c"), {"c": correo}
        ).scalar_one()
        sede = conn.execute(
            text(
                "INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
                " VALUES (:n, 'Av. Rivadavia', 19850, '08:00', '00:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id"
            ),
            {"n": f"Sede {s}"},
        ).scalar_one()
        espacio = conn.execute(
            text(
                "INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, precio_por_hora,"
                " techada, iluminada) VALUES (:sede, 'Futbol', 'F5', 1, :nombre, 38000, false,"
                " true) RETURNING id"
            ),
            {"sede": sede, "nombre": f"Moron_Rivadavia_19850_Futbol_F5_1_{s}"},
        ).scalar_one()
        reserva = conn.execute(
            text(
                "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
                " VALUES (:u, :e, :i, :f, 38000, 38000) RETURNING id"
            ),
            {"u": usuario, "e": espacio, "i": inicio, "f": inicio + timedelta(hours=1)},
        ).scalar_one()

    token = iniciar_sesion(correo, "ClubNahuel1")
    assert api.delete("/yo", headers={"Authorization": f"Bearer {token}"}).status_code == 204

    with motor.begin() as conn:
        estado, cancelada_por = conn.execute(
            text("SELECT estado, cancelada_por FROM reserva WHERE id = :r"), {"r": reserva}
        ).one()
        # Verifica: la reserva queda cancelada por la persona que se dio de baja, con rastro.
        assert (estado, cancelada_por) == ("cancelada", usuario)
        # Verifica: el mismo horario del mismo espacio se puede volver a reservar; si siguiera
        # tomado, la base lo rechazaría por superposición.
        otra = conn.execute(
            text(
                "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
                " VALUES (:u, :e, :i, :f, 38000, 38000) RETURNING id"
            ),
            {"u": usuario, "e": espacio, "i": inicio, "f": inicio + timedelta(hours=1)},
        ).scalar_one()
        assert otra != reserva
