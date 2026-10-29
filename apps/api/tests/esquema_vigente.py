"""El esquema vigente es el de la 0012: este módulo traduce los nombres de las migraciones
anteriores (tablas, columnas, valores guardados) a los que tiene la base en la cabeza."""

import importlib.util
from pathlib import Path
from types import ModuleType

_RUTA = Path(__file__).resolve().parents[1] / "migrations" / "versions" / "0012_english_schema.py"


def _cargar() -> ModuleType:
    spec = importlib.util.spec_from_file_location("migracion_0012", _RUTA)
    assert spec is not None and spec.loader is not None
    modulo = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(modulo)
    return modulo


_M = _cargar()


def tabla(vieja: str) -> str:
    """El nombre vigente de una tabla (el mismo si ya es vigente)."""
    return str(_M.TABLES.get(vieja, vieja))


def columna(tabla_vieja: str, vieja: str) -> str:
    """El nombre vigente de la columna `vieja` de la tabla `tabla_vieja`."""
    if tabla_vieja not in _M.TABLES:
        return vieja
    return str(_M._columns_of(tabla_vieja).get(vieja, vieja))


def valor(viejo: str) -> str:
    """El valor guardado vigente (el mismo si no cambió)."""
    return str(_M.VALUES.get(viejo, viejo))


def vigentes(tablas: dict[str, set[str]]) -> dict[str, set[str]]:
    """Las columnas de cada tabla con los nombres que tienen tras la 0012."""
    return {tabla(t): {columna(t, c) for c in columnas} for t, columnas in tablas.items()}


def nombres() -> set[str]:
    """Todo nombre que la 0012 le da a la base, también los que arma en vez de escribirlos."""
    movimiento = _M.TO_ENGLISH
    dados = {*movimiento.tables.values(), *movimiento.functions.values()}
    dados |= {*movimiento.triggers.values(), *movimiento.indexes.values()}
    dados |= {*movimiento.constraints.values(), *movimiento.views.values()}
    for columnas in movimiento.columns.values():
        dados |= set(columnas.values())
    return dados
