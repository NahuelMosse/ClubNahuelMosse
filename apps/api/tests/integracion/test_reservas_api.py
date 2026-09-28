"""`/reservas` contra la base y el emulador reales."""

from datetime import date, timedelta

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _reservar(
    motor: Engine,
    usuario: int,
    espacio: int,
    dia: date,
    hora: int,
    estado: str = "activa",
    motivo: str | None = None,
) -> None:
    with motor.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total,"
                " estado, motivo, cancelada_en)"
                " SELECT :u, :e, x.i, x.i + interval '1 hour', 38000, 38000, :estado, :motivo,"
                " CASE WHEN :estado <> 'activa' THEN now() END"
                " FROM (SELECT (CAST(:dia AS date) + make_interval(hours => :h))"
                " AT TIME ZONE 'America/Argentina/Buenos_Aires' AS i) x"
            ),
            {"u": usuario, "e": espacio, "dia": dia, "h": hora, "estado": estado, "motivo": motivo},
        )


def _yo(api: TestClient, motor: Engine, token: str) -> int:
    correo = api.get("/yo", headers=_con(token)).json()["correo"]
    with motor.connect() as conn:
        return int(
            conn.execute(
                text("SELECT id FROM usuario WHERE correo = :c"), {"c": correo}
            ).scalar_one()
        )


def test_cada_uno_ve_sus_proximas_y_su_historial_en_orden(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[int, str]
) -> None:
    sede_id, prefijo = sede
    espacio = api.post(
        "/espacios",
        headers=_con(token_admin),
        json={
            "sede_id": sede_id,
            "deporte": "Futbol",
            "tipo": "F5",
            "techada": False,
            "iluminada": True,
            "precio_por_hora": 38000,
        },
    ).json()["id"]
    yo = _yo(api, motor, token_usuario)
    hoy = date.today()
    _reservar(motor, yo, espacio, hoy + timedelta(days=3), 10)
    _reservar(motor, yo, espacio, hoy + timedelta(days=1), 10)
    _reservar(motor, yo, espacio, hoy + timedelta(days=2), 10, "cancelada")
    _reservar(motor, yo, espacio, hoy - timedelta(days=5), 10)
    _reservar(motor, yo, espacio, hoy - timedelta(days=2), 10, "anulada", "lluvia")
    _reservar(motor, _yo(api, motor, token_admin), espacio, hoy + timedelta(days=4), 10)

    def reservas(cuando: str) -> list[dict[str, object]]:
        r = api.get("/reservas", headers=_con(token_usuario), params={"cuando": cuando})
        assert r.status_code == 200
        lista: list[dict[str, object]] = r.json()["reservas"]
        return lista

    proximas = reservas("proximas")
    assert [str(p["inicio"])[:10] for p in proximas] == [
        str(hoy + timedelta(days=1)),
        str(hoy + timedelta(days=3)),
    ]
    assert proximas[0]["espacio"] == f"{prefijo}_Futbol_F5_1"
    assert proximas[0]["direccion"] == "Av. Vergara 1850"
    assert {p["estado"] for p in proximas} == {"activa"}
    historial = reservas("historial")
    assert [h["estado"] for h in historial] == ["cancelada", "anulada", "completada"]
    assert historial[1]["motivo"] == "lluvia"


def test_las_reservas_se_piden_con_sesion(api: TestClient) -> None:
    assert api.get("/reservas").status_code == 401
