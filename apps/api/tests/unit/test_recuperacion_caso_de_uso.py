from uuid import UUID

import pytest

from app.modules.recuperacion.casos_de_uso import (
    MAXIMO_POR_HORA,
    VIGENCIA_MINUTOS,
    EnlaceInvalido,
    hash_de,
    pedir_enlace,
    usar_enlace,
)
from app.modules.recuperacion.reglas import Destinatario, EnlaceReclamado
from app.shared.errors import InvalidData

LUCIA = Destinatario(UUID(int=7), "Lucía", "lucia@correo.com")
URL = "https://api.club.com/"


class Enlaces:
    def __init__(self, emitidos: int = 0, vigentes: set[str] | None = None) -> None:
        self.emitidos = emitidos
        self.emisiones: list[tuple[UUID, str, int]] = []
        self.vigentes = vigentes or set()
        self.liberados: list[UUID] = []

    def destinatario(self, correo: str) -> Destinatario | None:
        return LUCIA if correo == LUCIA.correo else None

    def emitir(
        self, usuario_id: UUID, codigo_hash: str, vigencia_minutos: int, maximo_por_hora: int
    ) -> bool:
        if self.emitidos >= maximo_por_hora:
            return False
        self.emisiones.append((usuario_id, codigo_hash, vigencia_minutos))
        return True

    def vigente(self, codigo_hash: str) -> bool:
        return codigo_hash in self.vigentes

    def reclamar(self, codigo_hash: str) -> EnlaceReclamado | None:
        if codigo_hash not in self.vigentes:
            return None
        self.vigentes.discard(codigo_hash)
        return EnlaceReclamado(id=UUID(int=3), usuario_id=UUID(int=7), uid="u7")

    def liberar(self, enlace_id: UUID) -> None:
        self.liberados.append(enlace_id)


class Identidad:
    def __init__(self, falla: bool = False) -> None:
        self.cambios: list[tuple[str, str]] = []
        self.falla = falla

    def change_password(self, uid: str, new_password: str) -> None:
        if self.falla:
            raise RuntimeError("Firebase no contesta")
        self.cambios.append((uid, new_password))


class Rastro:
    def __init__(self) -> None:
        self.marcados: list[UUID] = []

    def marcar_cambio_de_contrasena(self, id_usuario: UUID) -> None:
        self.marcados.append(id_usuario)


def test_a_una_cuenta_activa_le_toca_un_enlace_https_que_vence_en_media_hora() -> None:
    enlaces = Enlaces()
    mensaje = pedir_enlace("  Lucia@Correo.com ", URL, enlaces)
    assert mensaje is not None
    ((usuario, codigo_hash, vigencia),) = enlaces.emisiones
    assert (usuario, vigencia) == (UUID(int=7), VIGENCIA_MINUTOS)
    assert mensaje.para == "lucia@correo.com"
    assert "https://api.club.com/enlace/recuperar#codigo=" in mensaje.cuerpo
    codigo = mensaje.cuerpo.split("#codigo=")[1].split()[0]
    # El correo lleva el código y la base guarda sólo su hash.
    assert hash_de(codigo) == codigo_hash and codigo != codigo_hash


def test_un_correo_sin_cuenta_no_recibe_nada_y_no_da_error() -> None:
    enlaces = Enlaces()
    assert pedir_enlace("nadie@correo.com", URL, enlaces) is None
    assert enlaces.emisiones == []


def test_despues_del_tope_por_hora_no_se_envian_mas() -> None:
    """Verifica CU-04b-SUP-02."""
    enlaces = Enlaces(emitidos=MAXIMO_POR_HORA)
    assert pedir_enlace(LUCIA.correo, URL, enlaces) is None
    assert enlaces.emisiones == []


def test_un_correo_mal_escrito_se_rechaza() -> None:
    with pytest.raises(InvalidData) as error:
        pedir_enlace("lucia@correo", URL, Enlaces())
    assert error.value.errors == {"correo": "Revisá el formato del correo"}


def test_con_un_enlace_vigente_cambia_la_contrasena_y_deja_rastro() -> None:
    enlaces, identidad, rastro = Enlaces(vigentes={hash_de("abc")}), Identidad(), Rastro()
    usar_enlace("abc", "ClubNahuel2", enlaces, identidad, rastro)
    assert identidad.cambios == [("u7", "ClubNahuel2")]
    assert rastro.marcados == [UUID(int=7)]
    # El enlace ya no sirve para una segunda vez.
    with pytest.raises(EnlaceInvalido):
        usar_enlace("abc", "ClubNahuel3", enlaces, identidad, rastro)


def test_si_firebase_falla_el_enlace_se_libera() -> None:
    enlaces = Enlaces(vigentes={hash_de("abc")})
    with pytest.raises(RuntimeError):
        usar_enlace("abc", "ClubNahuel2", enlaces, Identidad(falla=True), Rastro())
    assert enlaces.liberados == [UUID(int=3)]


def test_una_contrasena_debil_no_gasta_el_enlace() -> None:
    enlaces = Enlaces(vigentes={hash_de("abc")})
    with pytest.raises(InvalidData) as error:
        usar_enlace("abc", "corta", enlaces, Identidad(), Rastro())
    assert error.value.errors == {"nueva": "Al menos 8 caracteres"}
    assert hash_de("abc") in enlaces.vigentes
