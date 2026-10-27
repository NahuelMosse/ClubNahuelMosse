import ast
from datetime import date, time
from pathlib import Path
from uuid import UUID

from fastapi.testclient import TestClient

from app.main import create_app
from app.modules.sedes.reglas import Sede
from app.modules.sedes.repositorio import repositorio_sedes
from app.modules.sesion.perfil import Perfil
from app.modules.sesion.usuario_actual import usuario_actual

INTERFAZ = Path(__file__).resolve().parents[2] / "app" / "interfaz"
# Los comandos de consola no tienen pedido HTTP: arman sus piezas ellos mismos.
COMANDOS = {"barrido.py", "sembrar_admin.py"}


def _construcciones(archivo: Path) -> list[str]:
    """Lo que el archivo construye de infraestructura: `…Sql(…)` y `FirebaseProvider(…)`."""
    arbol = ast.parse(archivo.read_text(encoding="utf-8"))
    return [
        f"{archivo.name}:{nodo.lineno} {nodo.func.id}"
        for nodo in ast.walk(arbol)
        if isinstance(nodo, ast.Call)
        and isinstance(nodo.func, ast.Name)
        and (nodo.func.id.endswith("Sql") or nodo.func.id == "FirebaseProvider")
    ]


def test_ninguna_ruta_construye_un_repositorio_ni_un_servicio_de_infraestructura() -> None:
    """ninguna ruta construye un repositorio ni un servicio de infraestructura
    @ARQ-01-S1 @assumption:ARQ-01-ASM-01"""
    rutas = [a for a in sorted(INTERFAZ.glob("*.py")) if a.name not in COMANDOS]
    encontradas = [c for archivo in rutas for c in _construcciones(archivo)]
    assert encontradas == []


class _SedesDePrueba:
    def activas(self) -> list[Sede]:
        return [
            Sede(
                id=UUID(int=7),
                nombre="Sede de prueba",
                calle="Calle",
                altura=123,
                apertura=time(8),
                cierre=time(22),
                dias=(1, 2, 3, 4, 5),
                canchas=2,
                deportes=("futbol",),
            )
        ]


def test_una_ruta_recibe_su_repositorio_por_dependencia_y_un_test_lo_reemplaza() -> None:
    """una ruta recibe su repositorio por dependencia y un test lo reemplaza @ARQ-01-S2"""
    app = create_app()
    app.dependency_overrides[usuario_actual] = lambda: Perfil(
        id=UUID(int=1),
        uid="uid-prueba",
        nombre="Ana",
        apellido="Díaz",
        correo="ana@club.test",
        rol="usuario",
        dni="30111222",
        fecha_nacimiento=date(1990, 1, 1),
    )
    app.dependency_overrides[repositorio_sedes] = _SedesDePrueba

    respuesta = TestClient(app, base_url="http://localhost").get("/sedes")

    assert respuesta.status_code == 200
    assert [s["nombre"] for s in respuesta.json()["sedes"]] == ["Sede de prueba"]


def test_una_ruta_con_dos_repositorios_los_arma_sobre_la_misma_conexion() -> None:
    """una ruta con dos repositorios los arma sobre la misma conexión @ARQ-01-ASM-02"""
    from typing import Annotated

    from fastapi import Depends, FastAPI

    from app.modules.bookings.repository import BookingsSql, bookings_repository
    from app.modules.notificaciones.repositorio import NotificacionesSql, repositorio_notificaciones
    from app.shared.db import connection

    app = FastAPI()
    conexiones: list[object] = []

    def conexion_de_prueba() -> object:
        nueva = object()
        conexiones.append(nueva)
        return nueva

    @app.get("/dos")
    def dos(
        reservas: Annotated[BookingsSql, Depends(bookings_repository)],
        avisos: Annotated[NotificacionesSql, Depends(repositorio_notificaciones)],
    ) -> bool:
        return reservas._conn is avisos._conn

    app.dependency_overrides[connection] = conexion_de_prueba

    respuesta = TestClient(app).get("/dos")

    assert respuesta.json() is True
    assert len(conexiones) == 1
