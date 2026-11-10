from collections.abc import Callable, Iterator, Sequence
from typing import Any
from uuid import UUID

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_reminder import FakeChannel, Member, app_of, tomorrow, a_member

from app.modules.notifications.use_cases import dispatch_pending
from app.modules.notifications.repository import NotificationsSql, enqueue_forced_cancellation
from app.modules.notifications.push import push_channel
from app.modules.users.seed_admin import main as sembrar

DIAS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
CONTRASENA = "ClubNahuel1"
MOTIVO = "mantenimiento de la cancha"
TITULO = "The club voided your booking"


class CanalQueFalla:
    def send(self, tokens: Sequence[str], aviso: Any) -> Any:
        raise ConnectionError("el servicio no contesta")


@pytest.fixture
def channel(api: TestClient) -> Iterator[FakeChannel]:
    """El servicio de notificaciones del teléfono, que anota lo que la API le pide enviar."""
    channel = FakeChannel()
    app_of(api).dependency_overrides[push_channel] = lambda: channel
    yield channel
    app_of(api).dependency_overrides.pop(push_channel, None)


@pytest.fixture
def admin(
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> dict[str, str]:
    s = unique()
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    argumentos = [
        "--correo", f"admin.{s}@club.com", "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert sembrar(argumentos) == 0
    token = sign_in(f"admin.{s}@club.com", CONTRASENA)
    assert token is not None
    return {"Authorization": f"Bearer {token}"}


def force_cancel(
    socio: Member, admin: dict[str, str], reserva: dict[str, Any], motivo: str = MOTIVO
) -> int:
    r = socio.api.post(
        f"/bookings/{reserva['id']}/void",
        headers=admin,
        json={"reason": motivo, "space_id": reserva["space_id"], "starts_at": reserva["starts_at"]},
    )
    return r.status_code


def cuerpo_esperado(venue: str, hora: str, motivo: str = MOTIVO) -> str:
    dia = tomorrow()
    return f"Football 5 · {venue} · {DIAS[dia.weekday()]} {dia.day}, {hora}. Reason: {motivo}."


def for_admin(socio: Member, admin: dict[str, str], reserva_id: str) -> dict[str, Any]:
    """La reserva como la ve el administrador en el historial global."""
    r = socio.api.get(f"/bookings/all?q={socio.venue}", headers=admin)
    assert r.status_code == 200
    [reserva] = [x for x in r.json()["bookings"] if x["id"] == reserva_id]
    assert isinstance(reserva, dict)
    return reserva


def test_al_anular_una_reserva_el_usuario_recibe_el_aviso_con_deporte_sede_fecha_y_motivo(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """el administrador anula una reserva y el usuario recibe el aviso con deporte, sede, fecha y motivo @CU-24.2-H01-01 @supuesto:CU-24.2-SUP-06"""
    socio = a_member(api, engine, sign_in, unique)
    reserva = socio.book("21:00")
    assert channel.sent == []

    assert force_cancel(socio, admin, reserva) == 200

    # Verifica: sale un solo aviso, al dispositivo del socio, con lo que dice el CU.
    assert len(channel.sent) == 1
    tokens, aviso = channel.sent[0]
    assert tokens == [socio.device]
    assert aviso.title == TITULO
    assert aviso.body == cuerpo_esperado(socio.venue, "21:00")

    # Verifica: queda también en el centro, sin leer.
    center = socio.center()
    assert center["unread"] == 1
    [entrada] = center["notifications"]
    assert (entrada["kind"], entrada["title"], entrada["body"]) == (
        "forced_cancellation",
        aviso.title,
        aviso.body,
    )


def test_al_tocar_el_aviso_la_app_sabe_que_reserva_abrir_y_el_historial_la_trae_anulada(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """al tocar el aviso la app abre el historial con la reserva anulada y su motivo @CU-24.2-H01-02"""
    socio = a_member(api, engine, sign_in, unique)
    reserva = socio.book("21:00")
    assert force_cancel(socio, admin, reserva) == 200

    # Verifica: el push y el centro llevan el tipo y el número de la reserva.
    [(_, aviso)] = channel.sent
    assert aviso.data == {"kind": "forced_cancellation", "booking_id": str(reserva["id"])}
    [entrada] = socio.center()["notifications"]
    assert entrada["booking_id"] == reserva["id"]

    # Verifica: el historial de esa persona la lista como anulada y con el motivo.
    historial = socio.api.get("/bookings?when=history", headers=socio.session).json()
    assert [(r["id"], r["status"], r["reason"]) for r in historial["bookings"]] == [
        (reserva["id"], "voided", MOTIVO)
    ]


def test_el_envio_del_aviso_consta_en_la_trazabilidad_de_la_reserva(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """el envío del aviso queda en la trazabilidad de la reserva @CU-24.2-H01-03 @supuesto:CU-24.2-SUP-07"""
    socio = a_member(api, engine, sign_in, unique)
    reserva = socio.book("21:00")
    assert for_admin(socio, admin, reserva["id"])["notice_delivery"] is None

    assert force_cancel(socio, admin, reserva) == 200

    # Verifica: el administrador ve que se envió, y cuándo.
    detalle = for_admin(socio, admin, reserva["id"])
    assert detalle["notice_delivery"] == "sent"
    assert detalle["notice_at"] is not None


def test_una_baja_que_afecta_a_varios_usuarios_manda_un_aviso_a_cada_uno_con_su_reserva(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
) -> None:
    """una baja que afecta a varios usuarios manda un aviso a cada uno con su propia reserva @CU-24.2-H02-01 @supuesto:CU-24.2-SUP-03"""
    uno = a_member(api, engine, sign_in, unique)
    otro = a_member(api, engine, sign_in, unique)
    de_uno = uno.book("20:00")
    de_otro = otro.book("21:00")

    # La baja cancela las reservas y encola, en la misma transacción, el aviso de cada persona.
    with engine.begin() as conn:
        for socio, reserva in ((uno, de_uno), (otro, de_otro)):
            conn.execute(
                text(
                    "UPDATE booking SET status = 'voided', reason = 'Baja de la sede',"
                    " canceled_at = now(), canceled_by = :u WHERE id = :id"
                ),
                {"u": socio.user_id, "id": reserva["id"]},
            )
            enqueue_forced_cancellation(conn, socio.user_id, [UUID(reserva["id"])])
    with engine.connect() as conn:
        for socio in (uno, otro):
            dispatch_pending(NotificationsSql(conn), channel, socio.user_id)

    # Verifica: cada persona recibe un solo aviso, con los datos de su propia reserva.
    assert [(t, a.body) for t, a in channel.sent] == [
        ([uno.device], cuerpo_esperado(uno.venue, "20:00", "Baja de la sede")),
        ([otro.device], cuerpo_esperado(otro.venue, "21:00", "Baja de la sede")),
    ]
    assert [e["title"] for e in uno.center()["notifications"]] == [TITULO]
    assert [e["title"] for e in otro.center()["notifications"]] == [TITULO]


def test_varias_reservas_anuladas_a_la_misma_persona_llegan_en_un_solo_aviso_con_la_cantidad(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """un usuario con varias reservas afectadas recibe un solo aviso con la cantidad @CU-24.2-H03-01 @supuesto:CU-24.2-SUP-02 @supuesto:CU-24.2-SUP-04 @supuesto:CU-24.2-SUP-06"""
    socio = a_member(api, engine, sign_in, unique)
    primera = socio.book("20:00")
    segunda = socio.book("21:00")

    assert force_cancel(socio, admin, primera) == 200
    assert force_cancel(socio, admin, segunda) == 200

    # Verifica: el centro trae un solo aviso, sin leer, que dice cuántas son y no apunta a una.
    center = socio.center()
    assert center["unread"] == 1
    [entrada] = center["notifications"]
    assert entrada["title"] == "The club voided 2 of your bookings"
    assert (
        entrada["body"]
        == "You have 2 bookings voided by the club. See the detail in your history."
    )
    assert entrada["booking_id"] is None

    # Verifica: el último push dice lo mismo y lleva a Mis reservas sin una reserva puntual.
    _, aviso = channel.sent[-1]
    assert (aviso.title, aviso.body) == (entrada["title"], entrada["body"])
    assert aviso.data == {"kind": "forced_cancellation"}

    # Verifica: las dos figuran anuladas en el historial, cada una con su motivo.
    historial = socio.api.get("/bookings?when=history", headers=socio.session).json()
    assert sorted((r["id"], r["status"]) for r in historial["bookings"]) == sorted(
        [(primera["id"], "voided"), (segunda["id"], "voided")]
    )

    # Verifica: las dos tienen el envío en su trazabilidad.
    for reserva in (primera, segunda):
        assert for_admin(socio, admin, reserva["id"])["notice_delivery"] == "sent"


def test_una_anulacion_despues_de_leer_el_aviso_abre_uno_nuevo(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """una anulación después de leer el aviso abre uno nuevo @supuesto:CU-24.2-SUP-02"""
    socio = a_member(api, engine, sign_in, unique)
    primera = socio.book("20:00")
    segunda = socio.book("21:00")
    assert force_cancel(socio, admin, primera) == 200
    [leida] = socio.center()["notifications"]
    assert api.post(f"/notifications/{leida['id']}/read", headers=socio.session).status_code == 204

    assert force_cancel(socio, admin, segunda) == 200

    center = socio.center()
    assert center["unread"] == 1
    assert [e["title"] for e in center["notifications"]] == [TITULO, TITULO]
    assert [e["read"] for e in center["notifications"]] == [False, True]


def test_sin_permiso_de_notificaciones_no_llega_el_push_pero_el_aviso_esta_en_el_centro(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """sin permiso de notificaciones no llega el push pero el aviso está en el centro @CU-24.2-H04-01 @supuesto:CU-24.2-SUP-07"""
    socio = a_member(api, engine, sign_in, unique, permission=False)
    reserva = socio.book("21:00")

    assert force_cancel(socio, admin, reserva) == 200

    # Verifica: nada sale hacia el teléfono, el aviso está en el centro y el administrador ve
    # que el push no salió.
    assert channel.sent == []
    [entrada] = socio.center()["notifications"]
    assert entrada["title"] == TITULO
    assert for_admin(socio, admin, reserva["id"])["notice_delivery"] == "no_permission"


def test_si_el_usuario_ya_habia_cancelado_la_reserva_no_recibe_aviso(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """si el usuario ya había cancelado la reserva, no recibe aviso @CU-24.2-H05-01"""
    socio = a_member(api, engine, sign_in, unique)
    reserva = socio.book("21:00")
    cancelada = socio.api.post(f"/bookings/{reserva['id']}/cancel", headers=socio.session)
    assert cancelada.status_code == 200

    assert force_cancel(socio, admin, reserva) == 409

    # Verifica: sólo quedó la confirmación de su propia cancelación.
    assert [a.data["kind"] for _, a in channel.sent] == ["user_cancellation"]
    assert [e["kind"] for e in socio.center()["notifications"]] == ["user_cancellation"]


def test_repetir_la_anulacion_no_repite_el_aviso(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """repetir la anulación no repite el aviso @supuesto:CU-24.2-SUP-08"""
    socio = a_member(api, engine, sign_in, unique)
    reserva = socio.book("21:00")

    assert force_cancel(socio, admin, reserva) == 200
    assert force_cancel(socio, admin, reserva) == 200

    assert len(channel.sent) == 1
    assert len(socio.center()["notifications"]) == 1


def test_una_anulacion_que_no_se_completa_no_deja_aviso(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """una anulación rechazada no deja aviso @supuesto:CU-24.2-SUP-08"""
    socio = a_member(api, engine, sign_in, unique)
    reserva = socio.book("21:00")
    movida = {**reserva, "starts_at": "2030-01-01T21:00:00-03:00"}

    assert force_cancel(socio, admin, movida) == 409

    assert channel.sent == []
    assert socio.center() == {"notifications": [], "unread": 0}


def test_si_el_push_falla_no_se_reintenta_y_el_aviso_queda_en_el_centro(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    admin: dict[str, str],
) -> None:
    """si el push falla el aviso queda en el centro con el envío fallido @supuesto:CU-24.2-SUP-01 @supuesto:CU-24.2-SUP-07"""
    app_of(api).dependency_overrides[push_channel] = lambda: CanalQueFalla()
    try:
        socio = a_member(api, engine, sign_in, unique)
        reserva = socio.book("21:00")

        assert force_cancel(socio, admin, reserva) == 200

        assert [e["title"] for e in socio.center()["notifications"]] == [TITULO]
        assert for_admin(socio, admin, reserva["id"])["notice_delivery"] == "failed"
    finally:
        app_of(api).dependency_overrides.pop(push_channel, None)
