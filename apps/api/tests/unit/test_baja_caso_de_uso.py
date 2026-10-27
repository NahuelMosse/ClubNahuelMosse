from datetime import date
from uuid import UUID

import pytest

from app.modules.sesion.perfil import Perfil, Rol
from app.modules.usuarios.baja import dar_de_baja
from app.shared.errores import Prohibido


def _perfil(rol: Rol = "usuario") -> Perfil:
    return Perfil(
        id=UUID(int=7),
        uid="u7",
        nombre="Lucía",
        apellido="Gómez",
        correo="lucia@correo.com",
        rol=rol,
        dni="30111222",
        fecha_nacimiento=date(1998, 11, 2),
    )


class Cuentas:
    def __init__(self) -> None:
        self.bajas: list[UUID] = []
        self.borradas: list[str] = []
        self.falla_proveedor = False

    def dar_de_baja(self, id_usuario: UUID) -> bool:
        if id_usuario in self.bajas:
            return False
        self.bajas.append(id_usuario)
        return True

    def borrar_cuenta(self, uid: str) -> None:
        if self.falla_proveedor:
            raise RuntimeError("Firebase no contesta")
        self.borradas.append(uid)


def test_da_de_baja_y_borra_la_cuenta_del_proveedor() -> None:
    cuentas = Cuentas()
    dar_de_baja(_perfil(), cuentas, cuentas)
    assert (cuentas.bajas, cuentas.borradas) == ([UUID(int=7)], ["u7"])


def test_si_el_proveedor_falla_la_baja_igual_queda_hecha(
    caplog: pytest.LogCaptureFixture,
) -> None:
    cuentas = Cuentas()
    cuentas.falla_proveedor = True
    dar_de_baja(_perfil(), cuentas, cuentas)
    assert cuentas.bajas == [UUID(int=7)]
    assert "no se pudo borrar del proveedor" in caplog.text


def test_una_cuenta_que_ya_estaba_de_baja_no_toca_el_proveedor() -> None:
    cuentas = Cuentas()
    dar_de_baja(_perfil(), cuentas, cuentas)
    dar_de_baja(_perfil(), cuentas, cuentas)
    assert (cuentas.bajas, cuentas.borradas) == ([UUID(int=7)], ["u7"])


def test_un_administrador_no_se_da_de_baja() -> None:
    """Verifica CU-07-SUP-03."""
    cuentas = Cuentas()
    with pytest.raises(Prohibido):
        dar_de_baja(_perfil("admin"), cuentas, cuentas)
    assert cuentas.bajas == []
