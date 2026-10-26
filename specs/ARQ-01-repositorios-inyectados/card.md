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

- T1 · S1,S2,ARQ-01-ASM-01,ARQ-01-ASM-02 · apps/api/app/dependencias.py (presentation), apps/api/app/interfaz/reservas.py (presentation), apps/api/app/interfaz/notificaciones.py (presentation), apps/api/app/interfaz/espacios.py (presentation), apps/api/app/interfaz/sesion.py (presentation), apps/api/app/interfaz/sedes.py (presentation), apps/api/app/interfaz/recuperacion.py (presentation), apps/api/app/interfaz/horarios.py (presentation), apps/api/app/interfaz/registro.py (presentation), apps/api/app/interfaz/pruebas.py (data) · tests: apps/api/tests/unit/test_repositorios_inyectados.py "ninguna ruta construye un repositorio ni un servicio de infraestructura @ARQ-01-S1 @assumption:ARQ-01-ASM-01"; apps/api/tests/unit/test_repositorios_inyectados.py "una ruta recibe su repositorio por dependencia y un test lo reemplaza @ARQ-01-S2"; apps/api/tests/unit/test_repositorios_inyectados.py "una ruta con dos repositorios los arma sobre la misma conexión @ARQ-01-ASM-02"

## Changes to existing behavior

- `app/dependencias.py` expone un proveedor por repositorio y servicio (`repositorio_reservas`, `repositorio_sedes`, …, `identidad`); las rutas de `app/interfaz/` los reciben con `Depends` en vez de construir `…Sql(conn)` · las respuestas de la API no cambian

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider
lint: sh D:/Temp/w/herramientas/arq01-lint.sh apps/api/app apps/api/tests
app: sh D:/Temp/w/herramientas/arq01-app.sh arq01_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh arq01_app --json --no-ambient --common-headers "X-Request-ID, Content-Security-Policy" --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo
mutate apps/api/app/dependencias.py: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -x tests/unit/test_repositorios_inyectados.py
no-visual: recuperacion.py arma una página HTML, pero la card sólo cambia cómo recibe sus repositorios; ninguna pantalla cambia
```

## Log

- L1 · por que no se uso inyeccion de dependencias para manejar la clean architecture? · (sobre la propuesta: A. Proveedores con `Depends`: `dependencias.py` expone `def repo_reservas(conn) -> Reservas`, y la ruta recibe un `Reservas` en vez de construir `ReservasSql`) hace los cambios A y B
- L3 · 2026-10-25 · declared · mutate · apps/api/app/interfaz/reservas.py · la card sólo cambia de dónde salen sus repositorios; lo que la ruta hace lo cubren los escenarios de CU-09, CU-10, CU-11, CU-14 y CU-15 de la suite
- L4 · 2026-10-25 · declared · K4 · apps/api/app/interfaz/reservas.py · cancelar y anular declaran los mismos parámetros (perfil, repositorio, id, tareas, canal): FastAPI lee las dependencias de la firma de cada ruta
