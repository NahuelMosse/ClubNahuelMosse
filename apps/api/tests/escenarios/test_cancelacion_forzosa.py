from collections.abc import Callable, Iterator, Sequence
from typing import Any
from uuid import UUID

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_recordatorio import CanalDePrueba, Socio, app_de, manana, un_socio

from app.modules.notifications.use_cases import dispatch_pending
from app.modules.notifications.repository import NotificationsSql, enqueue_forced_cancellation
from app.modules.notifications.push import push_channel
from app.modules.usuarios.sembrar_admin import main as sembrar

DIAS = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]
CONTRASENA = "ClubNahuel1"
MOTIVO = "mantenimiento de la cancha"
TITULO = "El club anuló tu reserva"


class CanalQueFalla:
    def send(self, tokens: Sequence[str], aviso: Any) -> Any:
        raise ConnectionError("el servicio no contesta")


@pytest.fixture
def canal(api: TestClient) -> Iterator[CanalDePrueba]:
    """El servicio de notificaciones del teléfono, que anota lo que la API le pide enviar."""
    canal = CanalDePrueba()
    app_de(api).dependency_overrides[push_channel] = lambda: canal
    yield canal
    app_de(api).dependency_overrides.pop(push_channel, None)


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


def anular(
    socio: Socio, admin: dict[str, str], reserva: dict[str, Any], motivo: str = MOTIVO
) -> int:
    r = socio.api.post(
        f"/reservas/{reserva['id']}/anular",
        headers=admin,
        json={"motivo": motivo, "espacio_id": reserva["espacio_id"], "inicio": reserva["inicio"]},
    )
    return r.status_code


def cuerpo_esperado(sede: str, hora: str, motivo: str = MOTIVO) -> str:
    dia = manana()
    return f"Fútbol 5 · {sede} · {DIAS[dia.weekday()]} {dia.day}, {hora}. Motivo: {motivo}."


def para_el_admin(socio: Socio, admin: dict[str, str], reserva_id: str) -> dict[str, Any]:
    """La reserva como la ve el administrador en el historial global."""
    r = socio.api.get(f"/reservas/todas?q={socio.sede}", headers=admin)
    assert r.status_code == 200
    [reserva] = [x for x in r.json()["reservas"] if x["id"] == reserva_id]
    assert isinstance(reserva, dict)
    return reserva


def test_al_anular_una_reserva_el_usuario_recibe_el_aviso_con_deporte_sede_fecha_y_motivo(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    admin: dict[str, str],
) -> None:
    """el administrador anula una reserva y el usuario recibe el aviso con deporte, sede, fecha y motivo @CU-24.2-H01-01 @supuesto:CU-24.2-SUP-06"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")
    assert canal.enviados == []

    assert anular(socio, admin, reserva) == 200

    # Verifica: sale un solo aviso, al dispositivo del socio, con lo que dice el CU.
    assert len(canal.enviados) == 1
    tokens, aviso = canal.enviados[0]
    assert tokens == [socio.dispositivo]
    assert aviso.title == TITULO
    assert aviso.body == cuerpo_esperado(socio.sede, "21:00")

    # Verifica: queda también en el centro, sin leer.
    centro = socio.centro()
    assert centro["no_leidas"] == 1
    [entrada] = centro["notificaciones"]
    assert (entrada["tipo"], entrada["titulo"], entrada["cuerpo"]) == (
        "cancelacion_forzosa",
        aviso.title,
        aviso.body,
    )


def test_al_tocar_el_aviso_la_app_sabe_que_reserva_abrir_y_el_historial_la_trae_anulada(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    admin: dict[str, str],
) -> None:
    """al tocar el aviso la app abre el historial con la reserva anulada y su motivo @CU-24.2-H01-02"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")
    assert anular(socio, admin, reserva) == 200

    # Verifica: el push y el centro llevan el tipo y el número de la reserva.
    [(_, aviso)] = canal.enviados
    assert aviso.data == {"tipo": "cancelacion_forzosa", "reserva_id": str(reserva["id"])}
    [entrada] = socio.centro()["notificaciones"]
    assert entrada["reserva_id"] == reserva["id"]

    # Verifica: el historial de esa persona la lista como anulada y con el motivo.
    historial = socio.api.get("/reservas?cuando=historial", headers=socio.sesion).json()
    assert [(r["id"], r["estado"], r["motivo"]) for r in historial["reservas"]] == [
        (reserva["id"], "anulada", MOTIVO)
    ]


def test_el_envio_del_aviso_consta_en_la_trazabilidad_de_la_reserva(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    admin: dict[str, str],
) -> None:
    """el envío del aviso queda en la trazabilidad de la reserva @CU-24.2-H01-03 @supuesto:CU-24.2-SUP-07"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")
    assert para_el_admin(socio, admin, reserva["id"])["aviso_envio"] is None

    assert anular(socio, admin, reserva) == 200

    # Verifica: el administrador ve que se envió, y cuándo.
    detalle = para_el_admin(socio, admin, reserva["id"])
    assert detalle["aviso_envio"] == "enviada"
    assert detalle["aviso_en"] is not None


def test_una_baja_que_afecta_a_varios_usuarios_manda_un_aviso_a_cada_uno_con_su_reserva(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
) -> None:
    """una baja que afecta a varios usuarios manda un aviso a cada uno con su propia reserva @CU-24.2-H02-01 @supuesto:CU-24.2-SUP-03"""
    uno = un_socio(api, motor, iniciar_sesion, unico)
    otro = un_socio(api, motor, iniciar_sesion, unico)
    de_uno = uno.reservar("20:00")
    de_otro = otro.reservar("21:00")

    # La baja cancela las reservas y encola, en la misma transacción, el aviso de cada persona.
    with motor.begin() as conn:
        for socio, reserva in ((uno, de_uno), (otro, de_otro)):
            conn.execute(
                text(
                    "UPDATE reserva SET estado = 'anulada', motivo = 'Baja de la sede',"
                    " cancelada_en = now(), cancelada_por = :u WHERE id = :id"
                ),
                {"u": socio.usuario_id, "id": reserva["id"]},
            )
            enqueue_forced_cancellation(conn, socio.usuario_id, [UUID(reserva["id"])])
    with motor.connect() as conn:
        for socio in (uno, otro):
            dispatch_pending(NotificationsSql(conn), canal, socio.usuario_id)

    # Verifica: cada persona recibe un solo aviso, con los datos de su propia reserva.
    assert [(t, a.body) for t, a in canal.enviados] == [
        ([uno.dispositivo], cuerpo_esperado(uno.sede, "20:00", "Baja de la sede")),
        ([otro.dispositivo], cuerpo_esperado(otro.sede, "21:00", "Baja de la sede")),
    ]
    assert [e["titulo"] for e in uno.centro()["notificaciones"]] == [TITULO]
    assert [e["titulo"] for e in otro.centro()["notificaciones"]] == [TITULO]


def test_varias_reservas_anuladas_a_la_misma_persona_llegan_en_un_solo_aviso_con_la_cantidad(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    admin: dict[str, str],
) -> None:
    """un usuario con varias reservas afectadas recibe un solo aviso con la cantidad @CU-24.2-H03-01 @supuesto:CU-24.2-SUP-02 @supuesto:CU-24.2-SUP-04 @supuesto:CU-24.2-SUP-06"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    primera = socio.reservar("20:00")
    segunda = socio.reservar("21:00")

    assert anular(socio, admin, primera) == 200
    assert anular(socio, admin, segunda) == 200

    # Verifica: el centro trae un solo aviso, sin leer, que dice cuántas son y no apunta a una.
    centro = socio.centro()
    assert centro["no_leidas"] == 1
    [entrada] = centro["notificaciones"]
    assert entrada["titulo"] == "El club anuló 2 de tus reservas"
    assert (
        entrada["cuerpo"]
        == "Tenés 2 reservas anuladas por el club. Mirá el detalle en tu historial."
    )
    assert entrada["reserva_id"] is None

    # Verifica: el último push dice lo mismo y lleva a Mis reservas sin una reserva puntual.
    _, aviso = canal.enviados[-1]
    assert (aviso.title, aviso.body) == (entrada["titulo"], entrada["cuerpo"])
    assert aviso.data == {"tipo": "cancelacion_forzosa"}

    # Verifica: las dos figuran anuladas en el historial, cada una con su motivo.
    historial = socio.api.get("/reservas?cuando=historial", headers=socio.sesion).json()
    assert sorted((r["id"], r["estado"]) for r in historial["reservas"]) == sorted(
        [(primera["id"], "anulada"), (segunda["id"], "anulada")]
    )

    # Verifica: las dos tienen el envío en su trazabilidad.
    for reserva in (primera, segunda):
        assert para_el_admin(socio, admin, reserva["id"])["aviso_envio"] == "enviada"


def test_una_anulacion_despues_de_leer_el_aviso_abre_uno_nuevo(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    admin: dict[str, str],
) -> None:
    """una anulación después de leer el aviso abre uno nuevo @supuesto:CU-24.2-SUP-02"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    primera = socio.reservar("20:00")
    segunda = socio.reservar("21:00")
    assert anular(socio, admin, primera) == 200
    [leida] = socio.centro()["notificaciones"]
    assert api.post(f"/notificaciones/{leida['id']}/leer", headers=socio.sesion).status_code == 204

    assert anular(socio, admin, segunda) == 200

    centro = socio.centro()
    assert centro["no_leidas"] == 1
    assert [e["titulo"] for e in centro["notificaciones"]] == [TITULO, TITULO]
    assert [e["leida"] for e in centro["notificaciones"]] == [False, True]


def test_sin_permiso_de_notificaciones_no_llega_el_push_pero_el_aviso_esta_en_el_centro(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    admin: dict[str, str],
) -> None:
    """sin permiso de notificaciones no llega el push pero el aviso está en el centro @CU-24.2-H04-01 @supuesto:CU-24.2-SUP-07"""
    socio = un_socio(api, motor, iniciar_sesion, unico, permiso=False)
    reserva = socio.reservar("21:00")

    assert anular(socio, admin, reserva) == 200

    # Verifica: nada sale hacia el teléfono, el aviso está en el centro y el administrador ve
    # que el push no salió.
    assert canal.enviados == []
    [entrada] = socio.centro()["notificaciones"]
    assert entrada["titulo"] == TITULO
    assert para_el_admin(socio, admin, reserva["id"])["aviso_envio"] == "sin_permiso"


def test_si_el_usuario_ya_habia_cancelado_la_reserva_no_recibe_aviso(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    admin: dict[str, str],
) -> None:
    """si el usuario ya había cancelado la reserva, no recibe aviso @CU-24.2-H05-01"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")
    cancelada = socio.api.post(f"/reservas/{reserva['id']}/cancelar", headers=socio.sesion)
    assert cancelada.status_code == 200

    assert anular(socio, admin, reserva) == 409

    # Verifica: sólo quedó la confirmación de su propia cancelación.
    assert [a.data["tipo"] for _, a in canal.enviados] == ["cancelacion_usuario"]
    assert [e["tipo"] for e in socio.centro()["notificaciones"]] == ["cancelacion_usuario"]


def test_repetir_la_anulacion_no_repite_el_aviso(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    admin: dict[str, str],
) -> None:
    """repetir la anulación no repite el aviso @supuesto:CU-24.2-SUP-08"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")

    assert anular(socio, admin, reserva) == 200
    assert anular(socio, admin, reserva) == 200

    assert len(canal.enviados) == 1
    assert len(socio.centro()["notificaciones"]) == 1


def test_una_anulacion_que_no_se_completa_no_deja_aviso(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    admin: dict[str, str],
) -> None:
    """una anulación rechazada no deja aviso @supuesto:CU-24.2-SUP-08"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")
    movida = {**reserva, "inicio": "2030-01-01T21:00:00-03:00"}

    assert anular(socio, admin, movida) == 409

    assert canal.enviados == []
    assert socio.centro() == {"notificaciones": [], "no_leidas": 0}


def test_si_el_push_falla_no_se_reintenta_y_el_aviso_queda_en_el_centro(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    admin: dict[str, str],
) -> None:
    """si el push falla el aviso queda en el centro con el envío fallido @supuesto:CU-24.2-SUP-01 @supuesto:CU-24.2-SUP-07"""
    app_de(api).dependency_overrides[push_channel] = lambda: CanalQueFalla()
    try:
        socio = un_socio(api, motor, iniciar_sesion, unico)
        reserva = socio.reservar("21:00")

        assert anular(socio, admin, reserva) == 200

        assert [e["titulo"] for e in socio.centro()["notificaciones"]] == [TITULO]
        assert para_el_admin(socio, admin, reserva["id"])["aviso_envio"] == "fallida"
    finally:
        app_de(api).dependency_overrides.pop(push_channel, None)
