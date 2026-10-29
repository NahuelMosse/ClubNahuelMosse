"""Los requisitos no funcionales del enunciado, verificados contra el repo y la API real."""

import hashlib
import os
import re
import subprocess
from collections.abc import Callable
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo

import httpx2
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

RAIZ = Path(__file__).resolve().parents[4]
APP = RAIZ / "apps" / "mobile"
API = RAIZ / "apps" / "api"
NOMBRE = "ClubNahuelMosse"
ZONA = ZoneInfo("America/Argentina/Buenos_Aires")
METODOS = {"get", "post", "put", "delete", "patch"}

# Lo que la API sirve sin sesión: alta de cuenta y recuperación de contraseña (con la página del enlace del correo).
PUBLICAS = {
    ("post", "/registro"),
    ("post", "/recuperacion"),
    ("post", "/recuperacion/consulta"),
    ("put", "/recuperacion"),
    ("get", "/enlace/recuperar"),
    ("get", "/health"),
}

# ic_launcher.png que genera `flutter create`, por densidad.
ICONO_POR_DEFECTO = {
    "13e9c72ec37fac220397aa819fa1ef2d",
    "6270344430679711b81476e29878caa7",
    "a0a8db5985280b3679d99a820ae2db79",
    "afe1b655b9f32da22f9a4301bb8e6ba8",
    "57838d52c318faff743130c3fcfae0c6",
}


def _leer(ruta: Path) -> str:
    return ruta.read_text(encoding="utf-8")


def _normalizar(ruta: str) -> str:
    sin_consulta = ruta.split("?")[0]
    sin_interpolacion = re.sub(r"\$\{[^}]*\}|\$\w+|\{[^}]*\}", "{}", sin_consulta)
    return sin_interpolacion.rstrip("/") or "/"


def _endpoints_que_usa_la_app() -> set[tuple[str, str]]:
    """Cada llamada a la API con ruta literal: `_api.get('/x')`, `_get('/x')`, `Uri(path: '/x')`."""
    llamadas = re.compile(r"\b_?api\.(get|post|put|delete)\(\s*'([^']+)'")
    hallados = {
        (m.group(1), _normalizar(m.group(2)))
        for f in (APP / "lib").rglob("*.dart")
        for m in llamadas.finditer(_leer(f))
    }
    # El catálogo, la búsqueda y la grilla arman un `Uri` y piden GET.
    for f in (
        APP / "lib" / "espacios" / "espacios.dart",
        APP / "lib" / "reservas" / "horarios.dart",
    ):
        for m in re.finditer(r"(?:_get\(\s*'([^']+)'|path:\s*'([^']+)')", _leer(f)):
            hallados.add(("get", _normalizar(m.group(1) or m.group(2))))
    return hallados


def _operaciones(api: TestClient) -> set[tuple[str, str]]:
    esquema = api.get("/openapi.json").json()
    return {
        (metodo, _normalizar(ruta))
        for ruta, ops in esquema["paths"].items()
        for metodo in ops
        if metodo in METODOS
    }


def test_la_app_se_llama_clubnahuelmosse_en_el_dispositivo_y_en_el_repositorio() -> None:
    """la app se llama ClubNahuelMosse en el dispositivo y el repositorio tiene el mismo nombre @RNF-01-H01-01"""
    manifiesto = _leer(APP / "android" / "app" / "src" / "main" / "AndroidManifest.xml")
    gradle = _leer(APP / "android" / "app" / "build.gradle.kts")

    assert f'android:label="{NOMBRE}"' in manifiesto
    assert f'applicationId = "ar.edu.unimoron.{NOMBRE.lower()}"' in gradle
    assert re.search(rf"^name: {NOMBRE.lower()}$", _leer(APP / "pubspec.yaml"), re.M)
    origen = _git("remote", "get-url", "origin")
    assert re.fullmatch(rf"https://github\.com/[^/]+/{NOMBRE}(\.git)?", origen), origen


def test_la_app_es_un_proyecto_flutter_para_android() -> None:
    """la app es un proyecto Flutter que compila y corre en un emulador Android @RNF-01-H02-01"""
    pubspec = _leer(APP / "pubspec.yaml")

    assert re.search(r"^dependencies:\n  flutter:\n    sdk: flutter$", pubspec, re.M)
    assert (APP / "lib" / "main.dart").is_file()
    assert (APP / "android" / "app" / "build.gradle.kts").is_file()
    actividad = next((APP / "android" / "app" / "src" / "main" / "kotlin").rglob("MainActivity.kt"))
    assert "FlutterActivity" in _leer(actividad)


def _git(*args: str) -> str:
    try:
        r = subprocess.run(
            ["git", "-C", str(RAIZ), *args], capture_output=True, text=True, check=True
        )
    except (OSError, subprocess.CalledProcessError):
        pytest.skip("hace falta el historial git del repositorio")
    return r.stdout.strip()


def test_el_repositorio_es_del_alumno_y_el_historial_tiene_commits_a_lo_largo_del_desarrollo() -> (
    None
):
    """el repositorio es de la cuenta del alumno y el historial tiene commits a lo largo del desarrollo @RNF-01-H03-01 @supuesto:RNF-01-SUP-06"""
    origen = _git("remote", "get-url", "origin")
    fechas = _git("log", "--format=%ad", "--date=short").splitlines()

    assert origen.startswith("https://github.com/NahuelMosse/")
    assert len(fechas) >= 50
    assert len(set(fechas)) >= 3


def test_la_api_publica_openapi_con_todos_los_endpoints_que_usa_la_app(api: TestClient) -> None:
    """la API publica su documentación OpenAPI con todos los endpoints que usa la app @RNF-01-H04-01"""
    usados = _endpoints_que_usa_la_app()
    publicados = _operaciones(api)

    assert len(usados) >= 30, "no se leyeron las llamadas de la app"
    assert usados <= publicados, sorted(usados - publicados)
    docs = api.get("/docs")
    assert docs.status_code == 200
    assert "swagger" in docs.text.lower()


def test_la_api_guarda_los_datos_en_postgresql(motor: Engine) -> None:
    """la API guarda los datos en una base PostgreSQL @RNF-01-H05-01"""
    with motor.connect() as conn:
        version: Any = conn.execute(text("SELECT version()")).scalar_one()
        tablas: Any = conn.execute(
            text("SELECT count(*) FROM information_schema.tables WHERE table_name = 'reserva'")
        ).scalar_one()

    assert str(version).startswith("PostgreSQL")
    assert tablas == 1


@pytest.mark.skipif(
    not os.environ.get("API_URL_NUBE"),
    reason="hace falta API_URL_NUBE con la dirección pública de la API desplegada",
)
def test_la_api_responde_desde_una_url_publica_en_la_nube() -> None:
    """la API y la base responden desde una URL pública en la nube y la app instalada usa esa URL @RNF-01-H06-01"""
    base = os.environ["API_URL_NUBE"].rstrip("/")

    esquema = httpx2.get(f"{base}/openapi.json", timeout=60)
    sedes = httpx2.get(f"{base}/sedes", timeout=60)

    assert base.startswith("https://")
    assert esquema.status_code == 200
    # Sin sesión la nube rechaza, y para responder 401 tuvo que abrir su base.
    assert sedes.status_code == 401


def test_toda_operacion_de_la_api_sin_usuario_autenticado_se_rechaza(api: TestClient) -> None:
    """una operación sobre usuarios o reservas sin usuario autenticado se rechaza @RNF-01-H06-02 @supuesto:RNF-01-SUP-01"""
    esquema: dict[str, Any] = api.get("/openapi.json").json()
    aceptadas = []
    rechazadas = 0

    for ruta, ops in esquema["paths"].items():
        for metodo in ops:
            if metodo not in METODOS or (metodo, ruta) in PUBLICAS:
                continue
            url = re.sub(r"\{[^}]*\}", "1", ruta)
            r = api.request(metodo.upper(), url, json={} if metodo != "get" else None)
            if r.status_code == 401:
                rechazadas += 1
            else:
                aceptadas.append((metodo, ruta, r.status_code))

    assert not aceptadas, aceptadas
    assert rechazadas >= 25
    token_falso = {"Authorization": "Bearer no-es-un-token"}
    assert api.get("/reservas", headers=token_falso).status_code == 401
    assert api.get("/yo", headers=token_falso).status_code == 401


def test_las_reservas_actuan_sobre_el_usuario_autenticado_y_no_sobre_otro_del_pedido(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """una operación sobre reservas actúa sobre el usuario autenticado y no sobre otro indicado en el pedido @RNF-01-H06-03"""
    ids: list[Any] = []
    sesiones: list[dict[str, str]] = []
    for nombre in ("Ana", "Beto"):
        s = unico()
        correo = f"{nombre.lower()}.{s}@correo.com"
        alta = api.post(
            "/registro",
            json={
                "nombre": nombre,
                "apellido": "Ferreyra",
                "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
                "fecha_nacimiento": "1994-07-21",
                "correo": correo,
                "contrasena": "ClubNahuel1",
            },
        )
        assert alta.status_code == 201
        token = iniciar_sesion(correo, "ClubNahuel1")
        assert token is not None
        sesiones.append({"Authorization": f"Bearer {token}"})
        with motor.connect() as conn:
            ids.append(
                conn.execute(
                    text("SELECT id FROM app_user WHERE email = :c"), {"c": correo}
                ).scalar_one()
            )
    ana, beto = sesiones
    id_ana, id_beto = ids
    s = unico()
    with motor.begin() as conn:
        espacio: Any = conn.execute(
            text(
                "WITH s AS (INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
                " VALUES (:n, 'Av. Vergara', 1850, '08:00', '23:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id)"
                " INSERT INTO space (venue_id, sport, kind, number, name, covered,"
                " lit, price_per_hour) SELECT id, 'Futbol', 'F5', 1, :e, false, true,"
                " 38000 FROM s RETURNING id"
            ),
            {"n": f"Sede Haedo {s}", "e": f"Haedo{s}_Vergara_1850_Futbol_F5_1"},
        ).scalar_one()
    manana = (datetime.now(ZONA).date() + timedelta(days=1)).isoformat()

    # Beto reserva a su nombre; Ana intenta reservar y cancelar «como Beto».
    de_beto = api.post(
        "/reservas",
        headers=beto,
        json={"espacio_id": str(espacio), "fecha": manana, "desde": "10:00", "horas": 1},
    )
    de_ana = api.post(
        "/reservas",
        headers=ana,
        json={
            "espacio_id": str(espacio),
            "fecha": manana,
            "desde": "12:00",
            "horas": 1,
            "usuario_id": str(id_beto),
        },
    )
    intento = api.post(f"/reservas/{de_beto.json()['id']}/cancelar", headers=ana)

    assert (de_beto.status_code, de_ana.status_code) == (201, 201)
    with motor.connect() as conn:
        dueno = {
            str(r.id): r.user_id
            for r in conn.execute(
                text("SELECT id, user_id FROM booking WHERE space_id = :e"), {"e": espacio}
            )
        }
        estado: Any = conn.execute(
            text("SELECT status FROM booking WHERE id = :i"), {"i": de_beto.json()["id"]}
        ).scalar_one()
    assert dueno == {de_beto.json()["id"]: id_beto, de_ana.json()["id"]: id_ana}
    assert intento.status_code in (403, 404)
    assert estado == "active"
    mias = api.get("/reservas", headers=ana).json()["reservas"]
    assert [r["id"] for r in mias] == [de_ana.json()["id"]]


def _comandos(readme: str) -> list[str]:
    bloques = re.findall(r"```[a-z]*\n(.*?)```", readme, re.S)
    return [linea.strip() for b in bloques for linea in b.splitlines() if linea.strip()]


def _secciones(readme: str) -> str:
    return " ".join(re.findall(r"^#+ (.+)$", readme, re.M)).lower()


def test_el_readme_de_la_app_alcanza_para_configurar_y_ejecutarla() -> None:
    """siguiendo sólo el README de la app se configura y ejecuta la app @RNF-01-H07-01 @supuesto:RNF-01-SUP-05"""
    readme = _leer(APP / "README.md")
    definidas = set(
        re.findall(
            r"String\.fromEnvironment\(\s*'([A-Z_]+)'",
            _leer(APP / "lib" / "comun" / "configuracion.dart"),
        )
    )

    for seccion in ("configurar", "ejecutar", "probar"):
        assert seccion in _secciones(readme), seccion
    assert {"API_URL", "AUTH_EMULADOR", "FIREBASE_API_KEY"} <= definidas
    assert not {v for v in definidas if v not in readme}, "variables sin documentar"
    for comando in _comandos(readme):
        for guion in re.findall(r"scripts/[\w.]+", comando):
            assert (RAIZ / guion).is_file(), comando
    assert "flutter pub get" in readme
    assert "flutter run" in readme
    assert "flutter build apk" in readme


def test_el_readme_del_backend_alcanza_para_configurar_ejecutar_y_desplegar() -> None:
    """siguiendo sólo el README del backend se configura, ejecuta y despliega la API @RNF-01-H07-02 @supuesto:RNF-01-SUP-05"""
    readme = _leer(API / "README.md")
    configuracion = _leer(API / "app" / "shared" / "config.py")
    variables = {
        campo.upper()
        for campo in re.findall(r"^    ([a-z_]+): ", configuracion, re.M)
        if campo != "model_config"
    }

    for seccion in ("configurar", "ejecutar", "probar", "desplegar"):
        assert seccion in _secciones(readme), seccion
    assert variables >= {"DATABASE_URL", "FIREBASE_PROJECT_ID", "PUBLIC_URL"}
    assert not {v for v in variables if v not in readme}, "variables sin documentar"
    for comando in _comandos(readme):
        for guion in re.findall(r"scripts/[\w.]+", comando):
            assert (RAIZ / guion).is_file(), comando
    assert "alembic upgrade head" in readme
    assert "/docs" in readme


def test_la_app_tiene_un_icono_propio_en_el_launcher() -> None:
    """la app tiene un ícono propio en el launcher @RNF-01-H08-01"""
    pubspec = _leer(APP / "pubspec.yaml")
    imagen = re.search(r"^\s+image_path: \"?([^\"\n]+)\"?$", pubspec, re.M)
    res = APP / "android" / "app" / "src" / "main" / "res"
    iconos = sorted(res.glob("mipmap-*dpi/ic_launcher.png"))

    assert "flutter_launcher_icons:" in pubspec
    assert imagen is not None and (APP / imagen.group(1)).is_file()
    assert len(iconos) == 5
    propios = {hashlib.md5(i.read_bytes()).hexdigest() for i in iconos}
    assert not propios & ICONO_POR_DEFECTO
    assert (res / "mipmap-anydpi-v26" / "ic_launcher.xml").is_file()
