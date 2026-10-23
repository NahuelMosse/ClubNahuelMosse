from collections.abc import Callable
from dataclasses import replace
from datetime import date
from typing import Any

import pytest

from app.aplicacion.errores import DatosInvalidos, NoDisponible, Prohibido
from app.aplicacion.espacios import dar_de_alta_espacio, nombre_sugerido
from app.dominio.espacios import (
    CATALOGO,
    CambioDeEspacio,
    DatosEspacio,
    Espacio,
    EspacioNuevo,
    NombreSugerido,
    SedeDelEspacio,
    validar_espacio,
)
from app.dominio.usuarios import Perfil, Rol

VALIDOS = DatosEspacio(
    sede_id=3,
    deporte="Futbol",
    tipo="F5",
    techada=False,
    iluminada=True,
    precio_por_hora=38000,
)


def _errores(**cambios: Any) -> dict[str, str]:
    espacio, errores = validar_espacio(replace(VALIDOS, **cambios))
    assert espacio is None
    return errores


def test_un_espacio_completo_se_puede_guardar() -> None:
    espacio, errores = validar_espacio(VALIDOS)
    assert errores == {}
    assert espacio == EspacioNuevo(3, "Futbol", "F5", False, True, 38000)


def test_cada_campo_que_falta_es_obligatorio() -> None:
    vacio = DatosEspacio(None, "", "", None, None, None)
    _, errores = validar_espacio(vacio)
    assert errores == dict.fromkeys(
        ["sede_id", "deporte", "tipo", "techada", "iluminada", "precio_por_hora"],
        "Este campo es obligatorio",
    )


def test_deporte_y_tipo_salen_del_catalogo() -> None:
    assert _errores(deporte="Rugby") == {"deporte": "Elegí un deporte de la lista"}
    assert _errores(tipo="PDL") == {"tipo": "Elegí un tipo de la lista"}


@pytest.mark.parametrize("precio", [0, -1, 10_000_000])
def test_el_precio_es_positivo_y_con_tope(precio: int) -> None:
    assert _errores(precio_por_hora=precio) == {
        "precio_por_hora": "Ingresá un precio entre $ 1 y $ 9.999.999"
    }


def test_el_catalogo_no_repite_claves() -> None:
    claves = [d.clave for d in CATALOGO]
    assert len(claves) == len(set(claves))
    for d in CATALOGO:
        tipos = [t.clave for t in d.tipos]
        assert tipos and len(tipos) == len(set(tipos))


def _perfil(rol: Rol) -> Perfil:
    return Perfil(
        id=7,
        uid="uid",
        nombre="Ana",
        apellido="Díaz",
        correo="ana@club.com",
        rol=rol,
        dni="20000001",
        fecha_nacimiento=date(1985, 6, 1),
    )


class _EspaciosEnMemoria:
    def __init__(self, sede: SedeDelEspacio | None) -> None:
        self.sede = sede
        self.guardados: list[tuple[EspacioNuevo, int | None, str, int]] = []

    def activos(
        self,
        sede_id: int | None = None,
        deporte: str | None = None,
        tipo: str | None = None,
    ) -> list[Espacio]:
        return []

    def siguiente(
        self,
        sede_id: int,
        deporte: str,
        tipo: str,
        nombre: Callable[[SedeDelEspacio, int], str],
    ) -> NombreSugerido | None:
        return None if self.sede is None else NombreSugerido(nombre(self.sede, 3), 3)

    def insertar(
        self,
        nuevo: EspacioNuevo,
        numero: int | None,
        nombre: Callable[[SedeDelEspacio, int], str],
        autor: int,
    ) -> Espacio:
        assert self.sede is not None
        compuesto = nombre(self.sede, 3)
        self.guardados.append((nuevo, numero, compuesto, autor))
        return Espacio(1, compuesto, nuevo.sede_id, self.sede.nombre, nuevo.deporte,
                       nuevo.tipo, 3, nuevo.techada, nuevo.iluminada,
                       nuevo.precio_por_hora)  # fmt: skip

    def actualizar(self, espacio_id: int, cambio: CambioDeEspacio, autor: int) -> Espacio:
        raise NotImplementedError

    def dar_de_baja(self, espacio_id: int, autor: int) -> None:
        raise NotImplementedError


MORON = SedeDelEspacio("Sede Morón", "Av. Rivadavia", 19850)


def test_el_nombre_sugerido_es_el_del_enunciado_con_el_numero_siguiente() -> None:
    s = nombre_sugerido(_perfil("admin"), 3, "Futbol", "F5", _EspaciosEnMemoria(MORON))
    assert (s.nombre, s.numero) == ("Moron_Rivadavia_19850_Futbol_F5_3", 3)


def test_sin_sede_activa_no_hay_nombre() -> None:
    with pytest.raises(NoDisponible):
        nombre_sugerido(_perfil("admin"), 3, "Futbol", "F5", _EspaciosEnMemoria(None))


def test_el_alta_queda_a_nombre_del_administrador_con_el_nombre_compuesto() -> None:
    espacios = _EspaciosEnMemoria(MORON)
    espacio = dar_de_alta_espacio(_perfil("admin"), VALIDOS, 3, espacios)
    assert espacio.nombre == "Moron_Rivadavia_19850_Futbol_F5_3"
    assert [(n, a) for _, n, _, a in espacios.guardados] == [(3, 7)]


def test_un_usuario_no_gestiona_espacios() -> None:
    espacios = _EspaciosEnMemoria(MORON)
    with pytest.raises(Prohibido):
        dar_de_alta_espacio(_perfil("usuario"), VALIDOS, None, espacios)
    with pytest.raises(Prohibido):
        nombre_sugerido(_perfil("usuario"), 3, "Futbol", "F5", espacios)
    assert espacios.guardados == []


def test_con_datos_invalidos_no_se_guarda_nada() -> None:
    espacios = _EspaciosEnMemoria(MORON)
    with pytest.raises(DatosInvalidos):
        dar_de_alta_espacio(_perfil("admin"), replace(VALIDOS, tipo=""), None, espacios)
    assert espacios.guardados == []
