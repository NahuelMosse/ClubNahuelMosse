from dataclasses import replace
from datetime import date, time
from typing import Any
from uuid import UUID

import pytest

from app.modules.sedes.casos_de_uso import dar_de_alta_sede
from app.modules.sedes.reglas import DatosSede, Sede, SedeNueva, validar_sede
from app.modules.sesion.perfil import Perfil, Rol
from app.shared.errores import DatosInvalidos, Prohibido

VALIDOS = DatosSede(
    nombre="Sede Haedo",
    direccion="Av. Vergara 1850",
    apertura=time(8),
    cierre=time(23),
    dias=(1, 2, 3, 4, 5, 6, 7),
)


def _errores(**cambios: Any) -> dict[str, str]:
    sede, errores = validar_sede(replace(VALIDOS, **cambios))
    assert sede is None
    return errores


def test_una_sede_completa_separa_calle_y_altura() -> None:
    sede, errores = validar_sede(replace(VALIDOS, nombre="  Sede   Haedo ", dias=(7, 1, 1)))
    assert errores == {}
    assert sede == SedeNueva(
        nombre="Sede Haedo",
        calle="Av. Vergara",
        altura=1850,
        apertura=time(8),
        cierre=time(23),
        dias=(1, 7),
    )


def test_cada_campo_vacio_tiene_su_mensaje() -> None:
    assert _errores(nombre=" ", direccion="", apertura=None, cierre=None, dias=()) == {
        "nombre": "El nombre es obligatorio",
        "direccion": "La dirección es obligatoria",
        "apertura": "El horario de apertura es obligatorio",
        "cierre": "El horario de cierre es obligatorio",
        "dias": "Elegí los días que abre",
    }


@pytest.mark.parametrize("direccion", ["Av. Vergara", "1850", "Vergara 0", "Vergara 18a"])
def test_la_direccion_termina_en_la_altura(direccion: str) -> None:
    assert _errores(direccion=direccion) == {"direccion": "Escribí la calle y la altura"}


def test_los_largos_tienen_tope() -> None:
    assert _errores(nombre="x" * 61, direccion="y" * 76 + " 1850") == {
        "nombre": "Usá hasta 60 caracteres",
        "direccion": "Usá hasta 80 caracteres",
    }
    sede, _ = validar_sede(replace(VALIDOS, nombre="x" * 60, direccion="y" * 75 + " 1850"))
    assert sede is not None


def test_el_cierre_va_despues_de_la_apertura() -> None:
    mensaje = {"cierre": "El cierre tiene que ser después de la apertura"}
    assert _errores(apertura=time(10), cierre=time(9)) == mensaje
    assert _errores(apertura=time(10), cierre=time(10)) == mensaje


def test_cerrar_a_las_00_es_la_medianoche() -> None:
    sede, errores = validar_sede(replace(VALIDOS, apertura=time(18), cierre=time(0)))
    assert errores == {}
    assert sede is not None


def test_las_horas_son_en_punto() -> None:
    assert _errores(apertura=time(8, 30), cierre=time(22, 15)) == {
        "apertura": "Elegí una hora en punto",
        "cierre": "Elegí una hora en punto",
    }


def test_los_dias_son_de_la_semana() -> None:
    assert _errores(dias=(0, 1)) == {"dias": "Elegí los días que abre"}
    assert _errores(dias=(8,)) == {"dias": "Elegí los días que abre"}


def _perfil(rol: Rol) -> Perfil:
    return Perfil(
        id=UUID(int=7),
        uid="uid",
        nombre="Ana",
        apellido="Díaz",
        correo="ana@club.com",
        rol=rol,
        dni="20000001",
        fecha_nacimiento=date(1985, 6, 1),
    )


class _SedesEnMemoria:
    def __init__(self) -> None:
        self.guardadas: list[tuple[SedeNueva, UUID]] = []

    def activas(self) -> list[Sede]:
        return []

    def insertar(self, nueva: SedeNueva, autor: UUID) -> Sede:
        self.guardadas.append((nueva, autor))
        return Sede(UUID(int=1), nueva.nombre, nueva.calle, nueva.altura, nueva.apertura,
                    nueva.cierre, nueva.dias, 0)  # fmt: skip

    def actualizar(self, sede_id: UUID, datos: SedeNueva, autor: UUID, confirmar: bool) -> Sede:
        raise NotImplementedError

    def dar_de_baja(self, sede_id: UUID, autor: UUID) -> None:
        raise NotImplementedError


def test_el_alta_queda_a_nombre_del_administrador() -> None:
    sedes = _SedesEnMemoria()
    sede = dar_de_alta_sede(_perfil("admin"), VALIDOS, sedes)
    assert sede.nombre == "Sede Haedo"
    assert [autor for _, autor in sedes.guardadas] == [UUID(int=7)]


def test_un_usuario_no_da_de_alta_sedes() -> None:
    sedes = _SedesEnMemoria()
    with pytest.raises(Prohibido):
        dar_de_alta_sede(_perfil("usuario"), VALIDOS, sedes)
    assert sedes.guardadas == []


def test_con_datos_invalidos_no_se_guarda_nada() -> None:
    sedes = _SedesEnMemoria()
    with pytest.raises(DatosInvalidos) as e:
        dar_de_alta_sede(_perfil("admin"), replace(VALIDOS, direccion=""), sedes)
    assert e.value.errores == {"direccion": "La dirección es obligatoria"}
    assert sedes.guardadas == []


def test_la_altura_es_de_digitos_comunes() -> None:
    assert _errores(direccion="Calle ١٢٣") == {"direccion": "Escribí la calle y la altura"}


def test_nombre_y_calle_tienen_que_aportar_al_nombre_de_los_espacios() -> None:
    assert _errores(nombre="Sede") == {"nombre": "Escribí el nombre de la sede"}
    assert _errores(direccion="Av. 100") == {"direccion": "Escribí la calle y la altura"}
