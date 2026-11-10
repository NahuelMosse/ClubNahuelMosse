import ast
import json
import re
from pathlib import Path
from typing import cast

ROOT = Path(__file__).resolve().parents[4]
API = ROOT / "apps" / "api"
APP = API / "app"
MODULES = APP / "modules"
SHARED = APP / "shared"

FOUR_IN_ENGLISH = {"routes", "use_cases", "rules", "repository"}
FILES_OF_EACH = {
    "venues": FOUR_IN_ENGLISH,
    "spaces": FOUR_IN_ENGLISH,
    "availability": FOUR_IN_ENGLISH,
    "bookings": FOUR_IN_ENGLISH,
    "notifications": FOUR_IN_ENGLISH,
    "password_recovery": FOUR_IN_ENGLISH,
    "users": {
        "account_routes",
        "registration_routes",
        "registration",
        "profile",
        "password",
        "deactivation",
        "admins",
        "rules",
        "repository",
    },
    "session": {"profile", "use_cases", "current_user", "repository"},
}
FEATURES = set(FILES_OF_EACH)
USE_CASES = [
    *(
        f"{f}/use_cases.py"
        for f in (
            "bookings",
            "venues",
            "spaces",
            "availability",
            "password_recovery",
            "session",
            "notifications",
        )
    ),
    *(f"users/{c}.py" for c in ("registration", "profile", "password", "deactivation", "admins")),
]
OLD_LAYERS = ("dominio", "aplicacion", "infraestructura", "interfaz", "dependencias")
DATABASE_AND_WEB = ("sqlalchemy", "fastapi", "psycopg")
COMMON_ERRORS = {"InvalidData", "Forbidden", "NotFound"}
# Commit where the card was born: the API contract before moving it.
BASE = "612d445fe18ee945ab3c3f8da31d133b11452d23"
RENAMED = {
    "app__interfaz__reservas__PedidoDeCambio": "BookingChangeRequest",
    "app__interfaz__espacios__PedidoDeCambio": "SpaceChangeRequest",
    "app__interfaz__sedes__PedidoDeEdicion": "VenueEditRequest",
    "app__interfaz__sesion__PedidoDeEdicion": "ProfileEditRequest",
    "ConsultaDeEnlace": "LinkCheck",
    "ContrasenaNueva": "NewPassword",
    "ErroresDeCampo": "FieldErrors",
    "ErroresDeContrasena": "PasswordErrors",
    "ErroresDeSede": "VenueErrors",
    "PedidoCambioDeContrasena": "PasswordChangeRequest",
    "PedidoDeEnlace": "LinkRequest",
    "PedidoDeSede": "VenueRequest",
    "PedidoRegistro": "RegistrationRequest",
    "PerfilPropio": "OwnProfile",
    "RegistroCreado": "RegistrationCreated",
    "ReservasFueraDelHorario": "BookingsOutside",
    "SedeVista": "VenueView",
    "Sedes": "VenueList",
    "SinSesion": "NoSession",
    "UsuarioRepetido": "DuplicateUser",
    "Catalogo": "CatalogView",
    "DeporteVista": "SportView",
    "EspacioVista": "SpaceView",
    "FranjaVista": "SlotView",
    "GrillaVista": "SlotGridView",
    "ListaDeEspacios": "SpaceList",
    "PedidoDeEspacio": "SpaceRequest",
    "Sugerencia": "Suggestion",
    "TipoVista": "KindView",
}
# ENG-04: the notifications module schemas become English.
NOTIFICATION_RENAMES = {
    "BajaDeDispositivo": "DeviceUnregistration",
    "Centro": "Center",
    "NotificacionVista": "NotificationView",
    "PedidoDeDispositivo": "DeviceRequest",
}
# ENG-05 renamed the bookings schemas; the rest of the contract is unchanged.
BOOKING_RENAMES = {
    "ReservaHistorialVista": "BookingHistoryView",
    "ReservaVista": "BookingView",
    "ListaDeReservas": "BookingList",
    "PedidoDeReserva": "BookingRequest",
    "PedidoDeAnulacion": "VoidRequest",
    "HistorialVista": "HistoryView",
    "ContadoresVista": "CountersView",
    "Errores": "Errors",
}


def _entries(folder: Path) -> set[str]:
    return {e.name for e in folder.iterdir() if e.name not in {"__pycache__", "__init__.py"}}


def _is_submodule(name: str) -> bool:
    """The name is a file of the module and the `__init__` of its folder does not export it."""
    path = API.joinpath(*name.split("."))
    if not path.parent.is_dir():
        return False
    existing = {e.name for e in path.parent.iterdir()}
    if path.name not in existing and f"{path.name}.py" not in existing:
        return False
    init = path.parent / "__init__.py"
    exported = init.is_file() and f'"{path.name}"' in init.read_text(encoding="utf-8")
    return not exported


def _imported(file: Path) -> set[str]:
    """Absolute module names the file imports (relative ones resolved)."""
    package = list(file.relative_to(API).with_suffix("").parts)
    if file.name != "__init__.py":
        package = package[:-1]
    found: set[str] = set()
    for node in ast.walk(ast.parse(file.read_text(encoding="utf-8"))):
        if isinstance(node, ast.Import):
            found.update(a.name for a in node.names)
        elif isinstance(node, ast.ImportFrom):
            base = package[: len(package) - (node.level - 1)] if node.level else []
            module = ".".join([*base, *(node.module.split(".") if node.module else [])])
            found.add(module)
            found.update(
                f"{module}.{a.name}" for a in node.names if _is_submodule(f"{module}.{a.name}")
            )
    return found


def _sources(folder: Path) -> list[Path]:
    return sorted(p for p in folder.rglob("*.py") if "__pycache__" not in p.parts)


def _of_features() -> list[Path]:
    return [p for p in _sources(MODULES) if len(p.relative_to(MODULES).parts) > 1]


def _foreign(file: Path) -> set[tuple[str, str]]:
    """(foreign feature, rest of the module) for each import into another feature."""
    own = file.relative_to(MODULES).parts[0]
    result: set[tuple[str, str]] = set()
    for name in _imported(file):
        parts = name.split(".")
        if parts[:2] == ["app", "modules"] and len(parts) > 2 and parts[2] != own:
            result.add((parts[2], ".".join(parts[3:])))
    return result


def test_only_main_health_tests_shared_and_modules_are_left_on_top() -> None:
    """only main, health, tests, shared and modules are left on top
    @ARQ-04-S1 @assumption:ARQ-04-ASM-01"""
    assert _entries(APP) == {"main.py", "health.py", "e2e_support.py", "shared", "modules"}
    assert _entries(MODULES) == FEATURES


def test_each_feature_is_flat_with_routes_use_cases_rules_and_repository() -> None:
    """each feature is flat, with routes, use cases, rules and repository
    @ARQ-04-S1 @assumption:ARQ-04-ASM-02"""
    for name, expected in FILES_OF_EACH.items():
        folder = MODULES / name
        assert (folder / "__init__.py").is_file(), name
        subfolders = [e for e in folder.iterdir() if e.is_dir() and e.name != "__pycache__"]
        assert subfolders == [], name
        present = {e.stem for e in folder.glob("*.py")}
        assert expected <= present, f"{name}: missing {expected - present}"


def test_a_feature_imports_another_only_through_its_init_and_there_are_no_cycles() -> None:
    """a feature imports another only through its __init__ and there are no cycles
    @ARQ-04-S2"""
    graph: dict[str, set[str]] = {f: set() for f in FEATURES}
    files = _of_features()
    assert {a.relative_to(MODULES).parts[0] for a in files} == FEATURES
    for file in files:
        own = file.relative_to(MODULES).parts[0]
        for foreign, rest in _foreign(file):
            assert rest == "", f"{file.relative_to(APP)} reaches into {foreign}.{rest}"
            graph.setdefault(own, set()).add(foreign)

    def cycle(path: list[str]) -> list[str] | None:
        for neighbor in sorted(graph.get(path[-1], set())):
            if neighbor in path:
                return [*path[path.index(neighbor) :], neighbor]
            if (c := cycle([*path, neighbor])) is not None:
                return c
        return None

    for f in sorted(graph):
        assert cycle([f]) is None, f"cycle: {cycle([f])}"


def test_shared_does_not_import_features_and_rules_do_not_import_database_or_web() -> None:
    """shared does not import features and rules do not import database or web
    @ARQ-04-S2"""
    shared_sources = _sources(SHARED)
    assert shared_sources
    for file in shared_sources:
        own = [n for n in _imported(file) if n.startswith("app.modules")]
        assert own == [], f"{file.relative_to(APP)} imports {own}"
    rules = [p for p in _of_features() if p.name in {"reglas.py", "rules.py"}]
    assert {p.parent.name for p in rules} == FEATURES - {"session"}
    for file in rules:
        for name in _imported(file):
            assert name.split(".")[0] not in DATABASE_AND_WEB, f"{file}: {name}"


def test_the_use_cases_do_not_import_repository_or_routes() -> None:
    """the use cases of each feature, also the users and session ones, do not import repository or routes
    @ARQ-04-S2"""  # noqa: E501
    for path in USE_CASES:
        file = MODULES / path
        assert file.is_file(), path
        for name in _imported(file):
            last = name.split(".")[-1]
            is_app = name.startswith("app.modules.")
            is_upper_layer = (
                last in {"repositorio", "repository"}
                or last.startswith("rutas")
                or last.endswith("routes")
            )
            assert not (is_app and is_upper_layer), f"{path} imports {name}"


def _without_titles(document: object) -> object:
    if isinstance(document, dict):
        return {
            k: _without_titles(v)
            for k, v in document.items()
            if not (k == "title" and isinstance(v, str))
        }
    if isinstance(document, list):
        return [_without_titles(v) for v in document]
    return document


def _contract(text: str) -> dict[str, dict[str, object]]:
    contract: dict[str, dict[str, object]] = json.loads(text)
    return contract


def _is_id_name(name: object) -> bool:
    return isinstance(name, str) and (
        name == "id" or name.endswith("_id") or name == "reemplazada_por"
    )


def _as_uuid(schema: object) -> object:
    if not isinstance(schema, dict):
        return schema
    if schema.get("type") == "integer":
        rest = {k: v for k, v in schema.items() if k not in ("type", "maximum", "minimum")}
        return {**rest, "type": "string", "format": "uuid"}
    if isinstance(schema.get("anyOf"), list):
        return {**schema, "anyOf": [_as_uuid(v) for v in schema["anyOf"]]}
    return schema


def _with_uuid_ids(document: object) -> object:
    """The integer ids of the old contract become uuid, which is what they are today."""
    if isinstance(document, list):
        return [_with_uuid_ids(v) for v in document]
    if not isinstance(document, dict):
        return document
    new = {k: _with_uuid_ids(v) for k, v in document.items()}
    if _is_id_name(new.get("name")) and "schema" in new:
        new["schema"] = _as_uuid(new["schema"])
    properties = new.get("properties")
    if isinstance(properties, dict):
        new["properties"] = {k: _as_uuid(v) if _is_id_name(k) else v for k, v in properties.items()}
    return new


def _with_booking_schemas(
    contract: dict[str, dict[str, object]],
) -> dict[str, dict[str, object]]:
    """The «/reservas» routes use the English schemas; Errors is a copy of «Errores»."""

    def rename(text: str) -> str:
        for old, new in BOOKING_RENAMES.items():
            text = text.replace(f'/schemas/{old}"', f'/schemas/{new}"')
        return text

    routes = cast(dict[str, object], contract["paths"])
    contract["paths"] = {
        route: json.loads(rename(json.dumps(item))) if route.startswith("/reservas") else item
        for route, item in routes.items()
    }
    schemas = cast(dict[str, object], contract["components"]["schemas"])
    schemas = json.loads(rename(json.dumps(schemas)))
    contract["components"]["schemas"] = schemas
    for old, new in BOOKING_RENAMES.items():
        schemas[new] = schemas.pop(old) if new != "Errors" else schemas[old]
    return contract


def test_the_contract_schemas_have_class_names_without_the_module_path() -> None:
    """the contract schemas have class names, without the module path
    @ARQ-04-S3 @assumption:ARQ-04-ASM-05"""
    contract = _contract((API / "openapi.json").read_text(encoding="utf-8"))
    schemas = set(cast(dict[str, object], contract["components"]["schemas"]))
    assert [n for n in schemas if "__" in n] == []
    assert set(RENAMED.values()) <= schemas


def _old_paths(file: Path) -> list[str]:
    pattern = re.compile(r"\bapp\.(" + "|".join(OLD_LAYERS) + r")\b")
    found = [n for n in _imported(file) if pattern.match(n)]
    for node in ast.walk(ast.parse(file.read_text(encoding="utf-8"))):
        if (
            isinstance(node, ast.Constant)
            and isinstance(node.value, str)
            and pattern.search(node.value)
        ):
            found.append(node.value)
    return found


def test_no_test_imports_the_old_layer_paths() -> None:
    """no test imports the old layer paths
    @ARQ-04-S3 @assumption:ARQ-04-ASM-07"""
    for file in sorted((API / "tests").rglob("*.py")):
        if file.resolve() == Path(__file__).resolve():
            continue
        assert _old_paths(file) == [], f"{file.relative_to(API)}"


def test_session_reads_the_user_table_without_writing_it() -> None:
    """session reads the user table without writing it
    @ARQ-04-S2 @assumption:ARQ-04-ASM-03"""
    repository = MODULES / "session" / "repository.py"
    assert repository.is_file()
    text = repository.read_text(encoding="utf-8")
    assert re.findall(r"\b(?:insert|update|delete)\(|\.(?:add|commit|merge|flush)\(", text) == []


def test_the_common_errors_live_in_shared_errors() -> None:
    """the common errors live in shared/errors.py
    @ARQ-04-S1 @assumption:ARQ-04-ASM-06"""

    def classes(file: Path) -> set[str]:
        tree = ast.parse(file.read_text(encoding="utf-8"))
        return {n.name for n in ast.walk(tree) if isinstance(n, ast.ClassDef)}

    errors = SHARED / "errors.py"
    assert errors.is_file()
    assert classes(errors) >= COMMON_ERRORS
    for file in _sources(MODULES):
        assert not classes(file) & COMMON_ERRORS, file


def test_notifications_does_not_import_bookings_the_notice_receives_the_data_it_needs() -> None:
    """notifications does not import bookings: the notice receives the data it needs
    @ARQ-04-S2 @assumption:ARQ-04-ASM-04"""
    files = _sources(MODULES / "notifications")
    assert files
    for file in files:
        for name in _imported(file):
            assert not name.startswith("app.modules.bookings"), f"{file.name}: {name}"
