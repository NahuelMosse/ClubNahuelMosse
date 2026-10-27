from collections.abc import Callable
from dataclasses import replace
from datetime import date
from typing import Any
from uuid import UUID

import pytest

from app.modules.sesion.perfil import Perfil, Rol
from app.modules.spaces.rules import (
    CATALOG,
    NewSpace,
    Space,
    SpaceChange,
    SpaceData,
    SpaceVenue,
    SuggestedName,
    validate_space,
)
from app.modules.spaces.use_cases import create_space, suggested_name
from app.shared.errors import Forbidden, InvalidData, Unavailable

VALIDOS = SpaceData(
    venue_id=UUID(int=3),
    sport="Futbol",
    kind="F5",
    covered=False,
    lit=True,
    price_per_hour=38000,
)


def _errores(**cambios: Any) -> dict[str, str]:
    espacio, errores = validate_space(replace(VALIDOS, **cambios))
    assert espacio is None
    return errores


def test_un_espacio_completo_se_puede_guardar() -> None:
    espacio, errores = validate_space(VALIDOS)
    assert errores == {}
    assert espacio == NewSpace(UUID(int=3), "Futbol", "F5", False, True, 38000)


def test_cada_campo_que_falta_es_obligatorio() -> None:
    vacio = SpaceData(None, "", "", None, None, None)
    _, errores = validate_space(vacio)
    assert errores == dict.fromkeys(
        ["sede_id", "deporte", "tipo", "techada", "iluminada", "precio_por_hora"],
        "Este campo es obligatorio",
    )


def test_deporte_y_tipo_salen_del_catalogo() -> None:
    assert _errores(sport="Rugby") == {"deporte": "Elegí un deporte de la lista"}
    assert _errores(kind="PDL") == {"tipo": "Elegí un tipo de la lista"}


@pytest.mark.parametrize("precio", [0, -1, 10_000_000])
def test_el_precio_es_positivo_y_con_tope(precio: int) -> None:
    assert _errores(price_per_hour=precio) == {
        "precio_por_hora": "Ingresá un precio entre $ 1 y $ 9.999.999"
    }


def test_el_catalogo_no_repite_claves() -> None:
    claves = [d.key for d in CATALOG]
    assert len(claves) == len(set(claves))
    for d in CATALOG:
        tipos = [t.key for t in d.kinds]
        assert tipos and len(tipos) == len(set(tipos))


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


class _EspaciosEnMemoria:
    def __init__(self, sede: SpaceVenue | None) -> None:
        self.sede = sede
        self.guardados: list[tuple[NewSpace, int | None, str, UUID]] = []

    def active(
        self,
        venue_id: UUID | None = None,
        sport: str | None = None,
        kind: str | None = None,
    ) -> list[Space]:
        return []

    def next_number(
        self,
        venue_id: UUID,
        sport: str,
        kind: str,
        name: Callable[[SpaceVenue, int], str],
    ) -> SuggestedName | None:
        return None if self.sede is None else SuggestedName(name(self.sede, 3), 3)

    def insert(
        self,
        new: NewSpace,
        number: int | None,
        name: Callable[[SpaceVenue, int], str],
        author: UUID,
    ) -> Space:
        assert self.sede is not None
        compuesto = name(self.sede, 3)
        self.guardados.append((new, number, compuesto, author))
        return Space(UUID(int=1), compuesto, new.venue_id, self.sede.name, new.sport,
                     new.kind, 3, new.covered, new.lit,
                     new.price_per_hour)  # fmt: skip

    def update(self, space_id: UUID, change: SpaceChange, author: UUID) -> Space:
        raise NotImplementedError

    def deactivate(self, space_id: UUID, author: UUID) -> None:
        raise NotImplementedError


MORON = SpaceVenue("Sede Morón", "Av. Rivadavia", 19850)


def test_el_nombre_sugerido_es_el_del_enunciado_con_el_numero_siguiente() -> None:
    s = suggested_name(_perfil("admin"), UUID(int=3), "Futbol", "F5", _EspaciosEnMemoria(MORON))
    assert (s.name, s.number) == ("Moron_Rivadavia_19850_Futbol_F5_3", 3)


def test_sin_sede_activa_no_hay_nombre() -> None:
    with pytest.raises(Unavailable):
        suggested_name(_perfil("admin"), UUID(int=3), "Futbol", "F5", _EspaciosEnMemoria(None))


def test_el_alta_queda_a_nombre_del_administrador_con_el_nombre_compuesto() -> None:
    espacios = _EspaciosEnMemoria(MORON)
    espacio = create_space(_perfil("admin"), VALIDOS, 3, espacios)
    assert espacio.name == "Moron_Rivadavia_19850_Futbol_F5_3"
    assert [(n, a) for _, n, _, a in espacios.guardados] == [(3, UUID(int=7))]


def test_un_usuario_no_gestiona_espacios() -> None:
    espacios = _EspaciosEnMemoria(MORON)
    with pytest.raises(Forbidden):
        create_space(_perfil("usuario"), VALIDOS, None, espacios)
    with pytest.raises(Forbidden):
        suggested_name(_perfil("usuario"), UUID(int=3), "Futbol", "F5", espacios)
    assert espacios.guardados == []


def test_con_datos_invalidos_no_se_guarda_nada() -> None:
    espacios = _EspaciosEnMemoria(MORON)
    with pytest.raises(InvalidData):
        create_space(_perfil("admin"), replace(VALIDOS, kind=""), None, espacios)
    assert espacios.guardados == []
