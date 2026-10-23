"""Operación: base que no responde, recordatorios fuera del proceso web, respaldo, usuario propio,
referencia del error, correlación, arranque, métricas y versión."""

import json
import logging
import os
import re
import select
import socket
import subprocess
import sys
import threading
import time
import tomllib
from collections.abc import Callable, Iterator
from contextlib import contextmanager
from pathlib import Path

import httpx2
import pytest
from fastapi import Depends
from fastapi.testclient import TestClient
from sqlalchemy import Connection, Engine, create_engine, text
from sqlalchemy.exc import OperationalError, ProgrammingError

from app.config import Config, config
from app.infraestructura.db import conexion, motor as motor_app
from app.infraestructura.usuarios import UsuariosSql
from app.main import crear_app

RAIZ_API = Path(__file__).resolve().parents[2]
RAIZ_REPO = RAIZ_API.parents[1]
CONTRASENA = "ClubNahuel1"
VERSION = tomllib.loads((RAIZ_API / "pyproject.toml").read_text(encoding="utf-8"))["project"][
    "version"
]
MENSAJE_500 = "Ocurrió un error. Si le escribís a soporte, pasale esta referencia."


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _datos_de_alta(s: str) -> dict[str, str]:
    return {
        "nombre": "Martín",
        "apellido": "Ferreyra",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "fecha_nacimiento": "1994-07-21",
        "correo": f"socio.{s}@correo.com",
        "contrasena": CONTRASENA,
    }


@pytest.fixture
def token_usuario(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> str:
    s = unico()
    assert api.post("/registro", json=_datos_de_alta(s)).status_code == 201
    token = iniciar_sesion(f"socio.{s}@correo.com", CONTRASENA)
    assert token is not None
    return token


class _Corte:
    """Un intermediario TCP hacia Postgres que se puede cortar como un agujero negro:
    cierra las conexiones abiertas y las nuevas quedan sin respuesta."""

    def __init__(self, destino: tuple[str, int]) -> None:
        self.destino = destino
        self.cortado = False
        self.abiertas: list[socket.socket] = []
        self.escucha = socket.create_server(("127.0.0.1", 0))
        self.puerto = int(self.escucha.getsockname()[1])
        threading.Thread(target=self._aceptar, daemon=True).start()

    def _aceptar(self) -> None:
        while True:
            try:
                cliente, _ = self.escucha.accept()
            except OSError:
                return
            self.abiertas.append(cliente)
            if not self.cortado:
                threading.Thread(target=self._pasar, args=(cliente,), daemon=True).start()

    def _pasar(self, cliente: socket.socket) -> None:
        base = socket.create_connection(self.destino)
        self.abiertas.append(base)
        pares = {cliente: base, base: cliente}
        try:
            while not self.cortado:
                listos, _, _ = select.select(list(pares), [], [], 0.2)
                for origen in listos:
                    datos = origen.recv(65536)
                    if not datos:
                        return
                    pares[origen].sendall(datos)
        except OSError:
            return

    def cortar(self) -> None:
        self.cortado = True
        for s in self.abiertas:
            s.close()

    def cerrar(self) -> None:
        self.cortar()
        self.escucha.close()


def _puerto_libre() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return int(s.getsockname()[1])


@contextmanager
def _servir(url: str, salida: Path) -> Iterator[tuple[str, "subprocess.Popen[bytes]"]]:
    """La API servida por uvicorn, como en Render, contra la base de [url]."""
    puerto = _puerto_libre()
    with salida.open("w", encoding="utf-8") as archivo:
        proceso = subprocess.Popen(
            [sys.executable, "-m", "uvicorn", "app.main:app", "--host", "127.0.0.1"]
            + ["--port", str(puerto)],
            cwd=RAIZ_API,
            stdout=archivo,
            stderr=subprocess.STDOUT,
            env={**os.environ, "DATABASE_URL": url, "PYTHONUTF8": "1", "PYTHONUNBUFFERED": "1"},
        )
        base = f"http://127.0.0.1:{puerto}"
        limite = time.monotonic() + 90
        while time.monotonic() < limite and proceso.poll() is None:
            try:
                httpx2.get(f"{base}/health", timeout=2)
                break
            except httpx2.HTTPError:
                time.sleep(0.5)
        try:
            yield base, proceso
        finally:
            proceso.terminate()
            proceso.wait(timeout=30)


@pytest.fixture
def api_con_corte(motor: Engine, tmp_path: Path) -> Iterator[tuple[str, _Corte, Path]]:
    """La API servida por uvicorn con la base detrás de un intermediario que se puede cortar."""
    url = motor.url
    corte = _Corte((url.host or "127.0.0.1", int(url.port or 5432)))
    url_cortable = url.set(host="127.0.0.1", port=corte.puerto).render_as_string(hide_password=False)
    salida = tmp_path / "uvicorn.log"
    with _servir(url_cortable, salida) as (base, _):
        yield base, corte, salida
    corte.cerrar()


@pytest.fixture
def base_vacia(motor: Engine) -> Iterator[str]:
    """Otra base de pruebas, vacía, para restaurar el respaldo o arrancar sin esquema."""
    nombre = "club_rev02_restaurada_test"
    admin = create_engine(motor.url.set(database="postgres"), isolation_level="AUTOCOMMIT")
    with admin.connect() as conn:
        conn.execute(text(f"DROP DATABASE IF EXISTS {nombre} WITH (FORCE)"))
        conn.execute(text(f"CREATE DATABASE {nombre}"))
    admin.dispose()
    yield motor.url.set(database=nombre).render_as_string(hide_password=False)


@pytest.fixture
def con_otra_base(monkeypatch: pytest.MonkeyPatch) -> Iterator[Callable[[str], None]]:
    """Apunta la API de este proceso a otra base; al terminar vuelve a la de pruebas."""

    def apuntar(url: str) -> None:
        monkeypatch.setattr(config, "database_url", url)
        motor_app.cache_clear()

    yield apuntar
    monkeypatch.undo()
    motor_app().dispose()
    motor_app.cache_clear()


def test_con_la_base_inalcanzable_un_pedido_falla_rapido(
    api_con_corte: tuple[str, _Corte, Path], token_usuario: str
) -> None:
    """con la base inalcanzable un pedido falla rápido, en 5 s, con un 503 controlado @REV-02-S1
    @assumption:REV-02-ASM-03
    """
    base, corte, _ = api_con_corte
    assert httpx2.get(f"{base}/yo", headers=_con(token_usuario), timeout=30).status_code == 200
    corte.cortar()

    antes = time.monotonic()
    r = httpx2.get(f"{base}/yo", headers=_con(token_usuario), timeout=60)
    demora = time.monotonic() - antes

    assert r.status_code == 503
    assert set(r.json()) == {"mensaje", "referencia"}
    assert demora < 9


def test_una_consulta_de_mas_de_10_s_se_corta_con_un_503_de_la_base(api: TestClient) -> None:
    """una consulta que pasa de 10 s se corta con un 503 @REV-02-S1 @assumption:REV-02-ASM-03"""
    app = crear_app()

    def lenta(conn: Connection = Depends(conexion)) -> None:
        conn.execute(text("SELECT pg_sleep(30)"))

    app.add_api_route("/lenta", lenta)
    with TestClient(app) as cliente:
        antes = time.monotonic()
        r = cliente.get("/lenta")
        demora = time.monotonic() - antes

    assert r.status_code == 503
    assert "referencia" in r.json()
    assert 9 < demora < 14


def test_esperar_un_lugar_en_el_pool_mas_de_5_s_da_un_503_de_la_base(
    api: TestClient, token_usuario: str
) -> None:
    """esperar un lugar en el pool más de 5 s da un 503 @REV-02-S1 @assumption:REV-02-ASM-03"""
    from app.infraestructura.db import POOL_MAXIMO

    ocupadas = [motor_app().connect() for _ in range(POOL_MAXIMO)]
    try:
        antes = time.monotonic()
        r = api.get("/yo", headers=_con(token_usuario))
        demora = time.monotonic() - antes
    finally:
        for c in ocupadas:
            c.close()

    assert r.status_code == 503
    assert "referencia" in r.json()
    assert 4.5 < demora < 9


def test_esperar_un_bloqueo_de_la_base_mas_de_5_s_da_un_503(
    api: TestClient, motor: Engine, token_usuario: str
) -> None:
    """esperar un bloqueo más de 5 s da un 503 @REV-02-S1 @assumption:REV-02-ASM-03"""
    bloqueo = motor.connect()
    try:
        bloqueo.execute(text("LOCK TABLE usuario IN ACCESS EXCLUSIVE MODE"))
        antes = time.monotonic()
        r = api.get("/yo", headers=_con(token_usuario))
        demora = time.monotonic() - antes
    finally:
        bloqueo.rollback()
        bloqueo.close()

    assert r.status_code == 503
    assert "referencia" in r.json()
    assert 4.5 < demora < 9


def test_el_chequeo_de_disponibilidad_mira_la_base(
    api_con_corte: tuple[str, _Corte, Path],
) -> None:
    """el chequeo de disponibilidad dice que la API no está lista sin base @REV-02-S2"""
    base, corte, _ = api_con_corte
    lista = httpx2.get(f"{base}/ready", timeout=30)
    corte.cortar()

    caida = httpx2.get(f"{base}/ready", timeout=60)
    viva = httpx2.get(f"{base}/health", timeout=30)

    assert lista.status_code == 200
    assert caida.status_code == 503
    assert viva.status_code == 200


def test_el_despliegue_chequea_la_disponibilidad() -> None:
    """Render reinicia la API cuando no está lista @REV-02-S2 @assumption:REV-02-ASM-03"""
    import yaml

    blueprint = yaml.safe_load((RAIZ_REPO / "render.yaml").read_text(encoding="utf-8"))

    assert blueprint["services"][0]["healthCheckPath"] == "/ready"


def test_sin_base_o_sin_esquema_la_api_sigue_en_pie_y_ready_da_503(
    base_vacia: str, tmp_path: Path
) -> None:
    """sin base o sin esquema la API no arranca sana: el proceso sigue y /ready responde 503
    @REV-02-S12 @assumption:REV-02-ASM-18
    """
    sin_base = "postgresql+psycopg://club:club@127.0.0.1:9/nada_test"
    resultados = []
    for url in (base_vacia, sin_base):
        with _servir(url, tmp_path / "arranque.log") as (base, proceso):
            resultados.append(
                (
                    proceso.poll(),
                    httpx2.get(f"{base}/ready", timeout=30).status_code,
                    httpx2.get(f"{base}/health", timeout=30).status_code,
                )
            )

    assert resultados == [(None, 503, 200), (None, 503, 200)]


def test_la_api_no_arranca_sana_sin_el_esquema(
    base_vacia: str, con_otra_base: Callable[[str], None], caplog: pytest.LogCaptureFixture
) -> None:
    """la API no arranca sana si la base no tiene el esquema @REV-02-S12"""
    con_otra_base(base_vacia)

    with caplog.at_level(logging.INFO), TestClient(crear_app()) as cliente:
        lista = cliente.get("/ready")

    errores = [r.getMessage() for r in caplog.records if r.levelno >= logging.ERROR]
    assert lista.status_code == 503
    assert any("esquema" in m for m in errores)


def test_la_api_no_arranca_sana_sin_base(
    con_otra_base: Callable[[str], None], caplog: pytest.LogCaptureFixture
) -> None:
    """la API no arranca sana si no hay base @REV-02-S12"""
    con_otra_base("postgresql+psycopg://club:club@127.0.0.1:9/nada_test")

    with caplog.at_level(logging.INFO), TestClient(crear_app()) as cliente:
        lista = cliente.get("/ready")

    errores = [r.getMessage() for r in caplog.records if r.levelno >= logging.ERROR]
    assert lista.status_code == 503
    assert any("base" in m for m in errores)


def _reserva_en_la_proxima_hora(motor: Engine, correo: str, s: str) -> int:
    with motor.begin() as conn:
        return int(
            conn.execute(
                text(
                    "WITH s AS (INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
                    " VALUES (:n, 'Av. Vergara', 1850, '00:00', '23:59', ARRAY[1,2,3,4,5,6,7])"
                    " RETURNING id),"
                    " e AS (INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada,"
                    " iluminada, precio_por_hora) SELECT id, 'Futbol', 'F5', 1, :e, false, true,"
                    " 38000 FROM s RETURNING id)"
                    " INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora,"
                    " total, creado_en, modificado_en)"
                    " SELECT u.id, e.id, h, h + interval '1 hour', 38000, 38000,"
                    " now() - interval '2 hours', now() - interval '2 hours' FROM usuario u, e,"
                    " (SELECT date_trunc('hour', now(), 'America/Argentina/Buenos_Aires')"
                    " + interval '1 hour' AS h) AS t WHERE u.correo = :c AND u.activo"
                    " RETURNING reserva.id"
                ),
                {"n": f"Sede Haedo {s}", "e": f"Haedo{s}_Vergara_1850_Futbol_F5_1", "c": correo},
            ).scalar_one()
        )


def test_los_recordatorios_salen_con_un_comando_fuera_del_servicio_web(
    api: TestClient, motor: Engine, unico: Callable[[], str]
) -> None:
    """los recordatorios salen aunque el servicio web esté dormido @REV-02-S3
    @assumption:REV-02-ASM-02
    """
    s = unico()
    api.post("/registro", json=_datos_de_alta(s))
    reserva = _reserva_en_la_proxima_hora(motor, f"socio.{s}@correo.com", s)

    corrida = subprocess.run(
        [sys.executable, "-m", "app.interfaz.barrido", "--una-vez"],
        cwd=RAIZ_API, env={**os.environ, "PYTHONUTF8": "1"},
        capture_output=True, text=True, timeout=120, check=False,
    )  # fmt: skip

    assert corrida.returncode == 0, corrida.stdout + corrida.stderr
    with motor.connect() as conn:
        avisos = conn.execute(
            text("SELECT count(*) FROM notificacion WHERE tipo = 'recordatorio' AND reserva_id = :r"),
            {"r": reserva},
        ).scalar_one()
    assert avisos == 1


class _CanalQueFalla:
    def enviar(self, tokens: list[str], aviso: object) -> object:
        raise ConnectionError("FCM no responde")


def test_un_aviso_que_no_salio_queda_a_la_vista(
    motor: Engine, caplog: pytest.LogCaptureFixture
) -> None:
    """un recordatorio que no salió queda a la vista de quien opera @REV-02-S4"""
    from app.aplicacion.notificaciones import despachar_pendientes
    from app.infraestructura.notificaciones import NotificacionesSql

    with motor.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, envio)"
                " SELECT id, 'cancelacion_usuario', 'Cancelaste tu reserva', 'Fútbol 5',"
                " 'pendiente' FROM usuario WHERE activo LIMIT 1"
            )
        )
        conn.execute(
            text(
                "INSERT INTO dispositivo (usuario_id, token, plataforma, permiso)"
                " SELECT usuario_id, 'fcm-' || id, 'android', true FROM notificacion"
                " WHERE envio = 'pendiente' ON CONFLICT DO NOTHING"
            )
        )

    with caplog.at_level(logging.INFO), motor.connect() as conn:
        despachar_pendientes(NotificacionesSql(conn), _CanalQueFalla())

    errores = [r for r in caplog.records if r.levelno >= logging.ERROR]
    assert any("aviso_sin_enviar" in r.getMessage() for r in errores)
    assert not any("fcm-" in r.getMessage() for r in caplog.records)


def test_el_respaldo_se_guarda_y_se_restaura(
    motor: Engine, base_vacia: str, tmp_path: Path
) -> None:
    """la base de producción tiene copia de seguridad y una vuelta atrás probada
    @REV-02-S5 @assumption:REV-02-ASM-01
    """
    archivo = tmp_path / "club.dump"
    origen = motor.url.render_as_string(hide_password=False)
    script = RAIZ_REPO / "scripts" / "respaldo.py"

    guardado = subprocess.run(
        [sys.executable, str(script), "guardar", "--url", origen, "--archivo", str(archivo)],
        capture_output=True, text=True, timeout=300, check=False,
    )  # fmt: skip
    restaurado = subprocess.run(
        [sys.executable, str(script), "restaurar", "--url", base_vacia, "--archivo", str(archivo)],
        capture_output=True, text=True, timeout=300, check=False,
    )  # fmt: skip

    assert guardado.returncode == 0, guardado.stderr
    assert restaurado.returncode == 0, restaurado.stderr
    assert _cuenta(base_vacia, "usuario") == _cuenta(origen, "usuario")
    assert _cuenta(base_vacia, "reserva") == _cuenta(origen, "reserva")


def _cuenta(url: str, tabla: str) -> int:
    otra = create_engine(url)
    with otra.connect() as conn:
        cantidad = int(conn.execute(text(f"SELECT count(*) FROM {tabla}")).scalar_one())
    otra.dispose()
    return cantidad


def test_la_app_entra_con_un_usuario_que_no_cambia_el_esquema(
    motor: Engine, unico: Callable[[], str]
) -> None:
    """la app se conecta con un usuario de base que no puede cambiar el esquema
    @REV-02-S6 @assumption:REV-02-ASM-04
    """
    clave = f"clave-{unico()}"
    creado = subprocess.run(
        [sys.executable, str(RAIZ_REPO / "scripts" / "usuario_de_la_app.py"),
         "--url", motor.url.render_as_string(hide_password=False), "--clave", clave],
        capture_output=True, text=True, timeout=120, check=False,
    )  # fmt: skip
    assert creado.returncode == 0, creado.stderr
    app = create_engine(motor.url.set(username="club_app", password=clave))

    with app.connect() as conn:
        leidas = conn.execute(text("SELECT count(*) FROM reserva")).scalar_one()
        with pytest.raises(ProgrammingError, match="permission denied|permiso denegado"):
            conn.execute(text("CREATE TABLE intrusa (id int)"))
    app.dispose()

    assert leidas >= 0


def test_un_error_del_servidor_da_una_referencia_que_esta_en_el_log(
    token_usuario: str,
    monkeypatch: pytest.MonkeyPatch,
    caplog: pytest.LogCaptureFixture,
) -> None:
    """un error del servidor da un número de referencia que soporte encuentra en el log
    @REV-02-S7 @REV-02-S10
    """

    def romper(*_: object, **__: object) -> None:
        raise RuntimeError("falla inesperada")

    monkeypatch.setattr(UsuariosSql, "perfil_activo", romper)
    with caplog.at_level(logging.INFO), TestClient(crear_app(), raise_server_exceptions=False) as c:
        r = c.get("/yo", headers=_con(token_usuario))

    referencia = r.json()["referencia"]
    errores = [x for x in caplog.records if x.levelno >= logging.ERROR]
    assert r.status_code == 500
    assert r.headers["x-request-id"] == referencia
    assert "falla inesperada" not in r.text
    propios = [x for x in errores if getattr(x, "referencia", None) == referencia]
    assert len(errores) == 1 and len(propios) == 1
    assert getattr(propios[0], "version", None) == VERSION


def test_la_referencia_del_error_es_el_id_de_correlacion_del_pedido(
    token_usuario: str, monkeypatch: pytest.MonkeyPatch
) -> None:
    """la referencia del error es el id de correlación del pedido @REV-02-S7
    @assumption:REV-02-ASM-05
    """

    def romper(*_: object, **__: object) -> None:
        raise RuntimeError("falla inesperada")

    monkeypatch.setattr(UsuariosSql, "perfil_activo", romper)
    with TestClient(crear_app(), raise_server_exceptions=False) as c:
        r = c.get("/yo", headers={**_con(token_usuario), "X-Request-ID": "pedido-propio-77"})

    assert r.status_code == 500
    assert r.json()["referencia"] == "pedido-propio-77"


def test_el_500_y_el_503_responden_mensaje_y_referencia_sin_traceback(
    token_usuario: str, monkeypatch: pytest.MonkeyPatch
) -> None:
    """el 500 y el 503 responden mensaje y referencia, sin traceback @REV-02-S7
    @assumption:REV-02-ASM-16
    """
    errores: list[Exception] = [
        RuntimeError("falla inesperada"),
        OperationalError("SELECT 1", {}, Exception("detalle interno de la base")),
    ]
    respuestas = []
    for error in errores:

        def romper(*_: object, _e: Exception = error, **__: object) -> None:
            raise _e

        monkeypatch.setattr(UsuariosSql, "perfil_activo", romper)
        with TestClient(crear_app(), raise_server_exceptions=False) as c:
            respuestas.append(c.get("/yo", headers=_con(token_usuario)))

    assert [r.status_code for r in respuestas] == [500, 503]
    for r in respuestas:
        assert set(r.json()) == {"mensaje", "referencia"}
        for filtrado in ("Traceback", "falla inesperada", "detalle interno", "SELECT 1"):
            assert filtrado not in r.text
    assert respuestas[0].json()["mensaje"] == MENSAJE_500


def test_el_openapi_documenta_el_500_el_503_ready_y_metrics(api: TestClient) -> None:
    """el OpenAPI documenta el 500, el 503, /ready y /metrics @REV-02-S7
    @assumption:REV-02-ASM-16
    """
    contrato = api.get("/openapi.json").json()

    assert "/ready" in contrato["paths"]
    assert "/metrics" in contrato["paths"]
    respuestas = contrato["paths"]["/yo"]["get"]["responses"]
    assert "500" in respuestas
    assert "503" in respuestas


def test_el_500_y_el_503_llevan_el_id_de_correlacion_en_la_respuesta(
    token_usuario: str, monkeypatch: pytest.MonkeyPatch
) -> None:
    """el 500 y el 503 llevan X-Request-ID @REV-02-S9 @assumption:REV-02-ASM-07"""
    cabeceras = []
    for error in (RuntimeError("x"), OperationalError("SELECT 1", {}, Exception("y"))):

        def romper(*_: object, _e: Exception = error, **__: object) -> None:
            raise _e

        monkeypatch.setattr(UsuariosSql, "perfil_activo", romper)
        with TestClient(crear_app(), raise_server_exceptions=False) as c:
            r = c.get("/yo", headers={**_con(token_usuario), "X-Request-ID": "caida-9"})
        cabeceras.append((r.status_code, r.headers["x-request-id"], r.json()["referencia"]))

    assert cabeceras == [(500, "caida-9", "caida-9"), (503, "caida-9", "caida-9")]


def test_cada_pedido_lleva_su_id_de_correlacion_en_el_log_y_en_la_respuesta(
    api: TestClient, caplog: pytest.LogCaptureFixture
) -> None:
    """cada pedido lleva un id de correlación en sus líneas de log y en la respuesta @REV-02-S9
    @assumption:REV-02-ASM-07
    """
    with caplog.at_level(logging.INFO):
        propio = api.get("/yo", headers={"X-Request-ID": "pedido-abc-123"})
        nuevo = api.get("/yo")

    assert propio.headers["x-request-id"] == "pedido-abc-123"
    assert re.fullmatch(r"[0-9a-f-]{16,}", nuevo.headers["x-request-id"])
    assert any(getattr(r, "referencia", None) == "pedido-abc-123" for r in caplog.records)
    assert any(getattr(r, "referencia", None) == nuevo.headers["x-request-id"] for r in caplog.records)


@pytest.mark.parametrize("ajeno", ["x" * 65, "con espacios", "a;b", "linea\tcon-tab", "ñandú"])
def test_un_id_de_correlacion_ajeno_invalido_se_reemplaza_por_uno_generado(
    api: TestClient, ajeno: str
) -> None:
    """un X-Request-ID de más de 64 caracteres o con otros signos se reemplaza por uno generado
    @REV-02-S9 @assumption:REV-02-ASM-07
    """
    r = api.get("/yo", headers={"X-Request-ID": ajeno.encode("utf-8")})

    assert r.status_code == 401
    assert r.headers["x-request-id"] != ajeno
    assert re.fullmatch(r"[0-9a-f-]{16,}", r.headers["x-request-id"])


def test_el_registro_sale_en_json_por_linea_con_nivel_evento_referencia_y_version(
    api_con_corte: tuple[str, _Corte, Path],
) -> None:
    """el registro sale en JSON por línea con nivel, evento, referencia y versión @REV-02-S10
    @assumption:REV-02-ASM-10
    """
    base, _, salida = api_con_corte
    httpx2.get(f"{base}/yo", headers={"X-Request-ID": "json-001"}, timeout=30)
    time.sleep(1)

    lineas = [json.loads(x) for x in salida.read_text(encoding="utf-8").splitlines() if x[:1] == "{"]
    rechazo = [x for x in lineas if x.get("referencia") == "json-001"]
    assert rechazo
    assert {"nivel", "evento", "referencia", "version", "mensaje"} <= set(rechazo[0])
    assert rechazo[0]["nivel"] == "WARNING"
    assert rechazo[0]["version"] == VERSION
    assert rechazo[0]["evento"]


def test_el_log_json_no_lleva_datos_personales_ni_secretos_en_el_registro(
    api_con_corte: tuple[str, _Corte, Path], unico: Callable[[], str]
) -> None:
    """el log JSON no lleva DNI, correo, token de dispositivo, Authorization ni la contraseña de
    la base @REV-02-S10 @assumption:REV-02-ASM-17
    """
    base, _, salida = api_con_corte
    s = unico()
    datos = _datos_de_alta(s)
    httpx2.post(f"{base}/registro", json=datos, timeout=30)
    httpx2.post(f"{base}/registro", json=datos, timeout=30)
    httpx2.get(f"{base}/yo", headers=_con("token-secreto-9Z"), timeout=30)
    httpx2.put(
        f"{base}/yo/dispositivo", json={"token": "fcm-secreto-4K", "plataforma": "android"},
        headers=_con("token-secreto-9Z"), timeout=30,
    )  # fmt: skip
    time.sleep(1)

    log = salida.read_text(encoding="utf-8")
    assert '"nivel"' in log
    for dato in (datos["dni"], datos["correo"], "token-secreto-9Z", "fcm-secreto-4K", "club:club@"):
        assert dato not in log
    assert "authorization" not in log.lower()


def test_hay_metricas_por_ruta_y_del_pool(api: TestClient, monkeypatch: pytest.MonkeyPatch) -> None:
    """hay métricas por ruta y del pool de conexiones @REV-02-S13 @assumption:REV-02-ASM-08"""
    monkeypatch.setattr(config, "metricas_token", "metricas-secretas")
    api.get("/yo")

    metricas = api.get("/metrics", headers=_con("metricas-secretas"))

    assert metricas.status_code == 200
    assert re.search(r'solicitudes_total\{[^}]*ruta="/yo"[^}]*codigo="401"[^}]*\} \d+', metricas.text)
    assert re.search(r"solicitud_segundos_bucket\{[^}]*ruta=\"/yo\"", metricas.text)
    assert re.search(r"pool_conexiones_en_uso \d+", metricas.text)
    assert re.search(r"pool_conexiones_libres \d+", metricas.text)


def test_metricas_sin_token_con_uno_malo_o_sin_token_configurado_responde_404(
    api: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    """/metrics sin token, con uno malo o sin METRICAS_TOKEN responde 404 @REV-02-S13
    @assumption:REV-02-ASM-14
    """
    monkeypatch.setattr(config, "metricas_token", "metricas-secretas")
    sin_token = api.get("/metrics")
    malo = api.get("/metrics", headers=_con("otro"))
    monkeypatch.setattr(config, "metricas_token", "")
    sin_definir = api.get("/metrics", headers=_con(""))
    sin_definir_con_token = api.get("/metrics", headers=_con("metricas-secretas"))

    assert [r.status_code for r in (sin_token, malo, sin_definir, sin_definir_con_token)] == [404] * 4


def test_las_metricas_usan_la_plantilla_de_la_ruta_y_las_rutas_inexistentes_suman_a_sin_ruta(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """las métricas usan la plantilla de la ruta y las rutas que no existen suman a sin_ruta
    @REV-02-S13 @assumption:REV-02-ASM-15
    """
    monkeypatch.setattr(config, "metricas_token", "metricas-secretas")
    app = crear_app()
    app.add_api_route("/cosas/{cosa_id}", lambda cosa_id: {"id": cosa_id})
    with TestClient(app) as c:
        c.get("/cosas/77")
        c.get("/cosas/88")
        c.get("/no-existe-ni-existira-123")
        metricas = c.get("/metrics", headers=_con("metricas-secretas")).text

    assert 'ruta="/cosas/{cosa_id}"' in metricas
    assert 'ruta="/cosas/77"' not in metricas
    assert 'ruta="/no-existe-ni-existira-123"' not in metricas
    assert re.search(r'solicitudes_total\{[^}]*ruta="sin_ruta"[^}]*codigo="404"', metricas)


def test_la_version_vive_en_pyproject_y_la_api_la_expone(api: TestClient) -> None:
    """la versión vive en pyproject.toml y la API la expone @REV-02-S14 @assumption:REV-02-ASM-09"""
    salud = api.get("/health").json()

    assert salud["version"] == VERSION
    assert config.version == VERSION


def test_la_version_vive_en_un_solo_lugar_y_la_api_la_expone(api: TestClient) -> None:
    """la versión vive en un solo lugar y la API la expone @REV-02-S14"""
    contrato = api.get("/openapi.json").json()

    assert contrato["info"]["version"] == VERSION
    assert VERSION not in (RAIZ_API / "app" / "main.py").read_text(encoding="utf-8")


def test_la_configuracion_se_lee_igual_desde_cualquier_carpeta() -> None:
    """la configuración se lee igual desde cualquier carpeta de arranque @REV-02-S15"""
    archivo = Path(str(Config.model_config.get("env_file")))

    assert archivo.is_absolute()
    assert archivo == RAIZ_API / ".env"
