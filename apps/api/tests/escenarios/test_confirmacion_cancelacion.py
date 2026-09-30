from collections.abc import Callable, Iterator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_recordatorio import CanalDePrueba, Socio, manana, un_socio

from app.infraestructura.push import canal_push

DIAS = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]


@pytest.fixture
def canal(api: TestClient) -> Iterator[CanalDePrueba]:
    """El servicio de notificaciones del teléfono, que anota lo que la API le pide enviar."""
    canal = CanalDePrueba()
    api.app.dependency_overrides[canal_push] = lambda: canal
    yield canal
    api.app.dependency_overrides.pop(canal_push, None)


def cancelar(socio: Socio, reserva_id: int) -> int:
    return socio.api.post(f"/reservas/{reserva_id}/cancelar", headers=socio.sesion).status_code


def cuerpo_esperado(sede: str, hora: str) -> str:
    dia = manana()
    return (
        f"Fútbol 5 · {sede} · {DIAS[dia.weekday()]} {dia.day}, {hora}. El horario quedó liberado."
    )


def test_al_cancelar_una_reserva_se_envia_la_confirmacion_con_la_reserva_y_el_horario_liberado(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
) -> None:
    """cancela una reserva y recibe la confirmación con la reserva y el horario liberado @CU-24.3-H01-01"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")

    # Verifica: nada sale antes de cancelar.
    assert canal.enviados == []

    assert cancelar(socio, reserva["id"]) == 200

    # Verifica: sale una sola confirmación, al dispositivo del socio, con lo que dice el CU.
    assert len(canal.enviados) == 1
    tokens, aviso = canal.enviados[0]
    assert tokens == [socio.dispositivo]
    assert aviso.titulo == "Reserva cancelada"
    assert aviso.cuerpo == cuerpo_esperado(socio.sede, "21:00")
    assert aviso.datos["reserva_id"] == str(reserva["id"])
    assert aviso.datos["tipo"] == "cancelacion_usuario"


def test_al_tocar_la_confirmacion_la_app_sabe_que_reserva_abrir(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
) -> None:
    """al tocar la confirmación la app abre el historial con la reserva cancelada @CU-24.3-H01-02"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")
    assert cancelar(socio, reserva["id"]) == 200

    # Verifica: el push y el centro llevan el número de la reserva, que el historial lista
    # como cancelada.
    [(_, aviso)] = canal.enviados
    assert aviso.datos["reserva_id"] == str(reserva["id"])
    [entrada] = socio.centro()["notificaciones"]
    assert entrada["reserva_id"] == reserva["id"]
    historial = socio.api.get("/reservas?cuando=historial", headers=socio.sesion).json()
    assert [(r["id"], r["estado"]) for r in historial["reservas"]] == [(reserva["id"], "cancelada")]


def test_la_confirmacion_queda_en_el_centro_de_notificaciones(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
) -> None:
    """la confirmación queda en el centro de notificaciones @CU-24.3-H01-03"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")
    assert socio.centro() == {"notificaciones": [], "no_leidas": 0}

    assert cancelar(socio, reserva["id"]) == 200

    # Verifica: queda una entrada sin leer, de confirmación, con el texto del CU.
    centro = socio.centro()
    assert centro["no_leidas"] == 1
    [entrada] = centro["notificaciones"]
    assert entrada["tipo"] == "cancelacion_usuario"
    assert entrada["titulo"] == "Reserva cancelada"
    assert entrada["cuerpo"] == cuerpo_esperado(socio.sede, "21:00")
    assert entrada["leida"] is False


def test_sin_permiso_de_notificaciones_no_se_envia_pero_la_confirmacion_queda_en_el_centro(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
) -> None:
    """sin permiso de notificaciones no llega el push pero la confirmación está en el centro @CU-24.3-H03-01"""
    socio = un_socio(api, motor, iniciar_sesion, unico, permiso=False)
    reserva = socio.reservar("21:00")

    assert cancelar(socio, reserva["id"]) == 200

    # Verifica: nada sale hacia el teléfono y la confirmación está en el centro.
    assert canal.enviados == []
    [entrada] = socio.centro()["notificaciones"]
    assert entrada["titulo"] == "Reserva cancelada"


def test_si_la_cancelacion_falla_no_se_confirma_nada(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
) -> None:
    """si la cancelación falló, no recibe ninguna confirmación @CU-24.3-H04-01"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    ajeno = un_socio(api, motor, iniciar_sesion, unico)
    de_otro = ajeno.reservar("21:00")
    anulada = socio.reservar("20:00")
    with motor.begin() as conn:
        conn.execute(
            text(
                "UPDATE reserva SET estado = 'anulada', motivo = 'mantenimiento',"
                " cancelada_en = now(), cancelada_por = :u WHERE id = :id"
            ),
            {"u": socio.usuario_id, "id": anulada["id"]},
        )

    # Verifica: cancelar la de otra persona (404) o una que el club ya anuló (409) falla y
    # no deja confirmación para nadie.
    assert cancelar(socio, de_otro["id"]) == 404
    assert cancelar(socio, anulada["id"]) == 409
    assert canal.enviados == []
    assert socio.centro() == {"notificaciones": [], "no_leidas": 0}
    assert ajeno.centro() == {"notificaciones": [], "no_leidas": 0}
