import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[4]
DOC = RAIZ / "docs" / "technical" / "integraciones.md"
SERVICIOS = [
    "Firebase Authentication",
    "Firebase Cloud Messaging",
    "Brevo",
    "PostgreSQL en Render",
    "Render",
    "Monitor que mantiene despierta la API",
]
CODIGO = ("apps/api/app", "apps/mobile/lib", "apps/mobile/android")
OTROS = ("render.yaml", "firebase.json", "package.json", "apps/mobile/definiciones.example.json")
NOMBRE_DE_VARIABLE = re.compile(r"^[A-Z][A-Z0-9_]{3,}$")
FORMAS_DE_SECRETO = [r"xkeysib-", r"rnd_", r"postgres(ql)?(\+\w+)?://[^\s:/`]+:[^\s@`]+@", r'"private_key"']


def _secciones() -> dict[str, str]:
    texto = DOC.read_text(encoding="utf-8")
    partes = re.split(r"^## ", texto, flags=re.M)[1:]
    return {p.split("\n", 1)[0].strip(): p for p in partes}


def _citas(texto: str) -> list[str]:
    return re.findall(r"`([^`\n]+)`", texto)


def _corpus() -> str:
    archivos = [RAIZ / o for o in OTROS]
    for carpeta in CODIGO:
        archivos += [f for f in (RAIZ / carpeta).rglob("*") if f.suffix in {".py", ".dart", ".xml"}]
    return "\n".join(f.read_text(encoding="utf-8", errors="ignore") for f in archivos)


def test_integraciones_md_tiene_una_seccion_por_servicio_con_para_que_se_usa() -> None:
    """integraciones.md tiene una sección por servicio con para qué se usa @DOC-03-S1 @assumption:DOC-03-ASM-02"""
    secciones = _secciones()
    for servicio in SERVICIOS:
        assert servicio in secciones, servicio
        assert "**Para qué se usa.**" in secciones[servicio], servicio
    for vecino in ("arquitectura.md", "system-design.md"):
        assert "integraciones.md" in (RAIZ / "docs" / "technical" / vecino).read_text(encoding="utf-8")


def test_cada_seccion_nombra_sus_archivos_y_sus_variables() -> None:
    """cada sección nombra sus archivos y sus variables @DOC-03-S2 @assumption:DOC-03-ASM-04"""
    for servicio, cuerpo in _secciones().items():
        if servicio not in SERVICIOS:
            continue
        assert "**Archivos.**" in cuerpo, servicio
        assert "**Variables.**" in cuerpo, servicio
        archivos = cuerpo.split("**Archivos.**", 1)[1].split("**Variables.**", 1)[0]
        assert any("/" in c or "." in c for c in _citas(archivos)), servicio


def test_cada_archivo_y_variable_que_cita_integraciones_md_existe_en_el_repo() -> None:
    """cada archivo y variable que cita integraciones.md existe en el repo @assumption:DOC-03-ASM-01"""
    corpus = _corpus()
    for cita in _citas(DOC.read_text(encoding="utf-8")):
        if NOMBRE_DE_VARIABLE.match(cita):
            assert cita in corpus, f"variable inexistente: {cita}"
        elif "/" in cita and not cita.startswith(("/", "http", "GET ", "POST ")) and " " not in cita:
            assert (RAIZ / cita).exists(), f"archivo inexistente: {cita}"


def test_integraciones_md_no_tiene_claves_cuentas_de_servicio_ni_urls_con_contrasena() -> None:
    """integraciones.md no tiene claves, cuentas de servicio ni URLs con contraseña @assumption:DOC-03-ASM-03"""
    texto = DOC.read_text(encoding="utf-8")
    for forma in FORMAS_DE_SECRETO:
        assert not re.search(forma, texto), forma
