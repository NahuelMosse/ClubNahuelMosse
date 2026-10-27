from datetime import date
from uuid import UUID

import pytest

from app.modules.session.profile import Profile
from app.modules.session.use_cases import authenticated_profile as perfil_autenticado
from app.shared.errors import NotAuthenticated

PERFIL = Profile(
    id=UUID(int=7),
    uid="u",
    first_name="Lucía",
    last_name="Gómez",
    email="lucia@correo.com",
    role="usuario",
    dni="30111222",
    birth_date=date(1998, 11, 2),
)


class Tokens:
    def __init__(self, validos: dict[str, str]) -> None:
        self.validos = validos
        self.consultados: list[str] = []

    def uid_from_token(self, token: str) -> str | None:
        self.consultados.append(token)
        return self.validos.get(token)


class Perfiles:
    def __init__(self, activos: dict[str, Profile]) -> None:
        self.activos = activos

    def active_profile(self, uid: str) -> Profile | None:
        return self.activos.get(uid)


def test_un_token_valido_de_una_cuenta_activa_da_su_perfil() -> None:
    assert perfil_autenticado("t", Tokens({"t": "u"}), Perfiles({"u": PERFIL})) == PERFIL


@pytest.mark.parametrize("token", [None, ""])
def test_sin_token_no_se_consulta_al_proveedor(token: str | None) -> None:
    tokens = Tokens({})
    with pytest.raises(NotAuthenticated):
        perfil_autenticado(token, tokens, Perfiles({}))
    assert tokens.consultados == []


def test_un_token_invalido_no_autentica() -> None:
    with pytest.raises(NotAuthenticated):
        perfil_autenticado("vencido", Tokens({}), Perfiles({"u": PERFIL}))


def test_una_cuenta_sin_perfil_activo_no_autentica() -> None:
    with pytest.raises(NotAuthenticated):
        perfil_autenticado("t", Tokens({"t": "u"}), Perfiles({}))
