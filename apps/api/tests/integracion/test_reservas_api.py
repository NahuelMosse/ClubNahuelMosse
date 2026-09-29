"""`/reservas` contra la base y el emulador reales."""

from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime, time, timedelta
from threading import Barrier
from zoneinfo import ZoneInfo

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.aplicacion.errores import HorarioOcupado
from app.infraestructura.reservas import ReservasSql


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


def _espacio_nuevo(api: TestClient, token_admin: str, sede_id: int) -> int:
    r = api.post(
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
    )
    return int(r.json()["id"])


def test_reservar_guarda_el_precio_y_un_pedido_repetido_devuelve_la_misma(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[int, str]
) -> None:
    sede_id, _ = sede
    espacio = _espacio_nuevo(api, token_admin, sede_id)
    manana = (date.today() + timedelta(days=1)).isoformat()
    pedido = {"espacio_id": espacio, "fecha": manana, "desde": "18:00", "horas": 2}

    primera = api.post("/reservas", headers=_con(token_usuario), json=pedido)
    segunda = api.post("/reservas", headers=_con(token_usuario), json=pedido)

    assert primera.status_code == 201
    assert (primera.json()["total"], primera.json()["estado"]) == (76000, "activa")
    assert segunda.status_code == 201
    assert segunda.json()["id"] == primera.json()["id"]
    with motor.connect() as conn:
        assert (
            conn.execute(
                text("SELECT count(*) FROM reserva WHERE espacio_id = :e"), {"e": espacio}
            ).scalar_one()
            == 1
        )
    grilla = api.get(
        f"/espacios/{espacio}/horarios",
        headers=_con(token_usuario),
        params={"fecha": manana},
    ).json()
    libres = {f["inicio"]: f["disponible"] for f in grilla["franjas"]}
    assert (libres["17:00"], libres["18:00"], libres["19:00"], libres["20:00"]) == (
        True,
        False,
        False,
        True,
    )


def test_el_administrador_no_reserva_y_un_espacio_dado_de_baja_no_se_reserva(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[int, str]
) -> None:
    sede_id, _ = sede
    espacio = _espacio_nuevo(api, token_admin, sede_id)
    manana = (date.today() + timedelta(days=1)).isoformat()
    pedido = {"espacio_id": espacio, "fecha": manana, "desde": "10:00", "horas": 1}

    assert api.post("/reservas", headers=_con(token_admin), json=pedido).status_code == 403
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE espacio SET activo = false, dado_de_baja_en = now() WHERE id = :e"),
            {"e": espacio},
        )
    r = api.post("/reservas", headers=_con(token_usuario), json=pedido)
    assert r.status_code == 422
    assert "espacio_id" in r.json()["errores"]
    assert api.post("/reservas", json=pedido).status_code == 401


def test_dos_reservas_a_la_vez_del_mismo_horario_dejan_una_y_la_otra_es_ocupado(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[int, str]
) -> None:
    sede_id, _ = sede
    espacio = _espacio_nuevo(api, token_admin, sede_id)
    yo = _yo(api, motor, token_usuario)
    otro = _yo(api, motor, token_admin)
    manana = datetime.combine(
        date.today() + timedelta(days=1), time(0), tzinfo=ZoneInfo("America/Argentina/Buenos_Aires")
    )
    for hora in range(8, 18):
        inicio = manana + timedelta(hours=hora)
        fin = inicio + timedelta(hours=1)
        barrera = Barrier(2)

        def pedir(
            usuario: int,
            inicio: datetime = inicio,
            fin: datetime = fin,
            barrera: Barrier = barrera,
        ) -> str:
            with motor.connect() as conn:
                barrera.wait()
                try:
                    return str(ReservasSql(conn).insertar(usuario, espacio, inicio, fin).id)
                except HorarioOcupado:
                    return "ocupado"

        # Dos personas distintas: una la toma y la otra ve el horario ocupado.
        with ThreadPoolExecutor(2) as hilos:
            resultados = sorted(hilos.map(pedir, [yo, otro]))
        assert resultados[1] == "ocupado", resultados
        assert resultados[0].isdigit()

    # La misma persona dos veces a la vez: las dos respuestas son la misma reserva.
    inicio = manana + timedelta(hours=20)
    barrera = Barrier(2)

    def repetir(_: int) -> str:
        with motor.connect() as conn:
            barrera.wait()
            return str(
                ReservasSql(conn).insertar(yo, espacio, inicio, inicio + timedelta(hours=1)).id
            )

    with ThreadPoolExecutor(2) as hilos:
        a, b = hilos.map(repetir, [0, 1])
    assert a == b
