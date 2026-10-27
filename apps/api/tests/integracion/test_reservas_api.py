"""`/reservas` contra la base y el emulador reales."""

from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime, time, timedelta
from threading import Barrier
from typing import Any
from uuid import UUID
from zoneinfo import ZoneInfo

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.reservas.repositorio import ReservasSql
from app.shared.errores import AgendaCambiada, HorarioOcupado


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _reservar(
    motor: Engine,
    usuario: UUID,
    espacio: str,
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


def _yo(api: TestClient, motor: Engine, token: str) -> UUID:
    correo = api.get("/yo", headers=_con(token)).json()["correo"]
    with motor.connect() as conn:
        return UUID(
            str(
                conn.execute(
                    text("SELECT id FROM usuario WHERE correo = :c"), {"c": correo}
                ).scalar_one()
            )
        )


def test_cada_uno_ve_sus_proximas_y_su_historial_en_orden(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
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


def _espacio_nuevo(api: TestClient, token_admin: str, sede_id: str) -> str:
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
    return str(r.json()["id"])


def test_reservar_guarda_el_precio_y_un_pedido_repetido_devuelve_la_misma(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
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
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
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
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
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
            usuario: UUID,
            inicio: datetime = inicio,
            fin: datetime = fin,
            barrera: Barrier = barrera,
        ) -> str:
            with motor.connect() as conn:
                barrera.wait()
                try:
                    sql = ReservasSql(conn)
                    agenda = sql.agenda(UUID(espacio))
                    assert agenda is not None
                    return str(sql.insertar(usuario, UUID(espacio), inicio, fin, agenda).id)
                except HorarioOcupado:
                    return "ocupado"

        # Dos personas distintas: una la toma y la otra ve el horario ocupado.
        with ThreadPoolExecutor(2) as hilos:
            resultados = sorted(hilos.map(pedir, [yo, otro]))
        assert resultados[1] == "ocupado", resultados
        UUID(resultados[0])

    # La misma persona dos veces a la vez: las dos respuestas son la misma reserva.
    inicio = manana + timedelta(hours=20)
    barrera = Barrier(2)

    def repetir(_: int) -> str:
        with motor.connect() as conn:
            barrera.wait()
            sql = ReservasSql(conn)
            agenda = sql.agenda(UUID(espacio))
            assert agenda is not None
            return str(
                sql.insertar(yo, UUID(espacio), inicio, inicio + timedelta(hours=1), agenda).id
            )

    with ThreadPoolExecutor(2) as hilos:
        a, b = hilos.map(repetir, [0, 1])
    assert a == b


def test_cancelar_libera_el_horario_estampa_quien_y_se_puede_repetir(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    espacio = _espacio_nuevo(api, token_admin, sede_id)
    manana = (date.today() + timedelta(days=1)).isoformat()
    pedido = {"espacio_id": espacio, "fecha": manana, "desde": "18:00", "horas": 1}
    reserva = api.post("/reservas", headers=_con(token_usuario), json=pedido).json()["id"]

    r = api.post(f"/reservas/{reserva}/cancelar", headers=_con(token_usuario))
    otra_vez = api.post(f"/reservas/{reserva}/cancelar", headers=_con(token_usuario))

    assert r.status_code == 200
    assert r.json()["estado"] == "cancelada"
    assert otra_vez.status_code == 200
    with motor.connect() as conn:
        fila = conn.execute(
            text(
                "SELECT cancelada_en IS NOT NULL, cancelada_por = usuario_id FROM reserva"
                " WHERE id = :id"
            ),
            {"id": reserva},
        ).one()
    assert tuple(fila) == (True, True)
    # El horario vuelve a estar libre para otra reserva.
    assert api.post("/reservas", headers=_con(token_usuario), json=pedido).status_code == 201


def test_no_se_cancela_una_ajena_una_empezada_ni_una_anulada(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    espacio = _espacio_nuevo(api, token_admin, sede_id)
    yo = _yo(api, motor, token_usuario)
    otro = _yo(api, motor, token_admin)
    hoy = date.today()
    _reservar(motor, otro, espacio, hoy + timedelta(days=1), 10)
    _reservar(motor, yo, espacio, hoy + timedelta(days=1), 12)
    _reservar(motor, yo, espacio, hoy + timedelta(days=2), 12, "anulada", "lluvia")
    with motor.begin() as conn:
        ids_reservas: list[Any] = list(
            conn.execute(
                text("SELECT id FROM reserva WHERE espacio_id = :e ORDER BY inicio"),
                {"e": espacio},
            ).scalars()
        )
        ajena, mia, anulada = ids_reservas
        conn.execute(
            text(
                "UPDATE reserva SET inicio = date_trunc('hour', now()), fin ="
                " date_trunc('hour', now()) + interval '1 hour' WHERE id = :id"
            ),
            {"id": mia},
        )

    def cancelar(reserva: UUID) -> int:
        return api.post(f"/reservas/{reserva}/cancelar", headers=_con(token_usuario)).status_code

    assert cancelar(ajena) == 404
    assert cancelar(mia) == 409
    assert cancelar(anulada) == 409
    assert api.post(f"/reservas/{mia}/cancelar").status_code == 401


def test_modificar_mueve_la_misma_reserva_libera_el_horario_y_recalcula_el_total(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    una = _espacio_nuevo(api, token_admin, sede_id)
    otra = api.post(
        "/espacios",
        headers=_con(token_admin),
        json={
            "sede_id": sede_id,
            "deporte": "Futbol",
            "tipo": "F5",
            "techada": True,
            "iluminada": True,
            "precio_por_hora": 43000,
        },
    ).json()["id"]
    manana = (date.today() + timedelta(days=1)).isoformat()
    reserva = api.post(
        "/reservas",
        headers=_con(token_usuario),
        json={"espacio_id": una, "fecha": manana, "desde": "21:00", "horas": 2},
    ).json()

    r = api.post(
        f"/reservas/{reserva['id']}/modificar",
        headers=_con(token_usuario),
        json={"espacio_id": otra, "fecha": manana, "desde": "18:00"},
    )

    assert r.status_code == 200, r.text
    assert (r.json()["id"], r.json()["espacio_id"], r.json()["total"]) == (
        reserva["id"],
        otra,
        86000,
    )
    # El horario anterior quedó libre y la grilla de la cancha nueva lo ignora sólo para su
    # dueño.
    libre = api.post(
        "/reservas",
        headers=_con(token_usuario),
        json={"espacio_id": una, "fecha": manana, "desde": "21:00", "horas": 1},
    )
    assert libre.status_code == 201
    grilla = api.get(
        f"/espacios/{otra}/horarios",
        headers=_con(token_usuario),
        params={"fecha": manana, "horas": 2, "reserva_id": reserva["id"]},
    ).json()
    assert {f["inicio"]: f["disponible"] for f in grilla["franjas"]}["18:00"] is True
    ajena = api.get(
        f"/espacios/{otra}/horarios",
        headers=_con(token_admin),
        params={"fecha": manana, "horas": 2, "reserva_id": reserva["id"]},
    ).json()
    assert {f["inicio"]: f["disponible"] for f in ajena["franjas"]}["18:00"] is False


def test_modificar_rechaza_lo_que_no_corresponde(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    espacio = _espacio_nuevo(api, token_admin, sede_id)
    hockey = api.post(
        "/espacios",
        headers=_con(token_admin),
        json={
            "sede_id": sede_id,
            "deporte": "Hockey",
            "tipo": "H7",
            "techada": False,
            "iluminada": True,
            "precio_por_hora": 50000,
        },
    ).json()["id"]
    manana = (date.today() + timedelta(days=1)).isoformat()
    mia = api.post(
        "/reservas",
        headers=_con(token_usuario),
        json={"espacio_id": espacio, "fecha": manana, "desde": "10:00", "horas": 1},
    ).json()["id"]
    _reservar(motor, _yo(api, motor, token_admin), espacio, date.today() + timedelta(days=1), 12)

    def cambiar(cuerpo: dict[str, object], token: str = token_usuario) -> tuple[int, object]:
        r = api.post(f"/reservas/{mia}/modificar", headers=_con(token), json=cuerpo)
        return r.status_code, r.json() if r.content else None

    # El mismo horario es un reintento de un cambio que ya se hizo: responde la reserva.
    mismo = cambiar({"espacio_id": espacio, "fecha": manana, "desde": "10:00"})
    assert mismo[0] == 200
    assert isinstance(mismo[1], dict)
    assert mismo[1]["id"] == mia
    assert cambiar({"espacio_id": hockey, "fecha": manana, "desde": "10:00"})[0] == 422
    ocupado = cambiar({"espacio_id": espacio, "fecha": manana, "desde": "12:00"})
    assert ocupado == (409, {"errores": {"horario": "Ese horario se ocupó"}})
    assert (
        cambiar({"espacio_id": espacio, "fecha": manana, "desde": "15:00"}, token_admin)[0] == 403
    )
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE reserva SET estado = 'anulada', motivo = 'lluvia' WHERE id = :id"),
            {"id": mia},
        )
    cambio = cambiar({"espacio_id": espacio, "fecha": manana, "desde": "15:00"})
    assert cambio == (409, {"errores": {"reserva": "Esto cambió mientras tanto"}})


def test_dos_cambios_cruzados_entre_las_mismas_canchas_se_esperan_sin_trabarse(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    a = _espacio_nuevo(api, token_admin, sede_id)
    b = _espacio_nuevo(api, token_admin, sede_id)
    yo = _yo(api, motor, token_usuario)
    manana = datetime.combine(
        date.today() + timedelta(days=1), time(0), tzinfo=ZoneInfo("America/Argentina/Buenos_Aires")
    )
    ua, ub = UUID(a), UUID(b)
    with motor.connect() as conn:
        agenda = ReservasSql(conn).agenda(ua)
    assert agenda is not None
    for hora in range(8, 20, 2):
        diez, once = manana + timedelta(hours=hora), manana + timedelta(hours=hora + 1)
        hora_ = timedelta(hours=1)
        with motor.connect() as conn:
            sql = ReservasSql(conn)
            r1 = sql.insertar(yo, ua, diez, diez + hora_, agenda).id
            r2 = sql.insertar(yo, ub, once, once + hora_, agenda).id
        barrera = Barrier(2)

        # Cada una quiere el lugar de la otra, que sigue tomado: las dos terminan en ocupado.
        def mover(
            cambio: tuple[UUID, tuple[UUID, datetime], UUID, datetime],
            barrera: Barrier = barrera,
            hora_: timedelta = hora_,
        ) -> str:
            reserva, antes, espacio, inicio = cambio
            with motor.connect() as conn:
                barrera.wait()
                try:
                    ReservasSql(conn).mover(
                        yo, reserva, antes, espacio, inicio, inicio + hora_, agenda
                    )
                except HorarioOcupado:
                    return "ocupado"
                return "movida"

        with ThreadPoolExecutor(2) as hilos:
            resultados = list(
                hilos.map(mover, [(r1, (ua, diez), ub, once), (r2, (ub, once), ua, diez)])
            )
        assert resultados == ["ocupado", "ocupado"]


def test_una_reserva_validada_con_el_horario_viejo_no_se_guarda(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    espacio = _espacio_nuevo(api, token_admin, sede_id)
    yo = _yo(api, motor, token_usuario)
    manana = datetime.combine(
        date.today() + timedelta(days=1), time(8), tzinfo=ZoneInfo("America/Argentina/Buenos_Aires")
    )
    with motor.connect() as conn:
        vieja = ReservasSql(conn).agenda(UUID(espacio))
    assert vieja is not None
    with motor.begin() as conn:
        conn.execute(text("UPDATE sede SET apertura = '09:00' WHERE id = :s"), {"s": sede_id})

    # Verifica: la reserva de las 8, validada antes del cambio, no entra.
    with motor.connect() as conn, pytest.raises(AgendaCambiada):
        ReservasSql(conn).insertar(yo, UUID(espacio), manana, manana + timedelta(hours=1), vieja)
    # Verifica: por la API, se vuelve a validar con el horario nuevo.
    r = api.post(
        "/reservas",
        headers=_con(token_usuario),
        json={
            "espacio_id": espacio,
            "fecha": manana.date().isoformat(),
            "desde": "08:00",
            "horas": 1,
        },
    )
    assert r.status_code == 422
    assert r.json()["errores"]["desde"] == "La sede abre a las 09:00"
