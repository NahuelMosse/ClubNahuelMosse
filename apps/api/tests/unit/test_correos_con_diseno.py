import json
import logging
from collections.abc import Sequence
from contextlib import contextmanager
from datetime import UTC, date, datetime, timedelta
from typing import Any, cast
from uuid import UUID

import pytest
from fastapi import BackgroundTasks

from app.modules.notificaciones.casos_de_uso import ResultadoDeEnvio, enviar_recordatorios
from app.modules.notificaciones.reglas import Aviso, Recordatorio
from app.modules.recuperacion import correo
from app.modules.recuperacion.casos_de_uso import pedir_enlace
from app.modules.recuperacion.reglas import Destinatario, Mensaje
from app.modules.reservas import rutas
from app.modules.reservas.reglas import Reserva
from app.modules.sesion import Perfil
from app.shared.config import config
from app.shared.plantilla_correo import html_de_correo

ENLACE_BASE = "https://club.example"
DIRECCION = "ana@correo.com"


def _id(numero: int) -> UUID:
    return UUID(int=numero)


class _Enlaces:
    def __init__(self, nombre: str = "Ana") -> None:
        self.nombre = nombre

    def destinatario(self, correo: str) -> Destinatario:
        return Destinatario(_id(1), self.nombre, DIRECCION)

    def emitir(self, usuario_id: UUID, codigo_hash: str, vigencia: int, maximo: int) -> bool:
        return True


def _recuperacion(nombre: str = "Ana") -> Mensaje:
    mensaje = pedir_enlace(DIRECCION, ENLACE_BASE, cast(Any, _Enlaces(nombre)))
    assert mensaje is not None
    return mensaje


def test_el_correo_de_recuperacion_sale_en_html_con_la_plantilla_el_saludo_el_boton_al_enlace_y_el_vencimiento() -> (
    None
):
    """el correo de recuperación sale en HTML con la plantilla, el saludo, el botón al enlace y el vencimiento
    @MAIL-02-S1 @assumption:MAIL-02-ASM-03"""
    html = _recuperacion().html

    assert html is not None
    for marca in ("#0A0A0B", "#141416", "#D4FF3D", "#A1A1AA", "CLUB NAHUEL MOSSE", "<table"):
        assert marca in html
    assert "<script" not in html
    assert "<img" not in html
    assert "Hola Ana" in html
    assert "Crear contraseña nueva" in html
    assert f'href="{ENLACE_BASE}/enlace/recuperar#codigo=' in html
    assert "30 minutos" in html
    assert "una sola vez" in html
    assert "ignorá" in html


def _reserva(**cambios: Any) -> Reserva:
    inicio = datetime(2026, 10, 28, 23, 0, tzinfo=UTC)  # 20:00 en el club
    datos: dict[str, Any] = {
        "id": _id(9),
        "espacio_id": _id(2),
        "sede_id": _id(3),
        "espacio": "Cancha 1",
        "deporte": "Futbol",
        "tipo": "F5",
        "sede": "Sede Morón",
        "direccion": "Calle 1",
        "inicio": inicio,
        "fin": inicio + timedelta(hours=1),
        "precio_por_hora": 12000,
        "total": 12000,
        "estado": "activa",
        "motivo": None,
        "cancelable": True,
    }
    return Reserva(**(datos | cambios))


def _perfil(nombre: str = "Ana") -> Perfil:
    return Perfil(_id(1), "uid", nombre, "Pérez", DIRECCION, "usuario", "30111222", date(1990, 1, 1))


def _recordatorio(sede: str = "Sede Morón") -> Recordatorio:
    inicio = datetime(2026, 10, 2, 0, 0, tzinfo=UTC)
    return Recordatorio(
        _id(7), _id(1), inicio, inicio + timedelta(hours=1), "Futbol", "F5", sede, DIRECCION, "Ana"
    )


def test_cada_correo_sigue_llevando_su_texto_y_el_html_repite_el_enlace_del_boton() -> None:
    """cada correo sigue llevando su texto y el HTML repite el enlace del botón
    @MAIL-02-S2"""
    recuperacion = _recuperacion()
    enlace = recuperacion.cuerpo.split("\n")[3]
    assert enlace.startswith(ENLACE_BASE)
    assert recuperacion.html is not None
    assert recuperacion.html.count(enlace) >= 2
    assert "Crear contraseña nueva" not in recuperacion.cuerpo or enlace in recuperacion.cuerpo

    enviados: list[Mensaje] = []
    rutas_enviar = pytest.MonkeyPatch()
    try:
        rutas_enviar.setattr(rutas, "enviar", enviados.append)
        tareas = BackgroundTasks()
        rutas_enviar.setattr(rutas, "reservar", lambda *a, **k: _reserva())
        rutas.hacer_reserva(
            rutas.PedidoDeReserva(espacio_id=cast(Any, _id(2)), fecha=date(2026, 10, 28), desde="20:00", horas=1),
            _perfil(),
            cast(Any, None),
            tareas,
        )
        _correr(tareas)
    finally:
        rutas_enviar.undo()
    from app.modules.notificaciones.reglas import correo_recordatorio

    for mensaje in (*enviados, correo_recordatorio(_recordatorio())):
        assert mensaje.cuerpo.strip()
        assert mensaje.html is not None


def _correr(tareas: BackgroundTasks) -> None:
    for tarea in tareas.tasks:
        tarea.func(*tarea.args, **tarea.kwargs)


def test_brevo_recibe_htmlcontent_solo_si_hay_html_smtp_la_alternativa_y_el_buzon_solo_el_texto(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Brevo recibe htmlContent sólo si hay HTML, SMTP la alternativa y el buzón sólo el texto
    @assumption:MAIL-02-ASM-01"""
    pedidos: list[dict[str, Any]] = []

    def falso_urlopen(pedido: Any, timeout: int) -> Any:
        pedidos.append(json.loads(pedido.data))

        @contextmanager
        def respuesta() -> Any:
            yield None

        return respuesta()

    monkeypatch.setattr("urllib.request.urlopen", falso_urlopen)
    monkeypatch.setattr(config, "brevo_api_key", "clave")
    monkeypatch.setattr(config, "correo_remitente", "club@correo.com")
    correo._por_brevo(Mensaje(DIRECCION, "Asunto", "texto", "<p>hola</p>"))
    correo._por_brevo(Mensaje(DIRECCION, "Asunto", "texto"))
    assert pedidos[0]["htmlContent"] == "<p>hola</p>"
    assert pedidos[0]["textContent"] == "texto"
    assert "htmlContent" not in pedidos[1]

    enviados: list[Any] = []

    class FalsoSmtp:
        def __init__(self, *a: Any, **k: Any) -> None: ...
        def __enter__(self) -> "FalsoSmtp":
            return self

        def __exit__(self, *a: Any) -> None: ...
        def starttls(self, **k: Any) -> None: ...
        def login(self, *a: Any) -> None: ...
        def send_message(self, mensaje: Any) -> None:
            enviados.append(mensaje)

    monkeypatch.setattr("smtplib.SMTP", FalsoSmtp)
    monkeypatch.setattr(config, "smtp_host", "smtp.example")
    correo._por_smtp(Mensaje(DIRECCION, "Asunto", "texto", "<p>hola</p>"))
    correo._por_smtp(Mensaje(DIRECCION, "Asunto", "texto"))
    assert enviados[0].get_body(("html",)).get_content().strip() == "<p>hola</p>"
    assert enviados[1].get_body(("html",)) is None

    guardado: list[dict[str, Any]] = []

    class FalsaConexion:
        def execute(self, sql: Any, params: dict[str, Any]) -> None:
            guardado.append(params)

    class FalsoMotor:
        @contextmanager
        def begin(self) -> Any:
            yield FalsaConexion()

    monkeypatch.setattr(correo, "motor", lambda: FalsoMotor())
    correo._al_buzon(Mensaje(DIRECCION, "Asunto", "texto", "<p>hola</p>"))
    assert guardado == [{"p": DIRECCION, "a": "Asunto", "c": "texto"}]


def test_un_nombre_o_una_sede_con_marcado_salen_escapados_en_el_html() -> None:
    """un nombre o una sede con marcado salen escapados en el HTML
    @assumption:MAIL-02-ASM-02"""
    from app.modules.notificaciones.reglas import correo_recordatorio
    from app.modules.reservas.correo import correo_de_reserva

    malo = "<b>x</b> & <script>"
    htmls = [
        _recuperacion(malo).html,
        correo_de_reserva(_perfil(malo), _reserva(sede=malo)).html,
        correo_recordatorio(_recordatorio(malo)).html,
        html_de_correo(malo, [malo], ("Ir", "https://x.test/?a=1&b=2"), malo),
    ]
    for html in htmls:
        assert html is not None
        assert "<b>x</b>" not in html
        assert "<script>" not in html
        assert "&lt;b&gt;x&lt;/b&gt;" in html or "&amp;" in html
    assert "a=1&amp;b=2" in str(htmls[3])


def test_al_hacer_una_reserva_sale_el_correo_de_confirmacion_con_deporte_sede_dia_horario_y_total(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """al hacer una reserva sale el correo de confirmación con deporte, sede, día, horario y total
    @MAIL-02-S3"""
    enviados: list[Mensaje] = []
    monkeypatch.setattr(rutas, "enviar", enviados.append)
    monkeypatch.setattr(rutas, "reservar", lambda *a, **k: _reserva())
    tareas = BackgroundTasks()
    respuesta = rutas.hacer_reserva(
        rutas.PedidoDeReserva(espacio_id=cast(Any, _id(2)), fecha=date(2026, 10, 28), desde="20:00", horas=1),
        _perfil(),
        cast(Any, None),
        tareas,
    )
    assert not isinstance(respuesta, type(None))
    assert enviados == []  # sale después de responder

    _correr(tareas)

    assert len(enviados) == 1
    mensaje = enviados[0]
    assert mensaje.para == DIRECCION
    assert mensaje.asunto == "Tu reserva está confirmada"
    for dato in ("Fútbol 5", "Sede Morón", "miércoles 28 de octubre", "20:00", "21:00", "12.000"):
        assert dato in mensaje.cuerpo
        assert mensaje.html is not None
        assert dato in mensaje.html


def test_si_el_correo_de_confirmacion_falla_la_reserva_responde_igual_y_queda_en_el_log_sin_la_direccion(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    """si el correo de confirmación falla la reserva responde igual y queda en el log sin la dirección
    @assumption:MAIL-02-ASM-04"""
    monkeypatch.setattr(config, "correo_modo", "brevo")

    def roto(*a: Any, **k: Any) -> None:
        raise ConnectionError(f"sin red hacia {DIRECCION}")

    monkeypatch.setattr("urllib.request.urlopen", roto)
    monkeypatch.setattr(rutas, "reservar", lambda *a, **k: _reserva())
    tareas = BackgroundTasks()
    respuesta = rutas.hacer_reserva(
        rutas.PedidoDeReserva(espacio_id=cast(Any, _id(2)), fecha=date(2026, 10, 28), desde="20:00", horas=1),
        _perfil(),
        cast(Any, None),
        tareas,
    )
    assert getattr(respuesta, "id", None) == _id(9)

    with caplog.at_level(logging.ERROR, logger="clubnahuelmosse.correo"):
        _correr(tareas)

    assert "Tu reserva está confirmada" in caplog.text
    assert "ConnectionError" in caplog.text
    assert DIRECCION not in caplog.text


def test_modificar_cancelar_o_anular_no_mandan_correo(monkeypatch: pytest.MonkeyPatch) -> None:
    """modificar, cancelar o anular no mandan correo
    @assumption:MAIL-02-ASM-05"""
    enviados: list[Mensaje] = []
    monkeypatch.setattr(rutas, "enviar", enviados.append)
    monkeypatch.setattr(rutas, "despachar_de", lambda *a: None)
    monkeypatch.setattr(rutas, "cancelar_reserva", lambda *a: _reserva(estado="cancelada"))
    monkeypatch.setattr(rutas, "modificar_reserva", lambda *a: _reserva())
    tareas = BackgroundTasks()
    rutas.cancelar(_perfil(), cast(Any, None), _id(9), tareas, cast(Any, None))
    rutas.modificar(
        rutas.PedidoDeCambioDeReserva(espacio_id=cast(Any, _id(2)), fecha=date(2026, 10, 28), desde="20:00"),
        _perfil(),
        cast(Any, None),
        _id(9),
    )
    _correr(tareas)
    assert enviados == []


class _Repositorio:
    def __init__(self) -> None:
        self.registrados: set[UUID] = set()

    def vencidos(self, ahora: datetime, usuario_id: UUID | None) -> list[Recordatorio]:
        return [_recordatorio()]

    def registrar(self, recordatorio: Recordatorio, aviso: Aviso) -> UUID | None:
        if recordatorio.reserva_id in self.registrados:
            return None
        self.registrados.add(recordatorio.reserva_id)
        return _id(50)

    def tokens_con_permiso(self, usuario_id: UUID) -> list[str]:
        return ["token"]

    def marcar_envio(self, notificacion_id: UUID, envio: str) -> None: ...

    def dar_de_baja_tokens(self, tokens: Sequence[str]) -> None: ...


class _Canal:
    def __init__(self) -> None:
        self.avisos: list[Aviso] = []

    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        self.avisos.append(aviso)
        return ResultadoDeEnvio(enviados=1)


def test_el_recordatorio_de_una_hora_antes_sale_por_push_y_por_correo_una_sola_vez(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """el recordatorio de una hora antes sale por push y por correo, una sola vez
    @MAIL-02-S4"""
    from app.modules.notificaciones import casos_de_uso

    enviados: list[Mensaje] = []
    monkeypatch.setattr(casos_de_uso, "enviar", enviados.append)
    repo, canal = _Repositorio(), _Canal()
    ahora = datetime(2026, 10, 1, 23, 0, tzinfo=UTC)

    assert enviar_recordatorios(cast(Any, repo), canal, ahora) == 1
    assert enviar_recordatorios(cast(Any, repo), canal, ahora) == 0

    assert len(canal.avisos) == 1
    assert len(enviados) == 1
    assert enviados[0].para == DIRECCION
    assert enviados[0].asunto == "Tu reserva es en 1 hora"
    assert enviados[0].html is not None
    for dato in ("Fútbol 5", "Sede Morón", "21:00", "22:00"):
        assert dato in enviados[0].cuerpo
        assert dato in enviados[0].html


def test_si_el_correo_del_recordatorio_falla_el_push_sale_igual(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    """si el correo del recordatorio falla el push sale igual
    @assumption:MAIL-02-ASM-04"""
    from app.modules.notificaciones import casos_de_uso

    def roto(mensaje: Mensaje) -> None:
        raise RuntimeError(f"no se pudo enviar a {mensaje.para}")

    monkeypatch.setattr(casos_de_uso, "enviar", roto)
    canal = _Canal()
    with caplog.at_level(logging.WARNING):
        registrados = enviar_recordatorios(
            cast(Any, _Repositorio()), canal, datetime(2026, 10, 1, 23, 0, tzinfo=UTC)
        )

    assert registrados == 1
    assert len(canal.avisos) == 1
    assert "RuntimeError" in caplog.text
    assert DIRECCION not in caplog.text
