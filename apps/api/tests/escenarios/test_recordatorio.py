from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from types import SimpleNamespace
from typing import Any
from zoneinfo import ZoneInfo

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

ZONA = ZoneInfo("America/Argentina/Buenos_Aires")
CONTRASENA = "ClubNahuel1"


class CanalDePrueba:
    """El servicio de notificaciones del teléfono, que anota lo que se le pide enviar."""

    def __init__(self) -> None:
        self.enviados: list[tuple[list[str], Any]] = []

    def enviar(self, tokens: list[str], aviso: Any) -> SimpleNamespace:
        self.enviados.append((list(tokens), aviso))
        return SimpleNamespace(enviados=len(tokens), invalidos=())


@dataclass
class Socio:
    api: TestClient
    motor: Engine
    correo: str
    sesion: dict[str, str]
    usuario_id: int
    espacio_id: int
    sede: str
    dispositivo: str
    reservas: list[dict[str, Any]] = field(default_factory=list)

    def reservar(self, desde: str) -> dict[str, Any]:
        r = self.api.post(
            "/reservas",
            headers=self.sesion,
            json={
                "espacio_id": self.espacio_id,
                "fecha": manana().isoformat(),
                "desde": desde,
                "horas": 1,
            },
        )
        assert r.status_code == 201
        reserva: dict[str, Any] = r.json()
        self.reservas.append(reserva)
        return reserva

    def barrer(self, canal: CanalDePrueba, ahora: datetime) -> int:
        """El barrido de recordatorios corriendo a la hora [ahora] del club, para este socio."""
        from app.aplicacion.notificaciones import enviar_recordatorios
        from app.infraestructura.notificaciones import NotificacionesSql

        with self.motor.connect() as conn:
            return enviar_recordatorios(NotificacionesSql(conn), canal, ahora, self.usuario_id)

    def centro(self) -> dict[str, Any]:
        r = self.api.get("/notificaciones", headers=self.sesion)
        assert r.status_code == 200
        centro: dict[str, Any] = r.json()
        return centro


def manana() -> Any:
    return datetime.now(ZONA).date() + timedelta(days=1)


def a_las(hora: int, minuto: int = 0) -> datetime:
    """La hora [hora]:[minuto] de mañana en el club."""
    return datetime.combine(manana(), datetime.min.time(), ZONA).replace(hour=hora, minute=minuto)


def un_socio(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    *,
    permiso: bool = True,
) -> Socio:
    """Una cuenta nueva con un dispositivo registrado, en una sede con una cancha de Fútbol 5."""
    s = unico()
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
    sede = f"Sede Morón {s}"
    with motor.begin() as conn:
        espacio = conn.execute(
            text(
                "WITH s AS (INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
                " VALUES (:n, 'Av. Rivadavia', 19850, '08:00', '23:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id)"
                " INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada,"
                " iluminada, precio_por_hora) SELECT id, 'Futbol', 'F5', 1, :e, false, true,"
                " 38000 FROM s RETURNING id"
            ),
            {"n": sede, "e": f"Moron{s}_Rivadavia_19850_Futbol_F5_1"},
        ).scalar_one()
        usuario = conn.execute(
            text("SELECT id FROM usuario WHERE correo = :c"), {"c": correo}
        ).scalar_one()
    token = iniciar_sesion(correo, CONTRASENA)
    assert token is not None
    sesion = {"Authorization": f"Bearer {token}"}
    dispositivo = f"fcm-{s}"
    registro = api.put(
        "/dispositivos",
        headers=sesion,
        json={"token": dispositivo, "plataforma": "android", "permiso": permiso},
    )
    assert registro.status_code == 204
    return Socio(api, motor, correo, sesion, int(usuario), int(espacio), sede, dispositivo)


def test_una_hora_antes_del_inicio_se_envia_una_sola_vez_el_recordatorio_con_deporte_sede_y_horario(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """una hora antes del inicio recibe el recordatorio con deporte, sede y horario @CU-24.1-H01-01"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")
    canal = CanalDePrueba()

    # Verifica: con más de una hora por delante todavía no se envía nada.
    assert socio.barrer(canal, a_las(19, 59)) == 0
    assert canal.enviados == []

    # Verifica: a la hora exacta sale al dispositivo del socio, con lo que dice el CU.
    assert socio.barrer(canal, a_las(20, 0)) == 1
    assert len(canal.enviados) == 1
    tokens, aviso = canal.enviados[0]
    assert tokens == [socio.dispositivo]
    assert aviso.titulo == "Tu reserva es en 1 hora"
    assert aviso.cuerpo == f"Fútbol 5 · {socio.sede} · 21:00 – 22:00"
    assert aviso.datos["reserva_id"] == str(reserva["id"])

    # Verifica: se envía una sola vez, aunque el barrido vuelva a pasar antes del turno.
    assert socio.barrer(canal, a_las(20, 30)) == 0
    assert len(canal.enviados) == 1


def test_sin_permiso_de_notificaciones_no_se_envia_pero_el_aviso_queda_en_el_centro(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """sin permiso de notificaciones no se envía y el aviso queda registrado @CU-24.1-H03-01"""
    socio = un_socio(api, motor, iniciar_sesion, unico, permiso=False)
    socio.reservar("21:00")
    canal = CanalDePrueba()

    registrados = socio.barrer(canal, a_las(20, 0))

    # Verifica: nada sale hacia el teléfono, y el aviso está en el centro sin leer.
    assert registrados == 1
    assert canal.enviados == []
    centro = socio.centro()
    assert [n["titulo"] for n in centro["notificaciones"]] == ["Tu reserva es en 1 hora"]
    assert centro["no_leidas"] == 1


def test_un_recordatorio_que_no_se_tocó_queda_como_no_leído(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """un recordatorio que no se tocó queda como no leído @CU-24.1-H04-01"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")
    assert socio.centro() == {"notificaciones": [], "no_leidas": 0}

    socio.barrer(CanalDePrueba(), a_las(20, 0))

    # Verifica: el aviso figura en el centro, sin leer, con su reserva y su cuerpo.
    centro = socio.centro()
    assert centro["no_leidas"] == 1
    [aviso] = centro["notificaciones"]
    assert aviso["tipo"] == "recordatorio"
    assert aviso["leida"] is False
    assert aviso["reserva_id"] == reserva["id"]
    assert aviso["cuerpo"] == f"Fútbol 5 · {socio.sede} · 21:00 – 22:00"


def test_marcar_todas_deja_todas_las_notificaciones_como_leidas(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """«Marcar todas» deja todas las notificaciones como leídas @CU-24.1-H04-02"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    socio.reservar("21:00")
    socio.reservar("22:00")
    canal = CanalDePrueba()
    socio.barrer(canal, a_las(20, 30))
    socio.barrer(canal, a_las(21, 30))
    assert socio.centro()["no_leidas"] == 2

    r = socio.api.post("/notificaciones/leer-todas", headers=socio.sesion)

    # Verifica: ninguna queda sin leer, y cada una guarda que fue leída.
    assert r.status_code == 204
    centro = socio.centro()
    assert centro["no_leidas"] == 0
    assert [n["leida"] for n in centro["notificaciones"]] == [True, True]


def test_una_reserva_cancelada_antes_no_recibe_recordatorio(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """la reserva se canceló antes y el recordatorio no llega @CU-24.1-H05-01"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")
    cancelada = socio.api.post(f"/reservas/{reserva['id']}/cancelar", headers=socio.sesion)
    assert cancelada.status_code == 200
    canal = CanalDePrueba()

    registrados = socio.barrer(canal, a_las(20, 0))

    # Verifica: no se envía ni se registra nada, ni a esa hora ni después.
    assert registrados == 0
    assert socio.barrer(canal, a_las(20, 45)) == 0
    assert canal.enviados == []
    assert socio.centro() == {"notificaciones": [], "no_leidas": 0}


def test_una_reserva_modificada_recibe_el_recordatorio_una_hora_antes_del_horario_nuevo(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """la reserva se modificó y el recordatorio llega una hora antes del horario nuevo @CU-24.1-H05-02"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")
    cambio = socio.api.post(
        f"/reservas/{reserva['id']}/modificar",
        headers=socio.sesion,
        json={"espacio_id": socio.espacio_id, "fecha": manana().isoformat(), "desde": "22:00"},
    )
    assert cambio.status_code == 200
    canal = CanalDePrueba()

    # Verifica: una hora antes del horario viejo no llega nada.
    assert socio.barrer(canal, a_las(20, 0)) == 0
    assert canal.enviados == []

    # Verifica: una hora antes del nuevo llega, con el horario nuevo.
    assert socio.barrer(canal, a_las(21, 0)) == 1
    [(tokens, aviso)] = canal.enviados
    assert tokens == [socio.dispositivo]
    assert aviso.cuerpo == f"Fútbol 5 · {socio.sede} · 22:00 – 23:00"
