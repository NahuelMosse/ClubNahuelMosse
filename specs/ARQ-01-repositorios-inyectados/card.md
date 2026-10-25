# ARQ-01 · repositorios inyectados en las rutas

card: ARQ-01
status: proposed
cap: 3 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-25): «por que no se uso inyeccion de dependencias para manejar la clean architecture?» y, sobre la propuesta A (proveedores con `Depends` en `dependencias.py`), «hace los cambios A y B»"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "por que no se uso inyeccion de dependencias para manejar la clean architecture?" · acceptance: ninguna ruta de `app/interfaz/` construye un repositorio ni un servicio de infraestructura (`…Sql(…)`, `ProveedorFirebase(…)`); los recibe con `Depends` desde `app/dependencias.py`
- S2 · "hace los cambios A" · acceptance: un test reemplaza el repositorio de una ruta con `app.dependency_overrides` y la ruta responde con los datos del reemplazo, sin base de datos
- ARQ-01-ASM-01 · los comandos de consola (`barrido.py`, `sembrar_admin.py`) no tienen pedido HTTP ni `Depends`: siguen armando sus piezas, como raíz de composición de su proceso · S1
- ARQ-01-ASM-02 · un pedido sigue usando una sola conexión: los proveedores dependen de `conexion` y FastAPI resuelve una vez por pedido la misma dependencia, así que una ruta con dos repositorios los arma sobre la misma conexión · S1

## Tasks

- T1 · S1,S2,ARQ-01-ASM-01,ARQ-01-ASM-02 · apps/api/app/dependencias.py (presentation), apps/api/app/interfaz/reservas.py (presentation), apps/api/app/interfaz/notificaciones.py (presentation), apps/api/app/interfaz/espacios.py (presentation), apps/api/app/interfaz/sesion.py (presentation), apps/api/app/interfaz/sedes.py (presentation), apps/api/app/interfaz/recuperacion.py (presentation), apps/api/app/interfaz/horarios.py (presentation), apps/api/app/interfaz/registro.py (presentation), apps/api/app/interfaz/pruebas.py (presentation) · tests: apps/api/tests/unit/test_repositorios_inyectados.py "ninguna ruta construye un repositorio ni un servicio de infraestructura @ARQ-01-S1 @assumption:ARQ-01-ASM-01"; apps/api/tests/unit/test_repositorios_inyectados.py "una ruta recibe su repositorio por dependencia y un test lo reemplaza @ARQ-01-S2"; apps/api/tests/unit/test_repositorios_inyectados.py "una ruta con dos repositorios los arma sobre la misma conexión @ARQ-01-ASM-02"

## Changes to existing behavior

- `app/dependencias.py` expone un proveedor por repositorio y servicio (`repositorio_reservas`, `repositorio_sedes`, …, `identidad`); las rutas de `app/interfaz/` los reciben con `Depends` en vez de construir `…Sql(conn)` · ningún contrato HTTP cambia

## Gate

```
suite: sh D:/Temp/w/herramientas/pytest-api.sh
lint: sh D:/Temp/w/herramientas/ruff-mypy-api-rev06.sh
```

## Log

- L1 · por que no se uso inyeccion de dependencias para manejar la clean architecture? · (sobre la propuesta: A. Proveedores con `Depends`: `dependencias.py` expone `def repo_reservas(conn) -> Reservas`, y la ruta recibe un `Reservas` en vez de construir `ReservasSql`) hace los cambios A y B
