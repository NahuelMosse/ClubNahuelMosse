"""El agrupado de avisos de anulación: trazabilidad por reserva, id nuevo y concurrencia."""

import threading
import time
from collections.abc import Callable, Sequence
from typing import Any

import pytest
import test_cancelacion_forzosa as base
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_recordatorio import CanalDePrueba, Socio, un_socio

from app.modules.notificaciones.repositorio import NotificacionesSql, encolar_cancelacion_forzosa

admin = base.admin
canal = base.canal


def _anular_en_la_base(motor: Engine, socio: Socio, reservas: Sequence[dict[str, Any]]) -> None:
    with motor.begin() as conn:
        for r in reservas:
            conn.execute(
                text(
                    "UPDATE reserva SET estado = 'anulada', motivo = 'Baja de la sede',"
                    " cancelada_en = now(), cancelada_por = :u WHERE id = :id"
                ),
                {"u": socio.usuario_id, "id": r["id"]},
            )


def _avisos(motor: Engine, socio: Socio) -> list[Any]:
    with motor.connect() as conn:
        return list(
            conn.execute(
                text(
                    "SELECT id, titulo, cantidad, reemplazada_por, envio, enviada_en"
                    " FROM notificacion WHERE usuario_id = :u ORDER BY id"
                ),
                {"u": socio.usuario_id},
            )
        )


def _en_paralelo(motor: Engine, usuario_id: int, lotes: Sequence[Sequence[int]]) -> None:
    """Encola el primer lote y, con su transacción todavía abierta, el segundo, que tiene que
    quedar esperando a que la primera termine."""
    primera_dentro, soltar = threading.Event(), threading.Event()
    errores: list[BaseException] = []

    def primera() -> None:
        try:
            with motor.begin() as conn:
                encolar_cancelacion_forzosa(conn, usuario_id, lotes[0])
                primera_dentro.set()
                soltar.wait(10)
        except BaseException as e:
            errores.append(e)
            primera_dentro.set()

    def segunda() -> None:
        try:
            primera_dentro.wait(10)
            with motor.begin() as conn:
                encolar_cancelacion_forzosa(conn, usuario_id, lotes[1])
        except BaseException as e:
            errores.append(e)

    hilos = [threading.Thread(target=primera), threading.Thread(target=segunda)]
    for h in hilos:
        h.start()
    primera_dentro.wait(10)
    time.sleep(0.5)
    esperando = hilos[1].is_alive()
    soltar.set()
    for h in hilos:
        h.join(10)
    assert errores == []
    assert esperando, "la segunda anulación no esperó a la primera"


def test_agrupar_abre_un_aviso_nuevo_y_cada_reserva_conserva_el_envio_del_suyo(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    admin: dict[str, str],
) -> None:
    """el aviso agrupado tiene id nuevo y la trazabilidad de cada reserva no cambia @supuesto:CU-24.2-SUP-02"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    primera = socio.reservar("20:00")
    segunda = socio.reservar("21:00")
    assert base.anular(socio, admin, primera) == 200
    [antes] = socio.centro()["notificaciones"]
    trazabilidad = base.para_el_admin(socio, admin, primera["id"])

    assert base.anular(socio, admin, segunda) == 200

    [despues] = socio.centro()["notificaciones"]
    assert despues["id"] != antes["id"]
    assert despues["titulo"] == "El club anuló 2 de tus reservas"
    assert base.para_el_admin(socio, admin, primera["id"])["aviso_en"] == trazabilidad["aviso_en"]
    assert base.para_el_admin(socio, admin, segunda["id"])["aviso_envio"] == "enviada"
    anterior, nuevo = _avisos(motor, socio)
    assert anterior.reemplazada_por == nuevo.id
    assert anterior.enviada_en < nuevo.enviada_en


def test_un_aviso_que_no_salio_pasa_sus_reservas_al_que_lo_reemplaza(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
) -> None:
    """lo que se agrupa antes de salir se informa en el aviso que sale @supuesto:CU-24.2-SUP-02"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reservas = [socio.reservar("20:00"), socio.reservar("21:00")]
    _anular_en_la_base(motor, socio, reservas)
    with motor.begin() as conn:
        encolar_cancelacion_forzosa(conn, socio.usuario_id, [reservas[0]["id"]])
    with motor.begin() as conn:
        encolar_cancelacion_forzosa(conn, socio.usuario_id, [reservas[1]["id"]])

    with motor.connect() as conn:
        vinculos = conn.execute(
            text("SELECT notificacion_id FROM notificacion_reserva WHERE reserva_id = ANY(:ids)"),
            {"ids": [r["id"] for r in reservas]},
        ).all()
    *_, nuevo = _avisos(motor, socio)
    assert {v.notificacion_id for v in vinculos} == {nuevo.id}


@pytest.mark.parametrize("con_aviso_previo", [False, True])
def test_dos_anulaciones_simultaneas_dejan_la_cantidad_y_un_solo_aviso_visible(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    admin: dict[str, str],
    con_aviso_previo: bool,
) -> None:
    """las anulaciones de una misma persona se serializan @supuesto:CU-24.2-SUP-02"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reservas = [socio.reservar("20:00"), socio.reservar("21:00"), socio.reservar("22:00")]
    if con_aviso_previo:
        assert base.anular(socio, admin, reservas[0]) == 200
        simultaneas = reservas[1:]
    else:
        simultaneas = reservas[:2]
        _anular_en_la_base(motor, socio, simultaneas)
    total = len(simultaneas) + int(con_aviso_previo)
    if con_aviso_previo:
        _anular_en_la_base(motor, socio, simultaneas)

    _en_paralelo(motor, socio.usuario_id, [[simultaneas[0]["id"]], [simultaneas[1]["id"]]])

    [visible] = socio.centro()["notificaciones"]
    assert visible["titulo"] == f"El club anuló {total} de tus reservas"
    sin_reemplazar = [a for a in _avisos(motor, socio) if a.reemplazada_por is None]
    assert [a.cantidad for a in sin_reemplazar] == [total]
    with motor.connect() as conn:
        vinculadas: Any = conn.execute(
            text(
                "SELECT count(*) FROM notificacion_reserva nr JOIN notificacion n"
                " ON n.id = nr.notificacion_id WHERE n.usuario_id = :u"
            ),
            {"u": socio.usuario_id},
        ).scalar_one()
    assert vinculadas == total


def test_un_aviso_leido_mientras_se_agrupa_no_se_traga_la_anulacion_nueva(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    admin: dict[str, str],
) -> None:
    """leer el aviso anterior en medio del agrupado deja el nuevo sin leer @supuesto:CU-24.2-SUP-02"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    primera = socio.reservar("20:00")
    segunda = socio.reservar("21:00")
    assert base.anular(socio, admin, primera) == 200
    [leido] = socio.centro()["notificaciones"]
    _anular_en_la_base(motor, socio, [segunda])

    def leyendo() -> None:
        with motor.connect() as conn:
            NotificacionesSql(conn).leer(socio.usuario_id, leido["id"])

    lectura = threading.Thread(target=leyendo)

    primera_dentro, soltar = threading.Event(), threading.Event()

    def encolando() -> None:
        with motor.begin() as conn:
            encolar_cancelacion_forzosa(conn, socio.usuario_id, [segunda["id"]])
            primera_dentro.set()
            soltar.wait(10)

    hilo = threading.Thread(target=encolando)
    hilo.start()
    primera_dentro.wait(10)
    lectura.start()
    time.sleep(0.5)
    soltar.set()
    hilo.join(10)
    lectura.join(10)

    centro = socio.centro()
    assert centro["no_leidas"] == 1
    [entrada] = centro["notificaciones"]
    assert entrada["titulo"] == "El club anuló 2 de tus reservas"
    assert entrada["leida"] is False


def test_el_despacho_toma_los_pendientes_por_un_indice_parcial(motor: Engine) -> None:
    """la consulta del despacho tiene su índice"""
    with motor.connect() as conn:
        definicion: Any = conn.execute(
            text("SELECT indexdef FROM pg_indexes WHERE indexname = 'notificacion_por_despachar'")
        ).scalar_one()
    assert "envio = 'pendiente'" in definicion
    assert "tipo <> 'recordatorio'" in definicion
