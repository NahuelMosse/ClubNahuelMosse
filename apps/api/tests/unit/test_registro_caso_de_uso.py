from datetime import date

import pytest

from app.modules.usuarios.registro import registrar
from app.modules.usuarios.reglas import DatosRegistro, Registro
from app.shared.errores import Duplicado

DATOS = DatosRegistro("Ana", "Pérez", "12345678", "2000-03-14", "ana@correo.com", "ClubNahuel1")
HOY = date(2026, 11, 12)


class Identidad:
    def __init__(self, existente: str | None = None, falla_borrar: bool = False) -> None:
        self.cuentas: dict[str, str] = {} if existente is None else {"ana@correo.com": existente}
        self.borradas: list[str] = []
        self.falla_borrar = falla_borrar

    def crear_cuenta(self, correo: str, contrasena: str) -> str:
        if correo in self.cuentas:
            raise Duplicado(["correo"])
        self.cuentas[correo] = f"uid-{len(self.cuentas) + len(self.borradas)}"
        return self.cuentas[correo]

    def uid_de(self, correo: str) -> str | None:
        return self.cuentas.get(correo)

    def borrar_cuenta(self, uid: str) -> None:
        if self.falla_borrar:
            raise RuntimeError("el proveedor no responde")
        self.borradas.append(uid)
        self.cuentas = {c: u for c, u in self.cuentas.items() if u != uid}


class Usuarios:
    def __init__(self, activos: set[str] | None = None, falla: BaseException | None = None) -> None:
        self.activos = activos or set()
        self.falla = falla
        self.insertados: list[str] = []

    def duplicados(self, correo: str, dni: str) -> list[str]:
        return []

    def uid_activo(self, uid: str) -> bool:
        return uid in self.activos

    def insertar(self, uid: str, registro: Registro) -> int:
        if self.falla is not None:
            raise self.falla
        self.insertados.append(uid)
        return 1


def test_si_falla_el_alta_se_borra_la_cuenta_creada() -> None:
    identidad = Identidad()
    with pytest.raises(ConnectionError):
        registrar(DATOS, HOY, identidad, Usuarios(falla=ConnectionError("se cortó la base")))
    assert identidad.borradas == ["uid-0"]


def test_un_error_al_borrar_no_tapa_el_error_original() -> None:
    identidad = Identidad(falla_borrar=True)
    with pytest.raises(Duplicado) as e:
        registrar(DATOS, HOY, identidad, Usuarios(falla=Duplicado(["dni"])))
    assert e.value.campos == ["dni"]


def test_una_cuenta_del_proveedor_sin_perfil_activo_se_reemplaza() -> None:
    identidad = Identidad(existente="uid-viejo")
    usuarios = Usuarios()
    assert registrar(DATOS, HOY, identidad, usuarios) == 1
    assert identidad.borradas == ["uid-viejo"]
    assert usuarios.insertados == [identidad.cuentas["ana@correo.com"]]


def test_una_cuenta_con_perfil_activo_sigue_siendo_duplicado() -> None:
    identidad = Identidad(existente="uid-activo")
    with pytest.raises(Duplicado):
        registrar(DATOS, HOY, identidad, Usuarios(activos={"uid-activo"}))
    assert identidad.borradas == []
