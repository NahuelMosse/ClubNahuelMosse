"""Los módulos de cuenta en inglés sobre el main de hoy: el correo de la recuperación ya vive en `notifications`."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import ast
from pathlib import Path

from tests.unit import test_modules_account_in_english as anterior
from tests.unit.test_api_in_english_contract_current import operations_differing_in
from tests.unit.test_base_in_english import COMMON_WORDS, _spanish, _words

FILES = {
    modulo: [a for a in archivos if a != "email"] for modulo, archivos in anterior.FILES.items()
}
NUEVOS = [anterior.MODULES / m / f"{a}.py" for m, archivos in FILES.items() for a in archivos]


def test_los_modulos_de_sedes_usuarios_sesion_y_recuperacion_se_llaman_como_dice_el_glosario() -> (
    None
):
    """los módulos de sedes, usuarios, sesión y recuperación se llaman como dice el glosario @ENG-02-S1 @assumption:ENG-02-ASM-02 @assumption:ENG-02-ASM-03"""
    faltan = [str(p.relative_to(anterior.APP)) for p in NUEVOS if not p.exists()]
    sobran = [v for v in anterior.OLD_NAMES if (anterior.MODULES / v).exists()]
    importes = [
        str(p.relative_to(anterior.API_ROOT))
        for carpeta in (
            anterior.APP,
            anterior.API_ROOT / "tests",
            anterior.API_ROOT / "migrations",
        )
        for p in carpeta.rglob("*.py")
        if p.resolve() != Path(anterior.__file__).resolve()
        and ".venv" not in p.parts
        and anterior.OLD_IMPORT.search(p.read_text(encoding="utf-8"))
    ]

    assert not faltan, faltan
    assert not sobran, sobran
    assert not importes, importes


def test_los_nombres_comentarios_y_docstrings_de_esos_modulos_estan_en_ingles() -> None:
    """los nombres, comentarios y docstrings de esos módulos están en inglés @ENG-02-S2 @assumption:ENG-02-ASM-04"""
    castellano = _spanish() | {"sede", "sedes", "usuario", "usuarios", "sesion", "recuperacion"}
    problemas: list[str] = []
    for ruta in NUEVOS:
        if not ruta.exists():
            problemas.append(f"{ruta.name}: no existe")
            continue
        fuente = ruta.read_text(encoding="utf-8")
        arbol = ast.parse(fuente)
        exentos = anterior._route_params(fuente) | anterior._model_fields(arbol)
        for nombre in sorted(anterior._defined_names(arbol) - exentos):
            if castellano & set(_words(nombre)):
                problemas.append(f"{ruta.parent.name}/{ruta.name}: nombre {nombre}")
        for texto in anterior._prose(fuente, arbol):
            if COMMON_WORDS.search(texto):
                problemas.append(
                    f"{ruta.parent.name}/{ruta.name}: {texto.strip().splitlines()[0][:60]}"
                )

    assert not problemas, problemas


def test_el_contrato_tiene_las_mismas_rutas_metodos_codigos_campos_y_operation_id_que_main() -> (
    None
):
    """el contrato tiene las mismas rutas, métodos, códigos, campos y operationId que main @ENG-02-S3 @assumption:ENG-02-ASM-01"""
    assert operations_differing_in("/register", "/me", "/password-recovery", "/link", "/venues") == []
