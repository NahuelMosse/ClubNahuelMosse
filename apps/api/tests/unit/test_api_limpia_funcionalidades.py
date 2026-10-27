import json
import re
import tomllib
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.shared.errors import Forbidden, InvalidData, NotFound

API = Path(__file__).resolve().parents[2]
APP = API / "app"
MODULOS = APP / "modules"
SHARED = APP / "shared"


def _codigo(archivos: list[Path]) -> dict[str, str]:
    return {a.relative_to(APP).as_posix(): a.read_text(encoding="utf-8") for a in sorted(archivos)}


def _fuentes(carpeta: Path) -> list[Path]:
    return [a for a in carpeta.rglob("*.py") if "__pycache__" not in a.parts]


def _datos() -> dict[str, str]:
    """Los archivos que hablan con la base: el de transacciones y los repositorios."""
    return _codigo([SHARED / "db.py", *MODULOS.glob("*/repositorio.py")])


def test_ninguna_ruta_atrapa_los_errores_que_se_responden_igual_en_toda_la_api() -> None:
    """ninguna ruta atrapa los errores que se responden igual en toda la API
    @ARQ-02-S2 @assumption:ARQ-02-ASM-01"""
    comunes = re.compile(
        r"sin_permiso\(|no_encontrado\(|datos_invalidos\("
        r"|HTTP_403_FORBIDDEN\)|HTTP_404_NOT_FOUND\)"
        r'|HTTP_422_UNPROCESSABLE_CONTENT,\s*content=\{"errores": e\.errors\}'
    )
    rutas = [a for a in _fuentes(MODULOS) if a.name.startswith("rutas")]
    assert rutas
    encontrados = [
        f"{nombre}: {m.group(0)}"
        for nombre, texto in _codigo(rutas).items()
        for m in comunes.finditer(texto)
    ]
    assert encontrados == []


@pytest.mark.parametrize(
    ("error", "codigo", "cuerpo"),
    [
        (
            InvalidData({"nombre": "Falta el nombre"}),
            422,
            b'{"errores":{"nombre":"Falta el nombre"}}',
        ),
        (Forbidden("no"), 403, b""),
        (NotFound(), 404, b""),
    ],
)
def test_cada_error_del_dominio_comun_se_responde_con_su_codigo_y_su_cuerpo(
    error: Exception, codigo: int, cuerpo: bytes
) -> None:
    """datos inválidos responde 422 con sus errores, prohibido 403 y no encontrada 404, sin cuerpo
    @ARQ-02-S1 @assumption:ARQ-02-ASM-01"""
    app = create_app()

    def falla() -> None:
        raise error

    app.add_api_route("/falla", falla)

    respuesta = TestClient(app, base_url="http://localhost").get("/falla")

    assert (respuesta.status_code, respuesta.content) == (codigo, cuerpo)


def test_el_contrato_publicado_no_cambia() -> None:
    """el contrato publicado no cambia @ARQ-02-S3 @assumption:ARQ-02-ASM-04"""
    publicado = json.loads((API / "openapi.json").read_text(encoding="utf-8"))

    assert create_app().openapi() == publicado


def test_los_repositorios_confirman_y_deshacen_en_un_solo_lugar() -> None:
    """los repositorios confirman y deshacen en un solo lugar @ARQ-02-S2"""
    codigo = _datos()
    con_rollback = {n for n, t in codigo.items() if "except BaseException" in t}

    assert con_rollback == {"shared/db.py"}
    assert codigo["shared/db.py"].count("except BaseException") == 1


def test_la_zona_del_club_el_lector_de_horas_y_el_identificador_se_definen_una_vez() -> None:
    """la zona del club, el lector de horas y el identificador se definen una vez @ARQ-02-S2"""
    codigo = _codigo(_fuentes(APP))
    todo = "\n".join(codigo.values())

    assert "timedelta(hours=-3)" not in todo
    assert len(re.findall(r"^def _?parse_time\(", todo, flags=re.MULTILINE)) == 1
    assert [n for n, t in codigo.items() if "Identifier = " in t] == ["shared/input_validation.py"]


def test_email_validator_deja_de_ser_dependencia_y_nadie_la_importa() -> None:
    """email-validator deja de ser dependencia y nadie la importa @assumption:ARQ-02-ASM-03"""
    proyecto = tomllib.loads((API / "pyproject.toml").read_text(encoding="utf-8"))
    dependencias = " ".join(proyecto["project"]["dependencies"])

    assert "email-validator" not in dependencias
    assert not any("email_validator" in t for t in _codigo(_fuentes(APP)).values())
