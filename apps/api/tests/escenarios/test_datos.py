"""Datos: índices, historiales por tandas, avisos varados y migraciones seguras."""

import os
import threading
from collections.abc import Callable, Iterator
from pathlib import Path
from typing import Any

import pytest
from alembic import command
from alembic.config import Config as AlembicConfig
from fastapi.testclient import TestClient
from sqlalchemy import Engine, create_engine, text
from sqlalchemy.exc import OperationalError
from test_recordatorio import CanalDePrueba, Socio, a_las, un_socio

from app.aplicacion.notificaciones import despachar_pendientes, enviar_recordatorios
from app.infraestructura.notificaciones import NotificacionesSql
from app.infraestructura.push import canal_push
from app.interfaz.sembrar_admin import main as sembrar

RAIZ_API = Path(__file__).resolve().parents[2]
# conftest.py deja acá la base de pruebas antes de importar los tests.
URL_PRUEBAS = os.environ["DATABASE_URL"]
CONTRASENA = "ClubNahuel1"
URL_MIGRACIONES = URL_PRUEBAS.rsplit("/", 1)[0] + "/club_rev03_migraciones_test"
REVISIONES = ["0002", "0003", "0004", "0005", "0006", "0007", "0008"]


@pytest.fixture
def canal(api: TestClient) -> Iterator[CanalDePrueba]:
    canal = CanalDePrueba()
    api.app.dependency_overrides[canal_push] = lambda: canal
    yield canal
    api.app.dependency_overrides.pop(canal_push, None)


@pytest.fixture
def socio(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> Socio:
    return un_socio(api, motor, iniciar_sesion, unico)


@pytest.fixture
def token_admin(
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> str:
    s = unico()
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    argumentos = [
        "--correo", f"admin.{s}@club.com", "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert sembrar(argumentos) == 0
    token = iniciar_sesion(f"admin.{s}@club.com", CONTRASENA)
    assert token is not None
    return token


def _pasadas(socio: Socio, cantidad: int) -> None:
    """[cantidad] reservas ya jugadas del socio, una por día hacia atrás."""
    with socio.motor.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
                " SELECT :u, :e, h - make_interval(days => n), h - make_interval(days => n)"
                " + interval '1 hour', 38000, 38000"
                " FROM generate_series(1, :c) AS n,"
                " (SELECT date_trunc('hour', now(), 'America/Argentina/Buenos_Aires') AS h) AS t"
            ),
            {"u": socio.usuario_id, "e": socio.espacio_id, "c": cantidad},
        )


def _indices(motor: Engine, tabla: str) -> list[str]:
    with motor.connect() as conn:
        return [
            str(f.indexdef)
            for f in conn.execute(
                text("SELECT indexdef FROM pg_indexes WHERE tablename = :t"), {"t": tabla}
            )
        ]


def test_el_historial_propio_tiene_un_indice_por_socio(motor: Engine) -> None:
    """el historial propio se resuelve con un índice por socio @REV-03-S1"""
    indices = _indices(motor, "reserva")

    assert any("(usuario_id" in i for i in indices)


def _empate(socio: Socio) -> None:
    """Una reserva más, en otra cancha de la misma sede, con el mismo inicio que la vigésima."""
    with socio.motor.begin() as conn:
        conn.execute(
            text(
                "WITH e AS (INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada,"
                " iluminada, precio_por_hora) SELECT sede_id, deporte, tipo, numero + 1,"
                " nombre || '_bis', techada, iluminada, precio_por_hora FROM espacio"
                " WHERE id = :e RETURNING id)"
                " INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
                " SELECT :u, e.id, h - interval '20 days', h - interval '20 days'"
                " + interval '1 hour', 38000, 38000 FROM e,"
                " (SELECT date_trunc('hour', now(), 'America/Argentina/Buenos_Aires') AS h) AS t"
            ),
            {"u": socio.usuario_id, "e": socio.espacio_id},
        )


def test_el_historial_propio_llega_por_tandas(api: TestClient, socio: Socio) -> None:
    """el historial propio de reservas se entrega por páginas @REV-03-S2"""
    _pasadas(socio, 25)
    _empate(socio)

    primera = api.get("/reservas", headers=socio.sesion, params={"cuando": "historial"}).json()
    segunda = api.get(
        "/reservas",
        headers=socio.sesion,
        params={"cuando": "historial", "despues": primera["siguiente"]},
    ).json()

    assert len(primera["reservas"]) == 20
    assert len(segunda["reservas"]) == 6
    assert segunda["siguiente"] is None
    ids = [r["id"] for r in primera["reservas"] + segunda["reservas"]]
    assert len(set(ids)) == 26


MARCADORES_INVALIDOS = ["no-es", "", "AAAA", "eyJ4IjoxfQ", "MjAyNi0xMS0xMlQwMDowMDowMHxhYmM"]


@pytest.mark.parametrize("marcador", MARCADORES_INVALIDOS)
def test_un_marcador_de_tanda_que_no_se_entiende_es_un_dato_invalido(
    api: TestClient, socio: Socio, marcador: str
) -> None:
    """un marcador de página inválido se rechaza @REV-03-S2 @assumption:REV-03-ASM-01"""
    r = api.get(
        "/reservas", headers=socio.sesion, params={"cuando": "historial", "despues": marcador}
    )

    assert r.status_code == 422
    assert "despues" in r.json()["errores"]


@pytest.mark.parametrize("marcador", MARCADORES_INVALIDOS)
def test_un_marcador_invalido_del_historial_global_es_un_dato_invalido(
    api: TestClient, token_admin: str, marcador: str
) -> None:
    """un marcador inválido del historial global se rechaza @REV-03-S3 @assumption:REV-03-ASM-01"""
    r = api.get(
        "/reservas/todas",
        headers={"Authorization": f"Bearer {token_admin}"},
        params={"despues": marcador},
    )

    assert r.status_code == 422
    assert "despues" in r.json()["errores"]


def test_el_historial_global_avanza_por_marcador(
    api: TestClient, socio: Socio, token_admin: str
) -> None:
    """una página avanzada del historial global se resuelve por marcador @REV-03-S3"""
    _pasadas(socio, 25)
    _empate(socio)
    admin = {"Authorization": f"Bearer {token_admin}"}
    filtro = {"q": socio.sede}

    primera = api.get("/reservas/todas", headers=admin, params=filtro).json()
    segunda = api.get(
        "/reservas/todas", headers=admin, params={**filtro, "despues": primera["siguiente"]}
    ).json()

    assert len(primera["reservas"]) == 20
    assert len(segunda["reservas"]) == 6
    assert segunda["siguiente"] is None
    reservas = primera["reservas"] + segunda["reservas"]
    inicios = [r["inicio"] for r in reservas]
    assert inicios == sorted(inicios, reverse=True)
    assert len({r["id"] for r in reservas}) == 26
    assert primera["total"] == 26


def test_las_apps_instaladas_siguen_paginando_por_numero(
    api: TestClient, socio: Socio, token_admin: str
) -> None:
    """el historial global sigue aceptando la página de las apps instaladas
    @REV-03-S3 @assumption:REV-03-ASM-11
    """
    _pasadas(socio, 25)
    admin = {"Authorization": f"Bearer {token_admin}"}
    filtro = {"q": socio.sede}
    primera = api.get("/reservas/todas", headers=admin, params=filtro).json()

    por_numero = api.get("/reservas/todas", headers=admin, params={**filtro, "pagina": 2}).json()
    los_dos = api.get(
        "/reservas/todas",
        headers=admin,
        params={**filtro, "pagina": 1, "despues": primera["siguiente"]},
    ).json()

    assert len(por_numero["reservas"]) == 5
    assert [r["id"] for r in los_dos["reservas"]] == [r["id"] for r in por_numero["reservas"]]


def test_el_historial_global_tiene_un_indice_por_fecha(motor: Engine) -> None:
    """el historial global se ordena por un índice de inicio @REV-03-S3"""
    indices = _indices(motor, "reserva")

    assert any("(inicio DESC, id DESC)" in i for i in indices)


def test_quien_cancelo_y_que_aviso_reemplazo_tienen_indice(motor: Engine) -> None:
    """quién canceló y qué aviso reemplazó a otro se consultan por índice @REV-03-S4"""
    assert any("(cancelada_por" in i for i in _indices(motor, "reserva"))
    assert any("(reemplazada_por" in i for i in _indices(motor, "notificacion"))


def _envios(socio: Socio) -> list[str]:
    with socio.motor.connect() as conn:
        return [
            str(f.envio)
            for f in conn.execute(
                text("SELECT envio FROM notificacion WHERE usuario_id = :u ORDER BY id"),
                {"u": socio.usuario_id},
            )
        ]


def _varar(socio: Socio, hace: str, intentos: int = 1) -> None:
    with socio.motor.begin() as conn:
        conn.execute(
            text(
                "UPDATE notificacion SET envio = 'enviando', enviada_en = NULL,"
                " tomada_en = now() - CAST(:hace AS interval), intentos = :i"
                " WHERE usuario_id = :u"
            ),
            {"u": socio.usuario_id, "hace": hace, "i": intentos},
        )


def _cancelar(socio: Socio, desde: str) -> None:
    reserva = socio.reservar(desde)
    r = socio.api.post(f"/reservas/{reserva['id']}/cancelar", headers=socio.sesion)
    assert r.status_code == 200


def _despachar(socio: Socio, canal: CanalDePrueba) -> None:
    with socio.motor.connect() as conn:
        despachar_pendientes(NotificacionesSql(conn), canal, socio.usuario_id)


def test_un_aviso_varado_en_enviando_se_vuelve_a_mandar(socio: Socio, canal: CanalDePrueba) -> None:
    """un aviso que quedó enviando por una caída se vuelve a enviar @REV-03-S5 @assumption:REV-03-ASM-04"""
    _cancelar(socio, "20:00")
    _varar(socio, "10 minutes")
    canal.enviados.clear()

    _despachar(socio, canal)

    assert _envios(socio) == ["enviada"]
    assert len(canal.enviados) == 1


class _CanalQueSeCae(CanalDePrueba):
    """El proceso muere justo después de tomar el aviso, antes de saber si salió."""

    def enviar(self, tokens: list[str], aviso: Any) -> Any:
        raise SystemExit("el proceso se cayó")


def test_un_aviso_que_quedo_a_medio_mandar_lo_retoma_el_despacho_siguiente(
    socio: Socio, canal: CanalDePrueba
) -> None:
    """un aviso que quedó enviando por una caída real se vuelve a enviar
    @REV-03-S5 @assumption:REV-03-ASM-04
    """
    _cancelar(socio, "20:00")
    with socio.motor.begin() as conn:
        conn.execute(
            text(
                "UPDATE notificacion SET envio = 'pendiente', enviada_en = NULL WHERE usuario_id = :u"
            ),
            {"u": socio.usuario_id},
        )
    with pytest.raises(SystemExit):
        _despachar(socio, _CanalQueSeCae())
    with socio.motor.begin() as conn:
        conn.execute(
            text(
                "UPDATE notificacion SET tomada_en = tomada_en - interval '10 minutes'"
                " WHERE usuario_id = :u"
            ),
            {"u": socio.usuario_id},
        )
    canal.enviados.clear()

    _despachar(socio, canal)

    assert _envios(socio) == ["enviada"]
    assert len(canal.enviados) == 1


def test_un_aviso_que_se_esta_mandando_no_se_toma_dos_veces(
    socio: Socio, canal: CanalDePrueba
) -> None:
    """un aviso tomado hace un momento no se vuelve a tomar @REV-03-S5 @assumption:REV-03-ASM-04"""
    _cancelar(socio, "20:00")
    _varar(socio, "1 minute")
    canal.enviados.clear()

    _despachar(socio, canal)

    assert _envios(socio) == ["enviando"]
    assert canal.enviados == []


def test_un_aviso_que_ya_se_intento_tres_veces_queda_fallido(
    socio: Socio, canal: CanalDePrueba
) -> None:
    """el aviso que agotó sus intentos queda fallido @REV-03-S5 @assumption:REV-03-ASM-05"""
    _cancelar(socio, "20:00")
    _varar(socio, "10 minutes", intentos=3)
    canal.enviados.clear()

    _despachar(socio, canal)

    assert _envios(socio) == ["fallida"]
    assert canal.enviados == []


def _recordatorio(socio: Socio, envio: str, hace: str) -> None:
    reserva: dict[str, Any] = socio.reservar("20:00")
    with socio.motor.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, reserva_id,"
                " reserva_inicio, envio, creada_en, tomada_en, intentos)"
                " SELECT :u, 'recordatorio', 'Tu turno es en una hora', 'Fútbol 5 en la sede',"
                " id, inicio, :envio, now() - CAST(:hace AS interval),"
                " CASE WHEN :envio = 'enviando' THEN now() - CAST(:hace AS interval) END,"
                " CASE WHEN :envio = 'enviando' THEN 1 ELSE 0 END"
                " FROM reserva WHERE id = :r"
            ),
            {"u": socio.usuario_id, "r": reserva["id"], "envio": envio, "hace": hace},
        )


def _barrer(socio: Socio, canal: CanalDePrueba) -> None:
    with socio.motor.connect() as conn:
        despachar_pendientes(NotificacionesSql(conn), canal, socio.usuario_id)
        enviar_recordatorios(NotificacionesSql(conn), canal, a_las(19, 10), socio.usuario_id)


def test_un_recordatorio_registrado_y_no_enviado_se_reintenta(
    socio: Socio, canal: CanalDePrueba
) -> None:
    """un recordatorio registrado y no enviado se reintenta @REV-03-S6"""
    _recordatorio(socio, "pendiente", "10 minutes")
    canal.enviados.clear()

    _barrer(socio, canal)

    assert _envios(socio) == ["enviada"]
    assert len(canal.enviados) == 1


def test_un_recordatorio_pendiente_de_una_reserva_cancelada_no_sale(
    socio: Socio, canal: CanalDePrueba
) -> None:
    """el recordatorio pendiente de una reserva ya cancelada no se manda @REV-03-S6"""
    _recordatorio(socio, "pendiente", "10 minutes")
    reserva = socio.reservas[-1]
    r = socio.api.post(f"/reservas/{reserva['id']}/cancelar", headers=socio.sesion)
    assert r.status_code == 200
    canal.enviados.clear()

    _barrer(socio, canal)

    assert canal.enviados == []


def test_un_recordatorio_varado_en_enviando_no_se_repite(
    socio: Socio, canal: CanalDePrueba
) -> None:
    """el recordatorio varado queda fallido: se envía una sola vez @REV-03-S6 @assumption:REV-03-ASM-02"""
    _recordatorio(socio, "enviando", "10 minutes")
    canal.enviados.clear()

    _barrer(socio, canal)

    assert _envios(socio) == ["fallida"]
    assert canal.enviados == []


@pytest.fixture
def base_de_migraciones(motor: Engine) -> Iterator[tuple[Engine, AlembicConfig]]:
    """Una base aparte, vacía, para subir y bajar migraciones sin tocar la de la suite."""
    admin = create_engine(URL_PRUEBAS.rsplit("/", 1)[0] + "/postgres", isolation_level="AUTOCOMMIT")
    with admin.connect() as conn:
        conn.execute(text("DROP DATABASE IF EXISTS club_rev03_migraciones_test WITH (FORCE)"))
        conn.execute(text("CREATE DATABASE club_rev03_migraciones_test"))
    admin.dispose()
    base = create_engine(URL_MIGRACIONES)
    alembic = AlembicConfig(str(RAIZ_API / "alembic.ini"))
    alembic.set_main_option("sqlalchemy.url", URL_MIGRACIONES.replace("%", "%%"))
    yield base, alembic
    base.dispose()


def _sembrar(base: Engine) -> None:
    with base.begin() as conn:
        conn.execute(
            text(
                "WITH u AS (INSERT INTO usuario (firebase_uid, correo, nombre, apellido, dni,"
                " fecha_nacimiento) VALUES ('uid-ana', 'ana@correo.com', 'Ana', 'Rios',"
                " '30111222', '1990-01-01') RETURNING id),"
                " s AS (INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
                " VALUES ('Sede Haedo', 'Av. Vergara', 1850, '08:00', '23:00',"
                " ARRAY[1,2,3,4,5,6,7]) RETURNING id),"
                " e AS (INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada,"
                " iluminada, precio_por_hora) SELECT id, 'Futbol', 'F5', 1,"
                " 'Haedo_Vergara_1850_Futbol_F5_1', false, true, 38000 FROM s RETURNING id)"
                " INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
                " SELECT u.id, e.id, h, h + interval '1 hour', 38000, 38000 FROM u, e,"
                " (SELECT date_trunc('hour', now(), 'America/Argentina/Buenos_Aires')"
                " + interval '1 day' AS h) AS t"
            )
        )


def _reservas(base: Engine) -> int:
    with base.connect() as conn:
        return int(conn.execute(text("SELECT count(*) FROM reserva")).scalar_one())


def test_la_migracion_nueva_no_se_queda_esperando_un_bloqueo(
    base_de_migraciones: tuple[Engine, AlembicConfig],
) -> None:
    """la migración nueva no bloquea las tablas mientras la versión anterior atiende @REV-03-S7"""
    base, alembic = base_de_migraciones
    command.upgrade(alembic, "0007")
    _sembrar(base)
    bloqueo = base.connect()
    bloqueo.execute(text("LOCK TABLE reserva IN ACCESS EXCLUSIVE MODE"))
    resultado: list[BaseException] = []
    hilo = threading.Thread(
        target=lambda: _capturar(resultado, lambda: command.upgrade(alembic, "0008"))
    )

    hilo.start()
    hilo.join(timeout=60)
    bloqueo.rollback()
    bloqueo.close()

    assert not hilo.is_alive()
    assert isinstance(resultado[0], OperationalError)
    assert "lock timeout" in str(resultado[0])
    command.upgrade(alembic, "0008")
    with base.connect() as conn:
        invalidos = conn.execute(
            text("SELECT count(*) FROM pg_index WHERE NOT indisvalid")
        ).scalar_one()
    assert invalidos == 0
    assert _reservas(base) == 1


def _capturar(resultado: list[BaseException], accion: Callable[[], None]) -> None:
    try:
        accion()
    except BaseException as e:  # noqa: BLE001 — el test afirma sobre el error que se guarda
        resultado.append(e)


def _esquema(base: Engine) -> set[tuple[str, ...]]:
    with base.connect() as conn:
        columnas = conn.execute(
            text(
                "SELECT table_name, column_name, data_type, is_nullable"
                " FROM information_schema.columns WHERE table_schema = 'public'"
            )
        )
        indices = conn.execute(
            text("SELECT tablename, indexdef, '', '' FROM pg_indexes WHERE schemaname = 'public'")
        )
        return {tuple(str(c) for c in f) for f in [*columnas, *indices]}


@pytest.mark.parametrize(
    ("anterior", "revision"), list(zip(["0001", *REVISIONES], REVISIONES, strict=False))
)
def test_cada_migracion_va_y_vuelve_con_datos(
    base_de_migraciones: tuple[Engine, AlembicConfig], anterior: str, revision: str
) -> None:
    """la suite vigila la ida y vuelta de las migraciones con datos
    @REV-03-S8 @assumption:REV-03-ASM-06
    """
    base, alembic = base_de_migraciones
    command.upgrade(alembic, "0001")
    _sembrar(base)
    command.upgrade(alembic, anterior)
    antes = _esquema(base)

    command.upgrade(alembic, revision)
    despues = _esquema(base)
    command.downgrade(alembic, "-1")
    vuelta = _esquema(base)
    command.upgrade(alembic, revision)

    assert vuelta == antes
    assert _esquema(base) == despues
    assert _reservas(base) == 1
