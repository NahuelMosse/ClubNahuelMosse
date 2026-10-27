"""`/sedes` contra la base y el emulador reales."""

from collections.abc import Callable, Iterator
from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.usuarios.sembrar_admin import main as sembrar

CONTRASENA = "ClubNahuel1"


@pytest.fixture
def token_admin(
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> Iterator[str]:
    s = unico()
    correo = f"admin.{s}@club.com"
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    argumentos = [
        "--correo", correo, "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert sembrar(argumentos) == 0
    token = iniciar_sesion(correo, CONTRASENA)
    assert token is not None
    yield token


@pytest.fixture
def token_usuario(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> str:
    s = unico()
    correo = f"socio.{s}@correo.com"
    pedido = {
        "nombre": "Martín",
        "apellido": "Ferreyra",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "fecha_nacimiento": "1994-07-21",
        "correo": correo,
        "contrasena": CONTRASENA,
    }
    assert api.post("/registro", json=pedido).status_code == 201
    token = iniciar_sesion(correo, CONTRASENA)
    assert token is not None
    return token


def _sede(nombre: str, **cambios: object) -> dict[str, object]:
    return {
        "nombre": nombre,
        "direccion": "Av. Vergara 1850",
        "apertura": "08:00",
        "cierre": "23:00",
        "dias": [1, 2, 3, 4, 5, 6],
    } | cambios


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def test_el_alta_guarda_la_sede_con_su_rastro_y_la_devuelve(
    api: TestClient, motor: Engine, token_admin: str, unico: Callable[[], str]
) -> None:
    nombre = f"Sede Haedo {unico()}"
    r = api.post("/sedes", headers=_con(token_admin), json=_sede(nombre))
    assert r.status_code == 201
    assert r.json() | {"id": ""} == {
        "id": "",
        "nombre": nombre,
        "direccion": "Av. Vergara 1850",
        "apertura": "08:00",
        "cierre": "23:00",
        "dias": [1, 2, 3, 4, 5, 6],
        "canchas": 0,
        "deportes": [],
    }
    with motor.connect() as conn:
        fila = conn.execute(
            text(
                "SELECT s.calle, s.altura, s.activa, s.creado_en IS NOT NULL AS con_fecha,"
                " u.correo LIKE 'admin.%' AS por_admin"
                " FROM sede s JOIN usuario u ON u.id = s.creado_por WHERE s.id = :id"
            ),
            {"id": r.json()["id"]},
        ).one()
    assert tuple(fila) == ("Av. Vergara", 1850, True, True, True)


def test_los_usuarios_ven_las_sedes_por_nombre_con_sus_canchas(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    unico: Callable[[], str],
) -> None:
    s = unico()
    zeta = api.post("/sedes", headers=_con(token_admin), json=_sede(f"zz Sede {s}")).json()
    api.post("/sedes", headers=_con(token_admin), json=_sede(f"ZY Sede {s}"))
    with motor.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, precio_por_hora,"
                " techada, iluminada) VALUES (:sede, 'Padel', 'PAD', 1, :n, 30000, true, true)"
            ),
            {"sede": zeta["id"], "n": f"Zz_Vergara_1850_Padel_PAD_1_{s}"},
        )

    r = api.get("/sedes", headers=_con(token_usuario))

    assert r.status_code == 200
    propias = [x for x in r.json()["sedes"] if x["nombre"].endswith(s)]
    assert [(x["nombre"], x["canchas"]) for x in propias] == [
        (f"ZY Sede {s}", 0),
        (f"zz Sede {s}", 1),
    ]


def test_no_hay_dos_sedes_activas_con_el_mismo_nombre(
    api: TestClient, token_admin: str, unico: Callable[[], str]
) -> None:
    nombre = f"Sede Haedo {unico()}"
    assert api.post("/sedes", headers=_con(token_admin), json=_sede(nombre)).status_code == 201
    r = api.post(
        "/sedes", headers=_con(token_admin), json=_sede(nombre.upper(), direccion="Otra 1")
    )
    assert r.status_code == 409
    assert r.json() == {"errores": {"nombre": "Ya existe una sede con ese nombre"}}


def test_dos_altas_iguales_a_la_vez_guardan_una_sola(
    api: TestClient, motor: Engine, token_admin: str, unico: Callable[[], str]
) -> None:
    nombre = f"Sede Haedo {unico()}"
    with ThreadPoolExecutor(max_workers=2) as pool:
        codigos = sorted(
            pool.map(
                lambda _: (
                    api.post("/sedes", headers=_con(token_admin), json=_sede(nombre)).status_code
                ),
                range(2),
            )
        )
    assert codigos == [201, 409]
    with motor.connect() as conn:
        n: Any = conn.execute(
            text("SELECT count(*) FROM sede WHERE nombre = :n"), {"n": nombre}
        ).scalar_one()
    assert n == 1


def test_los_datos_invalidos_vuelven_con_el_mensaje_de_cada_campo(
    api: TestClient, token_admin: str, unico: Callable[[], str]
) -> None:
    r = api.post(
        "/sedes",
        headers=_con(token_admin),
        json=_sede(f"Sede {unico()}", direccion="Vergara", apertura="22:00", cierre="21:00"),
    )
    assert r.status_code == 422
    assert r.json() == {
        "errores": {
            "direccion": "Escribí la calle y la altura",
            "cierre": "El cierre tiene que ser después de la apertura",
        }
    }
    r = api.post("/sedes", headers=_con(token_admin), json={})
    assert r.status_code == 422
    assert set(r.json()["errores"]) == {"nombre", "direccion", "apertura", "cierre", "dias"}


def test_sin_sesion_no_hay_sedes(api: TestClient) -> None:
    assert api.get("/sedes").status_code == 401
    assert api.post("/sedes", json=_sede("Sede Haedo")).status_code == 401


@pytest.mark.parametrize("hora", ["23:00+00:00", "00:00Z", "08", "0800", "T08:00", "8:00"])
def test_una_hora_que_no_es_hh_mm_es_un_error_del_campo(
    api: TestClient, token_admin: str, unico: Callable[[], str], hora: str
) -> None:
    r = api.post("/sedes", headers=_con(token_admin), json=_sede(f"Sede {unico()}", cierre=hora))
    assert r.status_code == 422
    assert r.json() == {"errores": {"cierre": "El horario de cierre es obligatorio"}}


def _alta(api: TestClient, token_admin: str, nombre: str) -> int:
    r = api.post(
        "/sedes", headers=_con(token_admin), json=_sede(nombre, dias=[1, 2, 3, 4, 5, 6, 7])
    )
    assert r.status_code == 201
    return int(r.json()["id"])


def test_editar_guarda_los_datos_nuevos_con_su_rastro(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, unico: Callable[[], str]
) -> None:
    nombre = f"Sede Haedo {unico()}"
    sede = _alta(api, token_admin, nombre)
    cambios = _sede(f"{nombre} Norte", direccion="Av. Vergara 1900", cierre="00:00", dias=[1, 2])

    r = api.put(f"/sedes/{sede}", headers=_con(token_admin), json=cambios)

    assert r.status_code == 200
    assert (r.json()["nombre"], r.json()["direccion"], r.json()["cierre"], r.json()["dias"]) == (
        f"{nombre} Norte",
        "Av. Vergara 1900",
        "00:00",
        [1, 2],
    )
    with motor.connect() as conn:
        fila = conn.execute(
            text(
                "SELECT s.modificado_en > s.creado_en AS despues, u.correo LIKE 'admin.%' AS admin"
                " FROM sede s JOIN usuario u ON u.id = s.modificado_por WHERE s.id = :id"
            ),
            {"id": sede},
        ).one()
    assert tuple(fila) == (True, True)
    # La misma sede puede quedarse con su nombre.
    assert api.put(f"/sedes/{sede}", headers=_con(token_admin), json=cambios).status_code == 200
    assert api.put(f"/sedes/{sede}", headers=_con(token_usuario), json=cambios).status_code == 403
    assert api.put(f"/sedes/{sede}", json=cambios).status_code == 401


def test_editar_rechaza_otro_nombre_en_uso_datos_invalidos_y_una_sede_dada_de_baja(
    api: TestClient, motor: Engine, token_admin: str, unico: Callable[[], str]
) -> None:
    nombre = f"Sede Haedo {unico()}"
    otra = f"Sede Morón {unico()}"
    sede = _alta(api, token_admin, nombre)
    _alta(api, token_admin, otra)

    repetido = api.put(f"/sedes/{sede}", headers=_con(token_admin), json=_sede(otra.upper()))
    assert repetido.status_code == 409
    assert repetido.json() == {"errores": {"nombre": "Ya existe una sede con ese nombre"}}
    vacio = api.put(f"/sedes/{sede}", headers=_con(token_admin), json=_sede(nombre, direccion=""))
    assert vacio.status_code == 422
    assert vacio.json()["errores"]["direccion"] == "La dirección es obligatoria"
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE sede SET activa = false, dado_de_baja_en = now() WHERE id = :id"),
            {"id": sede},
        )
    assert (
        api.put(f"/sedes/{sede}", headers=_con(token_admin), json=_sede(nombre)).status_code == 404
    )
    assert (
        api.put("/sedes/999999999", headers=_con(token_admin), json=_sede(nombre)).status_code
        == 404
    )


def test_achicar_el_horario_pide_confirmar_las_reservas_que_quedan_afuera_y_las_mantiene(
    api: TestClient, motor: Engine, token_admin: str, unico: Callable[[], str]
) -> None:
    nombre = f"Sede Morón {unico()}"
    sede = _alta(api, token_admin, nombre)
    espacio = api.post(
        "/espacios",
        headers=_con(token_admin),
        json={
            "sede_id": sede,
            "deporte": "Futbol",
            "tipo": "F5",
            "techada": False,
            "iluminada": True,
            "precio_por_hora": 38000,
        },
    ).json()["id"]
    with motor.begin() as conn:
        dueno: Any = conn.execute(text("SELECT min(id) FROM usuario")).scalar_one()
        manana: Any = conn.execute(
            text("SELECT (now() AT TIME ZONE 'America/Argentina/Buenos_Aires')::date + 1")
        ).scalar_one()
        for dia, hora, estado in [
            (1, 8, "activa"),
            (1, 22, "activa"),
            (1, 9, "cancelada"),
            (-2, 8, "activa"),
        ]:
            conn.execute(
                text(
                    "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora,"
                    " total, estado, cancelada_en)"
                    " SELECT :u, :e, x.i, x.i + interval '1 hour', 38000, 38000, :estado,"
                    " CASE WHEN :estado <> 'activa' THEN now() END"
                    " FROM (SELECT (CAST(:dia AS date) + make_interval(hours => :h))"
                    " AT TIME ZONE 'America/Argentina/Buenos_Aires' AS i) x"
                ),
                {
                    "u": dueno,
                    "e": espacio,
                    "dia": manana + timedelta(days=dia - 1),
                    "h": hora,
                    "estado": estado,
                },
            )

    def editar(**cambios: object) -> tuple[int, object]:
        r = api.put(f"/sedes/{sede}", headers=_con(token_admin), json=_sede(nombre, **cambios))
        return r.status_code, r.json()

    todos = [1, 2, 3, 4, 5, 6, 7]
    # Las pasadas y las canceladas no cuentan.
    assert editar(apertura="09:00", dias=todos) == (409, {"reservas_afuera": 1})
    assert editar(apertura="09:00", cierre="22:00", dias=todos) == (409, {"reservas_afuera": 2})
    sin_manana = [d for d in todos if d != manana.isoweekday()]
    assert editar(dias=sin_manana) == (409, {"reservas_afuera": 2})
    assert editar(apertura="09:00", dias=todos, confirmar=True)[0] == 200
    # Lo que ya estaba afuera no se vuelve a preguntar.
    assert editar(apertura="09:00", dias=todos, direccion="Av. Rivadavia 19850")[0] == 200
    with motor.connect() as conn:
        activas: Any = conn.execute(
            text("SELECT count(*) FROM reserva WHERE espacio_id = :e AND estado = 'activa'"),
            {"e": espacio},
        ).scalar_one()
    assert activas == 3


def test_la_baja_deja_la_sede_y_sus_espacios_inactivos_con_su_rastro(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, unico: Callable[[], str]
) -> None:
    nombre = f"Sede Haedo {unico()}"
    sede = _alta(api, token_admin, nombre)
    espacio = api.post(
        "/espacios",
        headers=_con(token_admin),
        json={
            "sede_id": sede,
            "deporte": "Futbol",
            "tipo": "F5",
            "techada": False,
            "iluminada": True,
            "precio_por_hora": 38000,
        },
    ).json()["id"]
    assert api.delete(f"/sedes/{sede}", headers=_con(token_usuario)).status_code == 403
    assert api.delete(f"/sedes/{sede}").status_code == 401

    assert api.delete(f"/sedes/{sede}", headers=_con(token_admin)).status_code == 204

    with motor.connect() as conn:
        fila = conn.execute(
            text(
                "SELECT s.activa, s.dado_de_baja_en IS NOT NULL, e.activo,"
                " e.dado_de_baja_por = s.dado_de_baja_por"
                " FROM sede s JOIN espacio e ON e.sede_id = s.id WHERE s.id = :id"
            ),
            {"id": sede},
        ).one()
    assert tuple(fila) == (False, True, False, True)
    sedes = api.get("/sedes", headers=_con(token_usuario)).json()["sedes"]
    assert nombre not in [s["nombre"] for s in sedes]
    espacios = api.get("/espacios", headers=_con(token_usuario)).json()["espacios"]
    assert espacio not in [e["id"] for e in espacios]
    # Ya dada de baja: 404, y su nombre queda libre para una sede nueva.
    assert api.delete(f"/sedes/{sede}", headers=_con(token_admin)).status_code == 404
    assert api.post("/sedes", headers=_con(token_admin), json=_sede(nombre)).status_code == 201


def test_no_se_da_de_baja_una_sede_con_reservas_sin_terminar(
    api: TestClient, motor: Engine, token_admin: str, unico: Callable[[], str]
) -> None:
    sede = _alta(api, token_admin, f"Sede Morón {unico()}")
    espacio = api.post(
        "/espacios",
        headers=_con(token_admin),
        json={
            "sede_id": sede,
            "deporte": "Futbol",
            "tipo": "F5",
            "techada": False,
            "iluminada": True,
            "precio_por_hora": 38000,
        },
    ).json()["id"]
    with motor.begin() as conn:
        dueno: Any = conn.execute(text("SELECT min(id) FROM usuario")).scalar_one()
        # Una en curso: empezó en esta hora y termina en dos.
        conn.execute(
            text(
                "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
                " SELECT :u, :e, i, i + interval '2 hours', 38000, 76000"
                " FROM (SELECT date_trunc('hour', now()) AS i) x"
            ),
            {"u": dueno, "e": espacio},
        )

    r = api.delete(f"/sedes/{sede}", headers=_con(token_admin))

    assert r.status_code == 409
    assert r.json() == {
        "errores": {
            "sede": "No se puede dar de baja la sede porque posee reservas futuras asociadas."
        }
    }
    with motor.connect() as conn:
        assert conn.execute(
            text("SELECT activa FROM sede WHERE id = :id"), {"id": sede}
        ).scalar_one()
