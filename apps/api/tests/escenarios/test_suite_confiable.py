"""La suite prueba lo que dice: bordes, sesión en cada operación, consultas fijas y unitarios."""

import ast
import os
import re
import subprocess
import sys
from collections.abc import Callable, Iterator
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Connection, Engine, event, text
from sqlalchemy.exc import IntegrityError

from app.shared.db import motor as motor_de_la_app
from app.interfaz.sembrar_admin import main as sembrar

RAIZ_API = Path(__file__).resolve().parents[2]
ZONA = ZoneInfo("America/Argentina/Buenos_Aires")
CONTRASENA = "ClubNahuel1"


def _no_publicas(api: TestClient) -> list[tuple[str, str]]:
    """Las operaciones que el contrato publica con seguridad: las demás no piden sesión."""
    esquema = api.get("/openapi.json").json()
    return [
        (metodo.upper(), re.sub(r"\{[^}]+\}", "1", ruta))
        for ruta, operaciones in esquema["paths"].items()
        for metodo, operacion in operaciones.items()
        if operacion.get("security")
    ]


def _sin_401(api: TestClient, cabeceras: dict[str, str]) -> dict[tuple[str, str], int]:
    codigos = {
        (metodo, ruta): api.request(
            metodo, ruta, headers=cabeceras, json=None if metodo == "GET" else {}
        ).status_code
        for metodo, ruta in _no_publicas(api)
    }
    return {operacion: c for operacion, c in codigos.items() if c != 401}


def test_toda_operacion_que_no_es_publica_responde_401_sin_sesion(api: TestClient) -> None:
    """toda operación no pública responde 401 sin sesión y se cuentan las 28 del contrato, como pide RNF-01-H06-02
    @REV-08-S1 @assumption:REV-08-ASM-02
    """
    assert len(_no_publicas(api)) >= 28
    assert _sin_401(api, {}) == {}


def test_un_token_invalido_cuenta_como_sin_sesion(api: TestClient) -> None:
    """un token inválido cuenta como sin sesión y responde 401
    @REV-08-S1 @assumption:REV-08-ASM-11
    """
    assert _sin_401(api, {"Authorization": "Bearer no-es-un-token"}) == {}


def _usuario(conn: Connection, correo: str, dni: str) -> int:
    return int(
        conn.execute(
            text(
                "INSERT INTO usuario (firebase_uid, correo, nombre, apellido, dni,"
                " fecha_nacimiento) VALUES (:uid, :c, 'Ana', 'Rios', :d, '1990-01-01')"
                " RETURNING id"
            ),
            {"uid": f"uid-{correo}-{dni}", "c": correo, "d": dni},
        ).scalar_one()
    )


def _espacio(conn: Connection, s: str) -> int:
    return int(
        conn.execute(
            text(
                "WITH s AS (INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
                " VALUES (:n, 'Av. Vergara', 1850, '08:00', '23:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id)"
                " INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada,"
                " iluminada, precio_por_hora) SELECT id, 'Futbol', 'F5', 1, :e, false, true,"
                " 38000 FROM s RETURNING id"
            ),
            {"n": f"Sede Haedo {s}", "e": f"Haedo{s}_Vergara_1850_Futbol_F5_1"},
        ).scalar_one()
    )


def _reserva(conn: Connection, usuario: int, espacio: int, horas: int) -> None:
    inicio = datetime(2030, 11, 14, 8, tzinfo=ZONA)
    conn.execute(
        text(
            "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
            " VALUES (:u, :e, :i, :f, 38000, :t)"
        ),
        {
            "u": usuario,
            "e": espacio,
            "i": inicio,
            "f": inicio + timedelta(hours=horas),
            "t": 38000 * horas,
        },
    )


@pytest.mark.parametrize("horas", [1, 4])
def test_la_base_acepta_reservas_de_una_a_cuatro_horas(
    db: Connection, unico: Callable[[], str], horas: int
) -> None:
    """el test de duración prueba los bordes que se aceptan @REV-08-S2"""
    s = unico()
    usuario = _usuario(db, f"borde.{s}@correo.com", str(int(s, 16) % 90_000_000 + 10_000_000))

    _reserva(db, usuario, _espacio(db, s), horas)

    assert db.execute(text("SELECT count(*) FROM reserva WHERE usuario_id = :u"), {"u": usuario}).scalar_one() == 1


@pytest.mark.parametrize("horas", [0, 5])
def test_la_base_rechaza_reservas_de_menos_de_una_o_mas_de_cuatro_horas(
    db: Connection, unico: Callable[[], str], horas: int
) -> None:
    """el test de duración prueba los bordes que se rechazan @REV-08-S2"""
    s = unico()
    usuario = _usuario(db, f"borde.{s}@correo.com", str(int(s, 16) % 90_000_000 + 10_000_000))
    espacio = _espacio(db, s)

    with pytest.raises(IntegrityError), db.begin_nested():
        _reserva(db, usuario, espacio, horas)


def test_la_baja_libera_el_dni_que_antes_estaba_bloqueado(
    db: Connection, unico: Callable[[], str]
) -> None:
    """el test de baja muestra el DNI bloqueado antes y liberado después @REV-08-S3"""
    s = unico()
    dni = str(int(s, 16) % 90_000_000 + 10_000_000)
    usuario = _usuario(db, f"vuelve.{s}@correo.com", dni)

    with pytest.raises(IntegrityError), db.begin_nested():
        _usuario(db, f"otro.{s}@correo.com", dni)
    db.execute(
        text("UPDATE usuario SET activo = false, dado_de_baja_en = now() WHERE id = :id"),
        {"id": usuario},
    )
    nuevo = _usuario(db, f"otro.{s}@correo.com", dni)

    assert nuevo != usuario


def test_la_baja_libera_el_correo_que_antes_estaba_bloqueado(
    db: Connection, unico: Callable[[], str]
) -> None:
    """la baja libera el correo que antes estaba bloqueado @REV-08-S3"""
    s = unico()
    correo = f"Vuelve.{s}@correo.com"
    usuario = _usuario(db, correo, str(int(s, 16) % 90_000_000 + 10_000_000))

    with pytest.raises(IntegrityError), db.begin_nested():
        _usuario(db, correo.lower(), str(int(s, 16) % 90_000_000 + 10_000_001))
    db.execute(
        text("UPDATE usuario SET activo = false, dado_de_baja_en = now() WHERE id = :id"),
        {"id": usuario},
    )
    nuevo = _usuario(db, correo.upper(), str(int(s, 16) % 90_000_000 + 10_000_001))

    assert nuevo != usuario


def test_restricciones_ya_no_trae_los_dos_tests_enganosos() -> None:
    """test_restricciones ya no trae los dos tests engañosos de duración y de baja
    @REV-08-S2 @assumption:REV-08-ASM-06
    """
    fuente = (RAIZ_API / "tests" / "integracion" / "test_restricciones.py").read_text(
        encoding="utf-8"
    )

    assert "def test_la_reserva_dura_entre_una_y_cuatro_horas(" not in fuente
    assert "def test_la_baja_libera_el_correo_y_el_dni(" not in fuente


def _correr(*argumentos: str, quitar: tuple[str, ...] = (), poner: dict[str, str] | None = None) -> "subprocess.CompletedProcess[str]":
    entorno = {k: v for k, v in os.environ.items() if k not in quitar} | (poner or {})
    return subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider", *argumentos],
        cwd=RAIZ_API, env=entorno, capture_output=True, text=True, timeout=300, check=False,
    )  # fmt: skip


ESCENARIO = "tests/escenarios/test_registro_de_errores.py"


def test_con_la_variable_del_emulador_ausente_la_corrida_falla_con_un_mensaje_claro() -> None:
    """con la variable del emulador ausente la corrida falla con un mensaje claro
    @REV-08-S5 @assumption:REV-08-ASM-10
    """
    corrida = _correr(ESCENARIO, quitar=("FIREBASE_AUTH_EMULATOR_HOST",))

    assert corrida.returncode != 0
    assert "hace falta el emulador de Firebase Auth" in corrida.stdout + corrida.stderr
    assert "passed" not in corrida.stdout


def test_con_el_emulador_apagado_la_corrida_falla_con_un_mensaje_claro() -> None:
    """con el emulador apagado la corrida falla con un mensaje claro
    @REV-08-S5 @assumption:REV-08-ASM-10
    """
    corrida = _correr(ESCENARIO, poner={"FIREBASE_AUTH_EMULATOR_HOST": "127.0.0.1:9"})

    assert corrida.returncode != 0
    assert "hace falta el emulador de Firebase Auth" in corrida.stdout + corrida.stderr
    assert "passed" not in corrida.stdout


def test_sin_el_emulador_de_autenticacion_la_corrida_falla() -> None:
    """sin el emulador de autenticación la suite no sale verde
    @REV-08-S5 @assumption:REV-08-ASM-03
    """
    entorno = {k: v for k, v in os.environ.items() if k != "FIREBASE_AUTH_EMULATOR_HOST"}

    corrida = subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider",
         "tests/escenarios/test_registro_de_errores.py"],
        cwd=RAIZ_API, env=entorno, capture_output=True, text=True, timeout=300, check=False,
    )  # fmt: skip

    assert corrida.returncode != 0
    assert "emulador" in corrida.stdout + corrida.stderr


def test_sin_el_emulador_se_puede_saltar_a_pedido_y_queda_dicho() -> None:
    """saltarse los tests de API sin emulador sólo pasa si se pide
    @REV-08-S5 @assumption:REV-08-ASM-03
    """
    entorno = {k: v for k, v in os.environ.items() if k != "FIREBASE_AUTH_EMULATOR_HOST"}

    corrida = subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider", "--sin-emulador",
         "tests/escenarios/test_registro_de_errores.py"],
        cwd=RAIZ_API, env=entorno, capture_output=True, text=True, timeout=300, check=False,
    )  # fmt: skip

    assert corrida.returncode == 0
    assert "skipped" in corrida.stdout


@pytest.fixture
def consultas() -> Iterator[list[str]]:
    """Las consultas SQL que hace la API mientras dura el test."""
    anotadas: list[str] = []

    def anotar(*argumentos: object) -> None:
        anotadas.append(str(argumentos[2]))

    event.listen(motor_de_la_app(), "before_cursor_execute", anotar)
    yield anotadas
    event.remove(motor_de_la_app(), "before_cursor_execute", anotar)


def _socio(
    api: TestClient, iniciar_sesion: Callable[[str, str], str | None], s: str
) -> dict[str, str]:
    correo = f"socio.{s}@correo.com"
    alta = api.post(
        "/registro",
        json={
            "nombre": "Martín",
            "apellido": "Ferreyra",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "fecha_nacimiento": "1994-07-21",
            "correo": correo,
            "contrasena": CONTRASENA,
        },
    )
    assert alta.status_code == 201
    token = iniciar_sesion(correo, CONTRASENA)
    assert token is not None
    return {"Authorization": f"Bearer {token}"}


def _proximas(motor: Engine, correo: str, espacio: int, cantidad: int) -> None:
    with motor.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
                " SELECT u.id, :e, h + make_interval(days => n), h + make_interval(days => n)"
                " + interval '1 hour', 38000, 38000 FROM usuario u,"
                " generate_series(1, :c) AS n,"
                " (SELECT date_trunc('day', now(), 'America/Argentina/Buenos_Aires')"
                " + interval '13 hours' + make_interval(days => 400) AS h) AS t"
                " WHERE u.correo = :correo AND u.activo"
            ),
            {"e": espacio, "c": cantidad, "correo": correo},
        )


def _contar(consultas: list[str], pedido: Callable[[], object]) -> int:
    consultas.clear()
    pedido()
    return len(consultas)


def test_mis_reservas_hace_las_mismas_consultas_con_pocas_o_muchas(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    consultas: list[str],
) -> None:
    """las próximas reservas se leen con una cantidad fija de consultas
    @REV-08-S6 @assumption:REV-08-ASM-05
    """
    s = unico()
    sesion = _socio(api, iniciar_sesion, s)
    with motor.begin() as conn:
        espacio = _espacio(conn, s)
    correo = f"socio.{s}@correo.com"
    _proximas(motor, correo, espacio, 2)
    pocas = _contar(consultas, lambda: api.get("/reservas", headers=sesion))
    with motor.begin() as conn:
        otro = _espacio(conn, f"{s}b")
    _proximas(motor, correo, otro, 13)

    muchas = _contar(consultas, lambda: api.get("/reservas", headers=sesion))

    assert muchas == pocas


@pytest.fixture
def admin(
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> dict[str, str]:
    s = unico()
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    argumentos = [
        "--correo", f"admin.{s}@club.com", "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert sembrar(argumentos) == 0
    token = iniciar_sesion(f"admin.{s}@club.com", CONTRASENA)
    assert token is not None
    return {"Authorization": f"Bearer {token}"}


def test_las_sedes_y_el_historial_global_hacen_consultas_fijas(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    admin: dict[str, str],
    consultas: list[str],
) -> None:
    """sedes e historial global se leen con una cantidad fija de consultas
    @REV-08-S6 @assumption:REV-08-ASM-05
    """
    s = unico()
    _socio(api, iniciar_sesion, s)
    with motor.begin() as conn:
        espacio = _espacio(conn, s)
    _proximas(motor, f"socio.{s}@correo.com", espacio, 2)
    sedes_antes = _contar(consultas, lambda: api.get("/sedes", headers=admin))
    historial_antes = _contar(consultas, lambda: api.get("/reservas/todas", headers=admin))
    with motor.begin() as conn:
        otros = [_espacio(conn, f"{s}{n}") for n in range(5)]
    _proximas(motor, f"socio.{s}@correo.com", otros[0], 13)

    sedes_despues = _contar(consultas, lambda: api.get("/sedes", headers=admin))
    historial_despues = _contar(consultas, lambda: api.get("/reservas/todas", headers=admin))

    assert sedes_despues == sedes_antes
    assert historial_despues == historial_antes


def _casos_de_uso() -> list[str]:
    fuente = (RAIZ_API / "app" / "aplicacion" / "reservas.py").read_text(encoding="utf-8")
    return [
        n.name
        for n in ast.parse(fuente).body
        if isinstance(n, ast.FunctionDef) and not n.name.startswith("_")
    ]


def test_cada_funcion_publica_de_reservas_tiene_su_unitario() -> None:
    """cada función pública de aplicacion/reservas.py tiene su unitario
    @REV-08-S7 @assumption:REV-08-ASM-09
    """
    unitarios = RAIZ_API / "tests" / "unit" / "test_casos_de_uso_reservas.py"
    codigo = unitarios.read_text(encoding="utf-8") if unitarios.exists() else ""

    assert len(_casos_de_uso()) >= 7
    assert [c for c in _casos_de_uso() if not re.search(rf"{c}\(", codigo)] == []


def test_rnf_01_h04_01_se_prueba_contra_el_contrato_publicado(api: TestClient) -> None:
    """RNF-01-H04-01 se prueba contra el contrato publicado y no leyendo el README
    @REV-08-S4 @assumption:REV-08-ASM-08
    """
    contrato = api.get("/openapi.json")
    fuente = (RAIZ_API / "tests" / "escenarios" / "test_requisitos_no_funcionales.py").read_text(
        encoding="utf-8"
    )

    assert contrato.status_code == 200
    assert len(contrato.json()["paths"]) >= 20
    assert "swagger" in api.get("/docs").text.lower()
    assert "_endpoints_que_usa_la_app" not in fuente


def test_los_casos_de_uso_de_reservas_se_prueban_sin_base_ni_emulador() -> None:
    """los casos de uso de reservas tienen unitarios que permiten medir la mutación
    @REV-08-S7
    """
    unitarios = RAIZ_API / "tests" / "unit" / "test_casos_de_uso_reservas.py"
    sin_servicios = {
        **{k: v for k, v in os.environ.items() if k != "FIREBASE_AUTH_EMULATOR_HOST"},
        "DATABASE_URL": "postgresql+psycopg://nadie:nadie@127.0.0.1:9/nada_test",
        "TEST_DATABASE_URL": "postgresql+psycopg://nadie:nadie@127.0.0.1:9/nada_test",
    }

    corrida = subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider", str(unitarios)],
        cwd=RAIZ_API, env=sin_servicios, capture_output=True, text=True, timeout=120, check=False,
    )  # fmt: skip

    assert corrida.returncode == 0, corrida.stdout[-2000:]
    codigo = unitarios.read_text(encoding="utf-8")
    assert [c for c in CASOS_DE_USO if not re.search(rf"\b{c}\(", codigo)] == []
