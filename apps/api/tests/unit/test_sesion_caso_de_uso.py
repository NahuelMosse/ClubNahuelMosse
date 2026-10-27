from datetime import date
from uuid import UUID

import pytest

from app.modules.sesion.casos_de_uso import perfil_autenticado
from app.modules.sesion.perfil import Perfil
from app.shared.errores import NoAutenticado

PERFIL = Perfil(
    id=UUID(int=7),
    uid="u",
    nombre="Lucía",
    apellido="Gómez",
    correo="lucia@correo.com",
    rol="usuario",
    dni="30111222",
    fecha_nacimiento=date(1998, 11, 2),
)


class Tokens:
    def __init__(self, validos: dict[str, str]) -> None:
        self.validos = validos
        self.consultados: list[str] = []

    def uid_del_token(self, token: str) -> str | None:
        self.consultados.append(token)
        return self.validos.get(token)


class Perfiles:
    def __init__(self, activos: dict[str, Perfil]) -> None:
        self.activos = activos

    def perfil_activo(self, uid: str) -> Perfil | None:
        return self.activos.get(uid)


def test_un_token_valido_de_una_cuenta_activa_da_su_perfil() -> None:
    assert perfil_autenticado("t", Tokens({"t": "u"}), Perfiles({"u": PERFIL})) == PERFIL


@pytest.mark.parametrize("token", [None, ""])
def test_sin_token_no_se_consulta_al_proveedor(token: str | None) -> None:
    tokens = Tokens({})
    with pytest.raises(NoAutenticado):
        perfil_autenticado(token, tokens, Perfiles({}))
    assert tokens.consultados == []


def test_un_token_invalido_no_autentica() -> None:
    with pytest.raises(NoAutenticado):
        perfil_autenticado("vencido", Tokens({}), Perfiles({"u": PERFIL}))


def test_una_cuenta_sin_perfil_activo_no_autentica() -> None:
    with pytest.raises(NoAutenticado):
        perfil_autenticado("t", Tokens({"t": "u"}), Perfiles({}))
