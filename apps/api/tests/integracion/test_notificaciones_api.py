"""Dispositivos, recordatorios y centro de notificaciones contra la base y el emulador reales."""

from collections.abc import Callable, Sequence
from datetime import datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.notificaciones.casos_de_uso import ResultadoDeEnvio, enviar_recordatorios
from app.modules.notificaciones.reglas import Aviso, Recordatorio
from app.modules.notificaciones.repositorio import NotificacionesSql

ZONA = ZoneInfo("America/Argentina/Buenos_Aires")


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


class Canal:
    def __init__(self, falla: bool = False) -> None:
        self.falla = falla
        self.enviados: list[tuple[list[str], Aviso]] = []

    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        if self.falla:
            raise ConnectionError("el servicio no contesta")
        self.enviados.append((list(tokens), aviso))
        return ResultadoDeEnvio(enviados=len(tokens))


def _yo(api: TestClient, motor: Engine, token: str) -> int:
    correo = api.get("/yo", headers=_con(token)).json()["correo"]
    with motor.connect() as conn:
        return int(
            conn.execute(
                text("SELECT id FROM usuario WHERE correo = :c"), {"c": correo}
            ).scalar_one()
        )


def _espacio(api: TestClient, token_admin: str, sede_id: int) -> int:
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
    assert r.status_code == 201
    return int(r.json()["id"])


def _barrer(motor: Engine, usuario: int, canal: Canal, ahora: datetime) -> int:
    with motor.connect() as conn:
        return enviar_recordatorios(NotificacionesSql(conn), canal, ahora, usuario)


def _manana_a_las(hora: int) -> datetime:
    dia = datetime.now(ZONA).date() + timedelta(days=1)
    return datetime.combine(dia, datetime.min.time(), ZONA).replace(hour=hora)


def _registrar(api: TestClient, token: str, dispositivo: str, permiso: bool = True) -> int:
    return api.put(
        "/dispositivos",
        headers=_con(token),
        json={"token": dispositivo, "plataforma": "android", "permiso": permiso},
    ).status_code


def _reservar(api: TestClient, token: str, espacio: int, desde: str = "21:00") -> dict[str, Any]:
    r = api.post(
        "/reservas",
        headers=_con(token),
        json={
            "espacio_id": espacio,
            "fecha": _manana_a_las(0).date().isoformat(),
            "desde": desde,
            "horas": 1,
        },
    )
    assert r.status_code == 201
    reserva: dict[str, Any] = r.json()
    return reserva


def test_registrar_un_dispositivo_exige_sesion_de_usuario_y_datos_validos(
    api: TestClient, token_admin: str, token_usuario: str, unico: Callable[[], str]
) -> None:
    dispositivo = f"fcm-{unico()}"
    cuerpo = {"token": dispositivo, "plataforma": "android", "permiso": True}

    assert api.put("/dispositivos", json=cuerpo).status_code == 401
    assert api.put("/dispositivos", headers=_con(token_admin), json=cuerpo).status_code == 403
    vacio = api.put("/dispositivos", headers=_con(token_usuario), json=cuerpo | {"token": "  "})
    assert vacio.status_code == 422
    assert vacio.json()["errores"]["token"] == "Este campo es obligatorio"
    assert (
        api.put(
            "/dispositivos", headers=_con(token_usuario), json=cuerpo | {"plataforma": "web"}
        ).status_code
        == 422
    )
    assert api.put("/dispositivos", headers=_con(token_usuario), json=cuerpo).status_code == 204
    # Registrarlo de nuevo con otro permiso lo actualiza, no lo duplica.
    assert (
        api.put(
            "/dispositivos", headers=_con(token_usuario), json=cuerpo | {"permiso": False}
        ).status_code
        == 204
    )


def test_un_token_registrado_por_otra_cuenta_no_cambia_de_dueno(
    api: TestClient,
    motor: Engine,
    token_usuario: str,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    s = unico()
    dispositivo = f"fcm-{s}"
    assert _registrar(api, token_usuario, dispositivo) == 204
    otro = api.post(
        "/registro",
        json={
            "nombre": "Lucía",
            "apellido": "Paz",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "fecha_nacimiento": "1996-02-11",
            "correo": f"otra.{s}@correo.com",
            "contrasena": "ClubNahuel1",
        },
    )
    assert otro.status_code == 201
    token_otra = iniciar_sesion(f"otra.{s}@correo.com", "ClubNahuel1")
    assert token_otra is not None

    assert _registrar(api, token_otra, dispositivo) == 204

    with motor.connect() as conn:
        duenos = conn.execute(
            text("SELECT usuario_id FROM dispositivo WHERE token = :t AND activo"),
            {"t": dispositivo},
        ).all()
    assert [int(d.usuario_id) for d in duenos] == [_yo(api, motor, token_usuario)]


def test_con_varios_dispositivos_llega_a_todos_y_al_cerrar_sesion_uno_deja_de_recibir(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
    unico: Callable[[], str],
) -> None:
    """varias sesiones a la vez y al cerrar una deja de recibir push (decisión 14)"""
    espacio = _espacio(api, token_admin, sede[0])
    usuario = _yo(api, motor, token_usuario)
    s = unico()
    assert _registrar(api, token_usuario, f"a-{s}") == 204
    assert _registrar(api, token_usuario, f"b-{s}") == 204
    _reservar(api, token_usuario, espacio)
    primero = Canal()

    assert _barrer(motor, usuario, primero, _manana_a_las(20)) == 1
    assert [t for t, _ in primero.enviados] == [[f"a-{s}", f"b-{s}"]]

    baja = api.post("/dispositivos/baja", headers=_con(token_usuario), json={"token": f"a-{s}"})
    assert baja.status_code == 204
    otra_reserva = _reservar(api, token_usuario, espacio, "22:00")
    segundo = Canal()
    assert _barrer(motor, usuario, segundo, _manana_a_las(21)) == 1
    assert [t for t, _ in segundo.enviados] == [[f"b-{s}"]]
    assert segundo.enviados[0][1].datos["reserva_id"] == str(otra_reserva["id"])
    # Dar de baja uno que ya no está responde igual.
    repetida = api.post("/dispositivos/baja", headers=_con(token_usuario), json={"token": f"a-{s}"})
    assert repetida.status_code == 204


def test_una_reserva_hecha_con_menos_de_una_hora_de_anticipacion_no_recibe_recordatorio(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
) -> None:
    """una reserva hecha con menos de una hora de anticipación no avisa (decisión 10)"""
    espacio = _espacio(api, token_admin, sede[0])
    usuario = _yo(api, motor, token_usuario)
    inicio = _manana_a_las(21)
    with motor.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total,"
                " creado_en, modificado_en) VALUES (:u, :e, :i, :f, 38000, 38000, :c, :c)"
            ),
            {
                "u": usuario,
                "e": espacio,
                "i": inicio,
                "f": inicio + timedelta(hours=1),
                "c": inicio - timedelta(minutes=30),
            },
        )
    canal = Canal()

    assert _barrer(motor, usuario, canal, inicio - timedelta(minutes=20)) == 0
    assert canal.enviados == []


def test_si_el_barrido_llega_tarde_el_recordatorio_sale_mientras_la_reserva_no_empezo(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
    unico: Callable[[], str],
) -> None:
    """si el servidor estuvo caído el aviso sale tarde, antes del inicio @supuesto:CU-24.1-SUP-07"""
    espacio = _espacio(api, token_admin, sede[0])
    usuario = _yo(api, motor, token_usuario)
    _registrar(api, token_usuario, f"fcm-{unico()}")
    _reservar(api, token_usuario, espacio)
    canal = Canal()

    assert _barrer(motor, usuario, canal, _manana_a_las(21)) == 0
    assert _barrer(motor, usuario, canal, _manana_a_las(20) + timedelta(minutes=50)) == 1
    assert len(canal.enviados) == 1


def test_una_reserva_modificada_despues_del_aviso_recibe_otro_para_el_horario_nuevo(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
) -> None:
    """una reserva modificada recibe un aviso nuevo y el anterior queda @supuesto:CU-24.1-SUP-12"""
    espacio = _espacio(api, token_admin, sede[0])
    usuario = _yo(api, motor, token_usuario)
    reserva = _reservar(api, token_usuario, espacio)
    assert _barrer(motor, usuario, Canal(), _manana_a_las(20)) == 1
    cambio = api.post(
        f"/reservas/{reserva['id']}/modificar",
        headers=_con(token_usuario),
        json={
            "espacio_id": espacio,
            "fecha": _manana_a_las(0).date().isoformat(),
            "desde": "22:00",
        },
    )
    assert cambio.status_code == 200

    assert _barrer(motor, usuario, Canal(), _manana_a_las(21)) == 1

    cuerpos = [
        n["cuerpo"]
        for n in api.get("/notificaciones", headers=_con(token_usuario)).json()["notificaciones"]
    ]
    assert [c.rsplit(" · ", 1)[1] for c in cuerpos] == ["22:00 – 23:00", "21:00 – 22:00"]


def test_un_envio_fallido_deja_el_aviso_en_el_centro_marcado_como_fallido(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
    unico: Callable[[], str],
) -> None:
    """el envío fallido queda en el centro, sin reintento @supuesto:CU-24.1-SUP-02"""
    espacio = _espacio(api, token_admin, sede[0])
    usuario = _yo(api, motor, token_usuario)
    _registrar(api, token_usuario, f"fcm-{unico()}")
    _reservar(api, token_usuario, espacio)

    assert _barrer(motor, usuario, Canal(falla=True), _manana_a_las(20)) == 1
    assert _barrer(motor, usuario, Canal(), _manana_a_las(20)) == 0

    with motor.connect() as conn:
        envio: Any = conn.execute(
            text("SELECT envio FROM notificacion WHERE usuario_id = :u"), {"u": usuario}
        ).scalar_one()
    assert envio == "fallida"
    assert api.get("/notificaciones", headers=_con(token_usuario)).json()["no_leidas"] == 1


def test_el_aviso_guarda_cuando_se_creo_se_envio_y_se_leyo(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
    unico: Callable[[], str],
) -> None:
    """se estampan la creación, el envío y la lectura @supuesto:CU-24.1-SUP-05"""
    espacio = _espacio(api, token_admin, sede[0])
    usuario = _yo(api, motor, token_usuario)
    _registrar(api, token_usuario, f"fcm-{unico()}")
    _reservar(api, token_usuario, espacio)
    _barrer(motor, usuario, Canal(), _manana_a_las(20))
    aviso = api.get("/notificaciones", headers=_con(token_usuario)).json()["notificaciones"][0]

    with motor.connect() as conn:
        antes = conn.execute(
            text("SELECT creada_en, enviada_en, leida_en FROM notificacion WHERE id = :i"),
            {"i": aviso["id"]},
        ).one()
    assert antes.creada_en is not None
    assert antes.enviada_en is not None
    assert antes.leida_en is None

    leida = api.post(f"/notificaciones/{aviso['id']}/leer", headers=_con(token_usuario))
    assert leida.status_code == 204
    with motor.connect() as conn:
        despues: Any = conn.execute(
            text("SELECT leida_en FROM notificacion WHERE id = :i"), {"i": aviso["id"]}
        ).scalar_one()
    assert despues is not None
    # Leerla de nuevo responde igual y no cambia cuándo se leyó.
    api.post(f"/notificaciones/{aviso['id']}/leer", headers=_con(token_usuario))
    with motor.connect() as conn:
        igual: Any = conn.execute(
            text("SELECT leida_en FROM notificacion WHERE id = :i"), {"i": aviso["id"]}
        ).scalar_one()
    assert igual == despues


def test_las_notificaciones_son_de_quien_las_recibe(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    espacio = _espacio(api, token_admin, sede[0])
    usuario = _yo(api, motor, token_usuario)
    _reservar(api, token_usuario, espacio)
    _barrer(motor, usuario, Canal(), _manana_a_las(20))
    ajena = api.get("/notificaciones", headers=_con(token_usuario)).json()["notificaciones"][0]
    s = unico()
    api.post(
        "/registro",
        json={
            "nombre": "Lucía",
            "apellido": "Paz",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "fecha_nacimiento": "1996-02-11",
            "correo": f"otra.{s}@correo.com",
            "contrasena": "ClubNahuel1",
        },
    )
    token_otra = iniciar_sesion(f"otra.{s}@correo.com", "ClubNahuel1")
    assert token_otra is not None

    assert api.get("/notificaciones").status_code == 401
    assert api.get("/notificaciones", headers=_con(token_otra)).json() == {
        "notificaciones": [],
        "no_leidas": 0,
    }
    assert (
        api.post(f"/notificaciones/{ajena['id']}/leer", headers=_con(token_otra)).status_code == 404
    )
    api.post("/notificaciones/leer-todas", headers=_con(token_otra))
    assert api.get("/notificaciones", headers=_con(token_usuario)).json()["no_leidas"] == 1


def test_el_borde_de_dispositivos_y_notificaciones_responde_con_un_codigo(
    api: TestClient, token_usuario: str
) -> None:
    sesion = _con(token_usuario)
    base = {"token": "fcm-x", "plataforma": "android", "permiso": True}

    assert (
        api.put("/dispositivos", headers=sesion, json=base | {"permiso": "quizás"}).status_code
        == 422
    )
    assert api.put("/dispositivos", headers=sesion, json={"token": "fcm-x"}).status_code == 422
    assert api.put("/dispositivos", headers=sesion, content=b"{roto").status_code == 422
    assert api.put("/dispositivos", headers=sesion, json=base | {"token": 7}).status_code == 422
    assert api.post("/notificaciones/0/leer", headers=sesion).status_code == 422
    assert api.post(f"/notificaciones/{2**63}/leer", headers=sesion).status_code == 422
    assert api.post("/notificaciones/abc/leer", headers=sesion).status_code == 422
    assert api.post("/notificaciones/999999/leer", headers=sesion).status_code == 404


def test_las_respuestas_del_centro_no_traen_campos_de_mas_ni_se_cachean(
    api: TestClient, token_usuario: str
) -> None:
    r = api.get("/notificaciones", headers=_con(token_usuario))

    assert r.status_code == 200
    assert set(r.json()) == {"notificaciones", "no_leidas"}


class EntreLaFotoYElRegistro(NotificacionesSql):
    """Hace que algo pase justo después de que el barrido mira las reservas y antes de que
    registre el aviso."""

    def __init__(self, conn: Any, alguien: Callable[[], None]) -> None:
        super().__init__(conn)
        self._alguien = alguien

    def vencidos(self, ahora: datetime, usuario_id: int | None) -> list[Recordatorio]:
        foto = super().vencidos(ahora, usuario_id)
        self._alguien()
        return foto


def _barrer_con(
    motor: Engine, usuario: int, canal: Canal, ahora: datetime, alguien: Callable[[], None]
) -> int:
    with motor.connect() as conn:
        return enviar_recordatorios(EntreLaFotoYElRegistro(conn, alguien), canal, ahora, usuario)


def _sin_recordatorios(motor: Engine, usuario: int) -> bool:
    with motor.connect() as conn:
        return (
            conn.execute(
                text(
                    "SELECT count(*) FROM notificacion WHERE usuario_id = :u"
                    " AND tipo = 'recordatorio'"
                ),
                {"u": usuario},
            ).scalar_one()
            == 0
        )


def test_una_reserva_cancelada_entre_la_lectura_y_el_registro_no_recibe_aviso(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
    unico: Callable[[], str],
) -> None:
    espacio = _espacio(api, token_admin, sede[0])
    usuario = _yo(api, motor, token_usuario)
    _registrar(api, token_usuario, f"fcm-{unico()}")
    reserva = _reservar(api, token_usuario, espacio)
    canal = Canal()

    def cancelar() -> None:
        r = api.post(f"/reservas/{reserva['id']}/cancelar", headers=_con(token_usuario))
        assert r.status_code == 200

    assert _barrer_con(motor, usuario, canal, _manana_a_las(20), cancelar) == 0
    assert canal.enviados == []
    assert _sin_recordatorios(motor, usuario)


def test_una_reserva_movida_entre_la_lectura_y_el_registro_no_avisa_el_horario_viejo(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
    unico: Callable[[], str],
) -> None:
    espacio = _espacio(api, token_admin, sede[0])
    usuario = _yo(api, motor, token_usuario)
    _registrar(api, token_usuario, f"fcm-{unico()}")
    reserva = _reservar(api, token_usuario, espacio)
    canal = Canal()

    def mover() -> None:
        r = api.post(
            f"/reservas/{reserva['id']}/modificar",
            headers=_con(token_usuario),
            json={
                "espacio_id": espacio,
                "fecha": _manana_a_las(0).date().isoformat(),
                "desde": "22:00",
            },
        )
        assert r.status_code == 200

    assert _barrer_con(motor, usuario, canal, _manana_a_las(20), mover) == 0
    assert canal.enviados == []
    assert _sin_recordatorios(motor, usuario)


def test_una_cuenta_dada_de_baja_entre_la_lectura_y_el_registro_no_recibe_aviso(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
    unico: Callable[[], str],
) -> None:
    espacio = _espacio(api, token_admin, sede[0])
    usuario = _yo(api, motor, token_usuario)
    _registrar(api, token_usuario, f"fcm-{unico()}")
    _reservar(api, token_usuario, espacio)
    canal = Canal()

    def dar_de_baja() -> None:
        with motor.begin() as conn:
            conn.execute(
                text("UPDATE usuario SET activo = false, dado_de_baja_en = now() WHERE id = :u"),
                {"u": usuario},
            )

    assert _barrer_con(motor, usuario, canal, _manana_a_las(20), dar_de_baja) == 0
    assert canal.enviados == []
