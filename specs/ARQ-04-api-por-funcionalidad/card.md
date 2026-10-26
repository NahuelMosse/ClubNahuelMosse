# ARQ-04 · la API agrupada por funcionalidad

status: proposed
cap: 8 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-26): «hay algo que se deberia seguir siempre que son las vertical slices, osea que se agrupa en carpeta por funcionalidad, asi queda mas ordenado y se puede separar mas facilmente en pedacitos»"
  - "kit · .claude/rules/architecture.md («Simplest structure that works», «Structure: vertical slices») y .claude/reference/structure.md: carpetas `modules/<feature>/`, un `shared/` chico, sin domain/application/infrastructure arriba, capas adentro sólo si hacen falta"
  - "relevamiento · plan de la reorganización sobre el código de card/SIM-01 (2026-10-26): árbol destino, mapeo de cada archivo, dos ciclos entre funcionalidades a cortar, 68 archivos de tests que importan las rutas viejas (24 congelados), 4 nombres de esquema del contrato que llevan la ruta del módulo"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "se agrupa en carpeta por funcionalidad" · acceptance: apps/api/app tiene `main.py`, `salud.py`, `pruebas.py`, `shared/` y `modules/<funcionalidad>/` (sedes, espacios, horarios, reservas, notificaciones, usuarios, sesion, recuperacion); no existen `dominio/`, `aplicacion/`, `infraestructura/`, `interfaz/` ni `dependencias.py`
- S2 · "asi queda mas ordenado y se puede separar mas facilmente en pedacitos" · acceptance: una funcionalidad importa otra sólo por su `__init__`; `shared/` no importa ninguna funcionalidad; no hay ciclos entre funcionalidades; `reglas.py` no importa base de datos ni web; `casos_de_uso.py` no importa `repositorio` ni `rutas`
- S3 · "vertical slices" (que el cambio sea sólo de lugar) · acceptance: la API responde igual: mismas rutas, mismos códigos y mismos cuerpos; la suite que pasaba sigue pasando
- ARQ-04-ASM-01 · las carpetas de arriba se llaman `modules/` y `shared/` en inglés porque las herramientas del kit leen esos nombres; las funcionalidades y sus archivos van en castellano · S1
- ARQ-04-ASM-02 · cada funcionalidad es plana: `rutas.py`, `casos_de_uso.py`, `reglas.py` (las reglas que se prueban sin base) y `repositorio.py`, más los archivos propios que ya tenía (por ejemplo `barrido.py`, `push.py`); ninguna lleva carpetas de capas · S1
- ARQ-04-ASM-03 · `sesion` es su propia funcionalidad (Perfil, Rol, usuario actual) y lee la tabla `usuario` sin escribirla; así todas usan la sesión sin el ciclo con usuarios · S2
- ARQ-04-ASM-04 · el ciclo reservas ↔ notificaciones se corta con un `Protocol` local en notificaciones (los datos de la reserva que un aviso necesita), y el de reservas ↔ usuarios porque usuarios usa reservas y no al revés · S2
- ARQ-04-ASM-05 · cuatro esquemas del contrato llevaban la ruta del módulo en el nombre (`app__interfaz__reservas__PedidoDeCambio` y tres más); pasan a nombres de clase únicos (`PedidoDeCambioDeReserva`, `PedidoDeCambioDeEspacio`, `PedidoDeEdicionDeSede`, `PedidoDeEdicionDePerfil`); rutas, códigos y formas no cambian · S3
- ARQ-04-ASM-06 · los errores comunes (`DatosInvalidos`, `Prohibido`, `NoEncontrada`, …) van todos a `shared/errores.py`; repartirlos por funcionalidad queda fuera · S1
- ARQ-04-ASM-07 · los tests congelados que importan rutas viejas se reescriben con el mismo nombre de archivo, los mismos títulos y tags, cambiando sólo lo que apunta a la ruta vieja (`git rm` y archivo nuevo); los que afirman la estructura por capas (REV-06 y ARQ-01/02) pasan a afirmar la de funcionalidades, con su `replaces:` en el Log · S3

## Tasks

- T1 · S1,S2,ARQ-04-ASM-01,ARQ-04-ASM-02,ARQ-04-ASM-07 · apps/api/tests/unit/test_arquitectura.py, apps/api/tests/unit/test_mapa_por_funcionalidad.py · tests: apps/api/tests/unit/test_arquitectura.py "arriba sólo quedan main, salud, pruebas, shared y modules @ARQ-04-S1 @assumption:ARQ-04-ASM-01"; apps/api/tests/unit/test_arquitectura.py "cada funcionalidad es plana, con rutas, casos de uso, reglas y repositorio @ARQ-04-S1 @assumption:ARQ-04-ASM-02"; apps/api/tests/unit/test_arquitectura.py "una funcionalidad importa otra sólo por su __init__ y no hay ciclos @ARQ-04-S2"; apps/api/tests/unit/test_arquitectura.py "shared no importa funcionalidades y reglas no importa base de datos ni web @ARQ-04-S2"; apps/api/tests/unit/test_arquitectura.py "casos_de_uso no importa repositorio ni rutas @ARQ-04-S2"; apps/api/tests/unit/test_arquitectura.py "ningún test importa las rutas viejas de capas @ARQ-04-S3 @assumption:ARQ-04-ASM-07"
- T2 · S1,ARQ-04-ASM-03,ARQ-04-ASM-06 · apps/api/app/shared/config.py (data), apps/api/app/shared/db.py (data), apps/api/app/shared/errores.py (rule), apps/api/app/shared/errores_http.py (presentation), apps/api/app/shared/entradas.py (presentation), apps/api/app/shared/respuestas.py (presentation), apps/api/app/shared/cuerpo.py (presentation), apps/api/app/shared/zona.py (rule), apps/api/app/shared/identidad.py (data), apps/api/app/shared/credencial_firebase.py (data), apps/api/app/modules/sesion/__init__.py (presentation), apps/api/app/modules/sesion/perfil.py (rule), apps/api/app/modules/sesion/casos_de_uso.py (rule), apps/api/app/modules/sesion/usuario_actual.py (presentation), apps/api/app/modules/sesion/repositorio.py (data), apps/api/migraciones/env.py (data) · tests: apps/api/tests/unit/test_arquitectura.py "sesion lee la tabla usuario sin escribirla @assumption:ARQ-04-ASM-03"; apps/api/tests/unit/test_arquitectura.py "los errores comunes viven en shared/errores.py @assumption:ARQ-04-ASM-06"
  reuses: apps/api/app/config.py, apps/api/app/infraestructura/db.py, apps/api/app/dominio/errores.py, apps/api/app/interfaz/entradas.py, apps/api/app/interfaz/errores_http.py, apps/api/app/interfaz/respuestas.py, apps/api/app/interfaz/cuerpo.py (movidos con git mv)
- T3 · S1,S2 · apps/api/app/modules/espacios/__init__.py (presentation), apps/api/app/modules/espacios/rutas.py (presentation), apps/api/app/modules/espacios/casos_de_uso.py (rule), apps/api/app/modules/espacios/reglas.py (rule), apps/api/app/modules/espacios/repositorio.py (data), apps/api/app/modules/sedes/__init__.py (presentation), apps/api/app/modules/sedes/rutas.py (presentation), apps/api/app/modules/sedes/casos_de_uso.py (rule), apps/api/app/modules/sedes/reglas.py (rule), apps/api/app/modules/sedes/repositorio.py (data), apps/api/app/modules/horarios/__init__.py (presentation), apps/api/app/modules/horarios/rutas.py (presentation), apps/api/app/modules/horarios/casos_de_uso.py (rule), apps/api/app/modules/horarios/disponibilidad.py (rule), apps/api/app/modules/horarios/reglas.py (rule), apps/api/app/modules/horarios/repositorio.py (data) · tests: apps/api/tests/unit/test_arquitectura.py "una funcionalidad importa otra sólo por su __init__ y no hay ciclos @ARQ-04-S2"
  reuses: los archivos de espacios, sedes y horarios de cada capa, movidos con git mv
- T4 · S1,S2,ARQ-04-ASM-04 · apps/api/app/modules/notificaciones/__init__.py (presentation), apps/api/app/modules/notificaciones/rutas.py (presentation), apps/api/app/modules/notificaciones/casos_de_uso.py (rule), apps/api/app/modules/notificaciones/almacen.py (rule), apps/api/app/modules/notificaciones/reglas.py (rule), apps/api/app/modules/notificaciones/repositorio.py (data), apps/api/app/modules/notificaciones/barrido.py (presentation), apps/api/app/modules/notificaciones/push.py (data), apps/api/app/modules/reservas/__init__.py (presentation), apps/api/app/modules/reservas/rutas.py (presentation), apps/api/app/modules/reservas/casos_de_uso.py (rule), apps/api/app/modules/reservas/almacen.py (rule), apps/api/app/modules/reservas/reglas.py (rule), apps/api/app/modules/reservas/repositorio.py (data) · tests: apps/api/tests/unit/test_arquitectura.py "notificaciones no importa reservas: el aviso recibe los datos que necesita @ARQ-04-S2 @assumption:ARQ-04-ASM-04"
  reuses: los archivos de notificaciones y reservas de cada capa, movidos con git mv
- T5 · S1,S3,ARQ-04-ASM-05 · apps/api/app/modules/usuarios/__init__.py (presentation), apps/api/app/modules/usuarios/rutas_cuenta.py (presentation), apps/api/app/modules/usuarios/rutas_registro.py (presentation), apps/api/app/modules/usuarios/registro.py (rule), apps/api/app/modules/usuarios/perfil.py (rule), apps/api/app/modules/usuarios/contrasena.py (rule), apps/api/app/modules/usuarios/baja.py (rule), apps/api/app/modules/usuarios/administradores.py (rule), apps/api/app/modules/usuarios/sembrar_admin.py (presentation), apps/api/app/modules/usuarios/reglas.py (rule), apps/api/app/modules/usuarios/repositorio.py (data), apps/api/app/modules/recuperacion/__init__.py (presentation), apps/api/app/modules/recuperacion/rutas.py (presentation), apps/api/app/modules/recuperacion/casos_de_uso.py (rule), apps/api/app/modules/recuperacion/reglas.py (rule), apps/api/app/modules/recuperacion/repositorio.py (data), apps/api/app/modules/recuperacion/correo.py (data), apps/api/app/main.py (presentation), apps/api/app/salud.py (presentation), apps/api/app/pruebas.py (presentation), apps/api/openapi.json · tests: apps/api/tests/unit/test_arquitectura.py "los esquemas del contrato tienen nombres de clase, sin la ruta del módulo @ARQ-04-S3 @assumption:ARQ-04-ASM-05"
  reuses: los archivos de usuarios, sesión y recuperación de cada capa, movidos con git mv
- T6 · S3 · docs/technical/mapa-del-codigo.md, docs/technical/arquitectura.md, docs/technical/system-design.md, docs/technical/runbook.md, docs/guia-basica.md, apps/api/README.md, README.md, scripts/e2e.sh (data), .claude/rules/arquitectura.md · tests: apps/api/tests/unit/test_mapa_por_funcionalidad.py "el mapa del código lista cada funcionalidad con sus archivos @ARQ-04-S1"
  reuses: los documentos existentes, con las rutas nuevas

## Changes to existing behavior

- openapi.json · cuatro esquemas cambian de nombre (ARQ-04-ASM-05); rutas, códigos y formas iguales
- comandos `python -m app.interfaz.sembrar_admin` y `python -m app.interfaz.barrido` pasan a `python -m app.modules.usuarios.sembrar_admin` y `python -m app.modules.notificaciones.barrido`
- los tests congelados que importaban rutas viejas se reescriben (ARQ-04-ASM-07)

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests
app: sh D:/Temp/w/herramientas/arq01-app.sh arq04_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh arq04_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
migrate-upgrade: cd apps/api && sh -c "DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8701/club_arq04_migra uv run --no-sync alembic upgrade head"
```

## Log

- L1 · hay algo que se deberia seguir siempre que son las vertical slices, osea que se agrupa en carpeta por funcionalidad, asi queda mas ordenado y se puede separar mas facilmente en pedacitos
- L2 · 2026-10-26 · la card sale de card/SIM-01 antes de que SIM-01 se integre a main, a pedido de la persona («avanza las 4 en paralelo y despues las vas mergeando resolviendo conflictos»)
- L3 · 2026-10-26 · alcance: la app Flutter no entra; ya está por funcionalidad salvo `comun/` y `admin/`, que van en otra card
- L4 · 2026-10-26 · declared · fault-db · la base es Postgres, no un archivo; la suite de integración la usa como siempre
- L5 · 2026-10-26 · declared · ARQ-04-ASM-07 · «06», «01» y «02» son los nombres de las cards REV-06, ARQ-01 y ARQ-02, no valores del supuesto
