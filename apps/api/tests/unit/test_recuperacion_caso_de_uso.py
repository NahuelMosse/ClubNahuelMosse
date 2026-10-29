from uuid import UUID

import pytest

from app.modules.password_recovery.rules import ClaimedLink as EnlaceReclamado
from app.modules.password_recovery.rules import Recipient as Destinatario
from app.modules.password_recovery.use_cases import (
    MAX_PER_HOUR as MAXIMO_POR_HORA,
)
from app.modules.password_recovery.use_cases import (
    VALIDITY_MINUTES as VIGENCIA_MINUTOS,
)
from app.modules.password_recovery.use_cases import (
    InvalidLink as EnlaceInvalido,
)
from app.modules.password_recovery.use_cases import (
    hash_of as hash_de,
)
from app.modules.password_recovery.use_cases import (
    request_link as pedir_enlace,
)
from app.modules.password_recovery.use_cases import (
    use_link as usar_enlace,
)
from app.shared.errors import InvalidData

LUCIA = Destinatario(UUID(int=7), "Lucía", "lucia@correo.com")
URL = "https://api.club.com/"


class Enlaces:
    def __init__(self, emitidos: int = 0, vigentes: set[str] | None = None) -> None:
        self.emitidos = emitidos
        self.emisiones: list[tuple[UUID, str, int]] = []
        self.vigentes = vigentes or set()
        self.liberados: list[UUID] = []

    def recipient(self, correo: str) -> Destinatario | None:
        return LUCIA if correo == LUCIA.email else None

    def issue(
        self, user_id: UUID, code_hash: str, validity_minutes: int, max_per_hour: int
    ) -> bool:
        if self.emitidos >= max_per_hour:
            return False
        self.emisiones.append((user_id, code_hash, validity_minutes))
        return True

    def valid(self, codigo_hash: str) -> bool:
        return codigo_hash in self.vigentes

    def claim(self, codigo_hash: str) -> EnlaceReclamado | None:
        if codigo_hash not in self.vigentes:
            return None
        self.vigentes.discard(codigo_hash)
        return EnlaceReclamado(id=UUID(int=3), user_id=UUID(int=7), uid="u7")

    def release(self, enlace_id: UUID) -> None:
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

    def mark_password_changed(self, id_usuario: UUID) -> None:
        self.marcados.append(id_usuario)


def test_a_una_cuenta_activa_le_toca_un_enlace_https_que_vence_en_media_hora() -> None:
    enlaces = Enlaces()
    mensaje = pedir_enlace("  Lucia@Correo.com ", URL, enlaces)
    assert mensaje is not None
    ((usuario, codigo_hash, vigencia),) = enlaces.emisiones
    assert (usuario, vigencia) == (UUID(int=7), VIGENCIA_MINUTOS)
    assert mensaje.recipient == "lucia@correo.com"
    assert "https://api.club.com/link/recover#code=" in mensaje.body
    codigo = mensaje.body.split("#code=")[1].split()[0]
    # El correo lleva el código y la base guarda sólo su hash.
    assert hash_de(codigo) == codigo_hash and codigo != codigo_hash


def test_un_correo_sin_cuenta_no_recibe_nada_y_no_da_error() -> None:
    enlaces = Enlaces()
    assert pedir_enlace("nadie@correo.com", URL, enlaces) is None
    assert enlaces.emisiones == []


def test_despues_del_tope_por_hora_no_se_envian_mas() -> None:
    """Verifica CU-04b-SUP-02."""
    enlaces = Enlaces(emitidos=MAXIMO_POR_HORA)
    assert pedir_enlace(LUCIA.email, URL, enlaces) is None
    assert enlaces.emisiones == []


def test_un_correo_mal_escrito_se_rechaza() -> None:
    with pytest.raises(InvalidData) as error:
        pedir_enlace("lucia@correo", URL, Enlaces())
    assert error.value.errors == {"email": "Revisá el formato del correo"}


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
    assert error.value.errors == {"new_password": "Al menos 8 caracteres"}
    assert hash_de("abc") in enlaces.vigentes
