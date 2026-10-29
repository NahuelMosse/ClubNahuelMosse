"""El módulo de notificaciones de la API está en inglés."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import ast
import re
from pathlib import Path

import pytest

from tests.unit.test_base_en_ingles import (
    PALABRAS_COMUNES,
    _castellano,
    _nombres_definidos,
    _palabras,
    _textos_de_prosa,
)

APP = Path(__file__).resolve().parents[2] / "app"
MODULO = APP / "modules" / "notifications"
ARCHIVOS = ["use_cases", "rules", "repository", "routes", "store", "sweep", "push"]
VIEJOS = ["casos_de_uso", "reglas", "repositorio", "rutas", "almacen", "barrido", "push"]
# Términos de este módulo que el glosario no lista como palabra suelta.
EXTRA_CASTELLANO = {
    "aviso", "avisos", "canal", "envio", "enviar", "enviado", "enviados", "invalido",
    "invalidos", "anticipacion", "espera", "motivo", "vigente", "registro", "pedido",
    "cuenta", "fila", "filas", "vencidos", "varados", "atascados", "muertos", "previo",
    "nuevas", "nuevo", "anuladas", "anulada", "perdido", "dispositivo", "dispositivos",
    "leida", "leer", "todas", "creada", "baja", "centro", "lista", "vista",
    "bloqueo", "recordatorio", "cancelacion", "forzosa", "hora", "cuando", "momento",
    "usuario", "reserva", "sede", "tipo", "titulo", "cuerpo", "datos", "plataforma",
    "permiso", "notificacion", "notificaciones", "inicio", "fin", "deporte", "unica",
    "total", "cantidad", "pendiente", "pendientes", "fallida", "fallidos", "siguiente",
    "tomar", "marcar", "registrar", "entregar", "despachar", "barrer", "armar", "mensaje",
}  # fmt: skip
INGLES = {"total", "token", "tokens", "push", "id", "ids"}  # `total` y `token` son inglés también
# Campos de los modelos Pydantic: son claves JSON y se quedan en castellano (ENG-04-ASM-05).
CLASES_DE_CAMPOS = {"BaseModel"}


def _campos_json(arbol: ast.AST) -> set[str]:
    campos: set[str] = set()
    for nodo in ast.walk(arbol):
        if isinstance(nodo, ast.ClassDef) and any(
            isinstance(b, ast.Name) and b.id in CLASES_DE_CAMPOS for b in nodo.bases
        ):
            campos |= {
                s.target.id
                for s in nodo.body
                if isinstance(s, ast.AnnAssign) and isinstance(s.target, ast.Name)
            }
    return campos


def test_el_modulo_de_notificaciones_se_llama_como_dice_el_glosario() -> None:
    """el módulo de notificaciones se llama como dice el glosario @ENG-04-S1 @assumption:ENG-04-ASM-02 @assumption:ENG-04-ASM-03"""
    faltan = [f"{n}.py" for n in ARCHIVOS if not (MODULO / f"{n}.py").exists()]
    sobran = [
        f"notificaciones/{n}.py"
        for n in VIEJOS
        if (APP / "modules" / "notificaciones" / f"{n}.py").exists()
    ]
    importes = re.compile(
        r"\bapp\.modules\.notificaciones\b|\bmodules import [^\n]*\bnotificaciones\b"
    )
    raiz = APP.parent
    viejos = [
        str(p.relative_to(raiz))
        for carpeta in (APP, raiz / "tests", raiz / "migrations")
        for p in carpeta.rglob("*.py")
        if p.resolve() != Path(__file__).resolve()
        and ".venv" not in p.parts
        and importes.search(p.read_text(encoding="utf-8"))
    ]

    assert not faltan, faltan
    assert not sobran, sobran
    assert not viejos, viejos
    assert (MODULO / "__init__.py").exists()


def test_los_nombres_comentarios_y_docstrings_de_notificaciones_estan_en_ingles() -> None:
    """los nombres, comentarios y docstrings de notificaciones están en inglés @ENG-04-S2 @assumption:ENG-04-ASM-04"""
    castellano = (_castellano() | EXTRA_CASTELLANO) - INGLES
    problemas: list[str] = []
    archivos = [MODULO / "__init__.py", *(MODULO / f"{n}.py" for n in ARCHIVOS)]
    for ruta in archivos:
        if not ruta.exists():
            problemas.append(f"{ruta.name}: no existe")
            continue
        fuente = ruta.read_text(encoding="utf-8")
        arbol = ast.parse(fuente)
        for nombre in sorted(_nombres_definidos(arbol) - _campos_json(arbol)):
            if castellano & set(_palabras(nombre)):
                problemas.append(f"{ruta.name}: nombre {nombre}")
        for texto in _textos_de_prosa(fuente, arbol):
            if PALABRAS_COMUNES.search(texto):
                problemas.append(f"{ruta.name}: {texto.strip().splitlines()[0][:60]}")

    assert not problemas, problemas


# (ruta, método) -> (operationId, parámetros, códigos, ¿lleva cuerpo?); todas llevan HTTPBearer.
CONTRATO = {
    ("/dispositivos", "put"): ("registrar_dispositivos_put", [], {"204", "401", "403", "409", "422"}, True),
    ("/dispositivos/baja", "post"): ("baja_dispositivos_baja_post", [], {"204", "401", "422"}, True),
    ("/notificaciones", "get"): ("centro_notificaciones_get", [], {"200", "401"}, False),
    ("/notificaciones/leer-todas", "post"): ("leer_todas_notificaciones_leer_todas_post", [], {"204", "401"}, False),
    ("/notificaciones/{notificacion_id}/leer", "post"): (
        "leer_notificaciones__notificacion_id__leer_post",
        [("notificacion_id", "path", True)],
        {"204", "401", "404", "422"},
        False,
    ),
}  # fmt: skip


def test_el_contrato_y_el_mensaje_push_de_notificaciones_son_los_de_main(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """el contrato y el mensaje push de notificaciones son los de main @ENG-04-S3 @assumption:ENG-04-ASM-01"""
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    from app.main import create_app
    from app.modules.notifications.push import build_message
    from app.modules.notifications.rules import Notice

    caminos = create_app().openapi()["paths"]
    obtenido = {}
    for (ruta, metodo), _ in CONTRATO.items():
        op = caminos[ruta][metodo]
        parametros = [(p["name"], p["in"], p["required"]) for p in op.get("parameters", [])]
        obtenido[(ruta, metodo)] = (
            op["operationId"],
            parametros,
            set(op["responses"]),
            "requestBody" in op,
            op["security"],
        )
    esperado = {k: (*v, [{"HTTPBearer": []}]) for k, v in CONTRATO.items()}
    comun = Notice(title="T", body="B", data={"tipo": "recordatorio", "reserva_id": "r"})
    forzosa = Notice(title="T", body="B", data={"tipo": "cancelacion_forzosa"})
    simple = build_message(["a", "b"], comun)
    agrupado = build_message(["a"], forzosa)

    assert obtenido == esperado
    assert (simple.notification.title, simple.notification.body) == ("T", "B")
    assert simple.data == {"tipo": "recordatorio", "reserva_id": "r"}
    assert simple.tokens == ["a", "b"] and simple.android is None and simple.apns is None
    assert agrupado.android.collapse_key == "cancelacion_forzosa"
    assert agrupado.android.notification.tag == "cancelacion_forzosa"
    assert agrupado.apns.headers == {"apns-collapse-id": "cancelacion_forzosa"}
    assert agrupado.data == {"tipo": "cancelacion_forzosa"}
