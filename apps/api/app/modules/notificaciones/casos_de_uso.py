import logging
from datetime import datetime
from uuid import UUID

from app.modules.notificaciones.almacen import Notificaciones
from app.modules.notificaciones.reglas import Aviso, Notificacion, mensaje_recordatorio
from app.modules.notificaciones.reglas import CanalNoConfigurado as CanalNoConfigurado
from app.modules.notificaciones.reglas import CanalPush as CanalPush
from app.modules.notificaciones.reglas import Pendiente as Pendiente
from app.modules.notificaciones.reglas import ResultadoDeEnvio as ResultadoDeEnvio
from app.modules.session import Profile
from app.shared.errors import Forbidden, InvalidData, NotFound, Unavailable

PLATAFORMAS = ("android", "ios")

_registro = logging.getLogger(__name__)


def entregar(  # noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores
    notificaciones: Notificaciones,
    canal: CanalPush,
    notificacion_id: UUID,
    usuario_id: UUID,
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
    notificaciones: Notificaciones, canal: CanalPush, usuario_id: UUID | None = None
) -> int:
    """Manda los avisos que se registraron junto con el hecho que avisan, como la confirmación
    de una cancelación, y devuelve cuántos salieron a despacho.

    Toma de a uno: lo que no se intentó sigue `pendiente`, y un aviso que falla por cualquier
    motivo queda `fallida` sin cortar los que siguen. Antes de tomar, los que no van a salir
    (un recordatorio que ya no corresponde, o un aviso con más de 10 minutos en `enviando`
    porque la API se cayó a mitad del envío) quedan `fallida`, no se reenvían y se avisan en el
    log como `aviso_sin_enviar`.
    """
    for perdido in notificaciones.marcar_varados_fallidos(usuario_id):
        # Sólo el id y el tipo: nada de la persona ni del texto del aviso.
        _registro.error(
            "aviso_sin_enviar notificacion_id=%s tipo=%s", perdido.notificacion_id, perdido.tipo
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
    usuario_id: UUID | None = None,
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


def registrar_dispositivo(  # noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores
    notificaciones: Notificaciones,
    perfil: Profile,
    token: str,
    plataforma: str,
    permiso: bool,  # noqa: FBT001
) -> None:
    """Registra el teléfono de quien pide, con el permiso que le dio al sistema operativo.

    Lanza `Forbidden` si es administrador, `InvalidData` si falta el token o la plataforma
    no existe y `Unavailable` si la cuenta ya no está activa.
    """
    if perfil.role != "usuario":
        raise Forbidden("sólo un usuario recibe avisos")
    errores: dict[str, str] = {}
    if not token.strip():
        errores["token"] = "Este campo es obligatorio"
    if plataforma not in PLATAFORMAS:
        errores["plataforma"] = "Tiene que ser android o ios"
    if errores:
        raise InvalidData(errores)
    if not notificaciones.registrar_dispositivo(perfil.id, token.strip(), plataforma, permiso):
        raise Unavailable("la cuenta ya no está activa")


def dar_de_baja_dispositivo(notificaciones: Notificaciones, perfil: Profile, token: str) -> None:
    """Al cerrar la sesión, el teléfono deja de recibir los avisos de esta cuenta."""
    notificaciones.baja_dispositivo(perfil.id, token.strip())


def mis_notificaciones(
    notificaciones: Notificaciones, perfil: Profile
) -> tuple[list[Notificacion], int]:
    return notificaciones.de_usuario(perfil.id)


def marcar_leida(notificaciones: Notificaciones, perfil: Profile, notificacion_id: UUID) -> None:
    """Lanza `NotFound` si la notificación no es de quien pide."""
    if not notificaciones.leer(perfil.id, notificacion_id):
        raise NotFound("no hay una notificación suya con ese número")


def marcar_todas(notificaciones: Notificaciones, perfil: Profile) -> None:
    notificaciones.leer_todas(perfil.id)
