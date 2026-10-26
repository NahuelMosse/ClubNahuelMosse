import logging
from datetime import datetime

from app.aplicacion.almacen_de_avisos import Notificaciones
from app.aplicacion.errores import DatosInvalidos, NoDisponible, NoEncontrada, Prohibido
from app.dominio.notificaciones import (
    Aviso,
    Notificacion,
    mensaje_recordatorio,
)
from app.dominio.notificaciones import (
    CanalNoConfigurado as CanalNoConfigurado,
)
from app.dominio.notificaciones import (
    CanalPush as CanalPush,
)
from app.dominio.notificaciones import (
    Pendiente as Pendiente,
)
from app.dominio.notificaciones import (
    ResultadoDeEnvio as ResultadoDeEnvio,
)
from app.dominio.usuarios import Perfil

PLATAFORMAS = ("android", "ios")

_registro = logging.getLogger(__name__)


def entregar(
    notificaciones: Notificaciones,
    canal: CanalPush,
    notificacion_id: int,
    usuario_id: int,
    aviso: Aviso,
) -> None:
    """Manda un aviso ya registrado a los teléfonos con permiso y deja anotado cómo salió.

    Sin ningún dispositivo con permiso queda sólo en el centro: `sin_permiso` si hay
    dispositivos que no lo dieron y `sin_canal` si no hay ninguno al que mandarlo, igual que
    cuando no hay servicio de envío. Un envío que falla no se reintenta desde acá: queda
    marcado como fallido.
    """
    tokens = notificaciones.tokens_con_permiso(usuario_id)
    if not tokens:
        hay_dispositivos = notificaciones.tiene_dispositivos(usuario_id)
        notificaciones.marcar_envio(
            notificacion_id, "sin_permiso" if hay_dispositivos else "sin_canal"
        )
        return
    try:
        resultado = canal.enviar(tokens, aviso)
    except CanalNoConfigurado:
        notificaciones.marcar_envio(notificacion_id, "sin_canal")
        return
    except Exception as e:
        # El servicio de afuera puede fallar de cualquier forma; el aviso ya está en el
        # centro y un envío no puede cortar el de otra persona. Se loguea el tipo del error
        # y no su texto, que puede traer el token del teléfono.
        _registro.error(
            "aviso_sin_enviar notificacion=%s error=%s", notificacion_id, type(e).__name__
        )
        notificaciones.marcar_envio(notificacion_id, "fallida")
        return
    notificaciones.dar_de_baja_tokens(resultado.invalidos)
    notificaciones.marcar_envio(notificacion_id, "enviada" if resultado.enviados > 0 else "fallida")


def despachar_pendientes(
    notificaciones: Notificaciones, canal: CanalPush, usuario_id: int | None = None
) -> int:
    """Manda los avisos que se registraron junto con el hecho que avisan, como la confirmación
    de una cancelación, y devuelve cuántos salieron a despacho. Retoma los que quedaron
    `enviando` por un proceso caído y los recordatorios registrados que no salieron.

    Toma de a uno: lo que no se intentó sigue `pendiente`, y un aviso que falla por cualquier
    motivo queda `fallida` sin cortar los que siguen. Antes de tomar, los que no van a salir
    quedan `fallida` y se avisan en el log como `aviso_sin_enviar`.
    """
    for perdido in notificaciones.marcar_varados_fallidos(usuario_id):
        # Sólo el número y el tipo: nada de la persona ni del texto del aviso.
        _registro.error(
            "aviso_sin_enviar notificacion_id=%d tipo=%s", perdido.notificacion_id, perdido.tipo
        )
    despachados = 0
    while (p := notificaciones.tomar_siguiente(usuario_id)) is not None:
        despachados += 1
        try:
            entregar(notificaciones, canal, p.notificacion_id, p.usuario_id, p.aviso)
        except Exception as e:
            _registro.error(
                "aviso_sin_enviar notificacion=%s error=%s", p.notificacion_id, type(e).__name__
            )
            notificaciones.marcar_envio(p.notificacion_id, "fallida")
    return despachados


def enviar_recordatorios(
    notificaciones: Notificaciones,
    canal: CanalPush,
    ahora: datetime,
    usuario_id: int | None = None,
) -> int:
    """Registra y envía el aviso de una hora antes de cada reserva a la que ya le toca, y
    devuelve cuántos registró.

    El aviso se registra antes de enviarlo: el índice único de la base hace que dos barridos
    al mismo tiempo no lo manden dos veces.
    """
    registrados = 0
    for recordatorio in notificaciones.vencidos(ahora, usuario_id):
        try:
            aviso = mensaje_recordatorio(recordatorio)
            nuevo = notificaciones.registrar(recordatorio, aviso)
            if nuevo is None:
                continue
            registrados += 1
            entregar(notificaciones, canal, nuevo, recordatorio.usuario_id, aviso)
        except Exception as e:
            # El recordatorio de una persona no corta el de las demás.
            _registro.warning("el recordatorio falló: %s", type(e).__name__)
    return registrados


def registrar_dispositivo(
    notificaciones: Notificaciones, perfil: Perfil, token: str, plataforma: str, permiso: bool
) -> None:
    """Registra el teléfono de quien pide, con el permiso que le dio al sistema operativo.

    Lanza `Prohibido` si es administrador, `DatosInvalidos` si falta el token o la plataforma
    no existe y `NoDisponible` si la cuenta ya no está activa.
    """
    if perfil.rol != "usuario":
        raise Prohibido("sólo un usuario recibe avisos")
    errores: dict[str, str] = {}
    if not token.strip():
        errores["token"] = "Este campo es obligatorio"
    if plataforma not in PLATAFORMAS:
        errores["plataforma"] = "Tiene que ser android o ios"
    if errores:
        raise DatosInvalidos(errores)
    if not notificaciones.registrar_dispositivo(perfil.id, token.strip(), plataforma, permiso):
        raise NoDisponible("la cuenta ya no está activa")


def dar_de_baja_dispositivo(notificaciones: Notificaciones, perfil: Perfil, token: str) -> None:
    """Al cerrar la sesión, el teléfono deja de recibir los avisos de esta cuenta."""
    notificaciones.baja_dispositivo(perfil.id, token.strip())


def mis_notificaciones(
    notificaciones: Notificaciones, perfil: Perfil
) -> tuple[list[Notificacion], int]:
    return notificaciones.de_usuario(perfil.id)


def marcar_leida(notificaciones: Notificaciones, perfil: Perfil, notificacion_id: int) -> None:
    """Lanza `NoEncontrada` si la notificación no es de quien pide."""
    if not notificaciones.leer(perfil.id, notificacion_id):
        raise NoEncontrada("no hay una notificación suya con ese número")


def marcar_todas(notificaciones: Notificaciones, perfil: Perfil) -> None:
    notificaciones.leer_todas(perfil.id)
