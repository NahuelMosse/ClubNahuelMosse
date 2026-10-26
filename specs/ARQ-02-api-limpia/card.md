# ARQ-02 · API limpia: librerías, sin duplicados y ordenada

card: ARQ-02
status: proposed
cap: 4 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-25): «veo varias cosas en el codigo que reinventan la rueda, si hay una libreria que lo hace, ponela, asi simplificamos el codigo, quiero que sea legible», «bueno si podemos reducir lineas de codigo agregando librerias o no repitiendo codigo, lo agradeceria» y «lo que se puede manejar con librerias se hace con librerias, lo que esta duplicado se comparte y lo demas se lo deja limpio y bien ordenado»"
  - "relevamiento · lectura completa de los 66 archivos de apps/api/app (2026-10-25): errores del dominio atrapados ruta por ruta, commit/rollback repetido en los repositorios, filas copiadas campo por campo, mapeos a modelos de vista, `_leer_hora` triplicado, dos zonas del club, métricas Prometheus a mano"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "lo que se puede manejar con librerias se hace con librerias" · acceptance: las métricas de `/metrics` salen de `prometheus-client` con las mismas series (`solicitudes_total` por método, ruta y código, `solicitud_segundos` por ruta, el uso del pool); los errores del dominio que se responden igual en toda la API los convierte un manejador de excepciones de FastAPI; las filas pasan a objetos del dominio con `**fila._mapping` y a modelos de vista con `model_validate`
- S2 · "lo que esta duplicado se comparte" · acceptance: el commit y el rollback de los repositorios viven en un solo lugar; la zona horaria del club, el lector de horas `HH:MM`, el identificador de ruta y el armado de la agenda de una sede se definen una vez
- S3 · "lo demas se lo deja limpio y bien ordenado" · acceptance: las respuestas de la API no cambian (el contrato `openapi.json` queda idéntico) y las rutas quedan en recibir, llamar al caso de uso y responder
- ARQ-02-ASM-01 · los errores que se responden igual en toda la API son `DatosInvalidos` → 422 `{"errores": {campo: mensaje}}` (20 rutas), `Prohibido` → 403 sin cuerpo (14) y `NoEncontrada` → 404 sin cuerpo (9); una ruta que hoy responde otra cosa para uno de ellos la sigue respondiendo ella. `NoAutenticado` y `Demorado` se atrapan en un solo lugar cada uno y quedan ahí; los que cambian por ruta (`NoDisponible`, `Duplicado`, `Cambiado`, `ConReservasFuturas`, `HorarioOcupado`) siguen en su ruta · S1,S3
- ARQ-02-ASM-02 · `prometheus-client` usa un registro propio de la API, no el global de la librería, para que cada `crear_app` empiece con las series vacías como hoy · S1
- ARQ-02-ASM-03 · quedan propios, porque la librería cambiaría lo que la API responde o pierde algo: el límite de pedidos (`slowapi` cambia el 429 y tomaría el primer `X-Forwarded-For`, que el cliente puede falsificar), el filtro de Host (el de Starlette responde texto plano y no exime `/health` ni `/ready`), el cursor de páginas, el formato JSON de los logs (lo propio es elegir los campos; el JSON ya sale de `json.dumps`) y la validación de correo (`email-validator` rechaza los dominios `.test`); `email-validator` deja de ser dependencia porque nadie la importa · S1
- ARQ-02-ASM-04 · los modelos de error de `openapi.json` (`Errores`, `ErroresDeCampo`, …) no se unifican: renombrarían componentes del contrato publicado, que un test fija · S3

## Tasks

- T1 · S1,S3,ARQ-02-ASM-01,ARQ-02-ASM-04 · apps/api/app/main.py (presentation), apps/api/app/interfaz/errores_http.py (presentation), apps/api/app/interfaz/respuestas.py (presentation), apps/api/app/interfaz/reservas.py (presentation), apps/api/app/interfaz/sedes.py (presentation), apps/api/app/interfaz/espacios.py (presentation), apps/api/app/interfaz/horarios.py (presentation), apps/api/app/interfaz/notificaciones.py (presentation), apps/api/app/interfaz/sesion.py (presentation), apps/api/app/interfaz/registro.py (presentation), apps/api/app/interfaz/recuperacion.py (presentation), apps/api/app/interfaz/entradas.py (presentation), apps/api/app/interfaz/pruebas.py (data) · tests: apps/api/tests/unit/test_api_limpia.py "ninguna ruta atrapa los errores que se responden igual en toda la API @ARQ-02-S2 @assumption:ARQ-02-ASM-01"; apps/api/tests/unit/test_api_limpia.py "datos inválidos responde 422 con sus errores, prohibido 403 y no encontrada 404, sin cuerpo @ARQ-02-S1 @assumption:ARQ-02-ASM-01"; apps/api/tests/unit/test_api_limpia.py "el contrato publicado no cambia @ARQ-02-S3 @assumption:ARQ-02-ASM-04"
- T2 · S1,S2 · apps/api/app/infraestructura/db.py (data), apps/api/app/infraestructura/reservas.py (data), apps/api/app/infraestructura/sedes.py (data), apps/api/app/infraestructura/espacios.py (data), apps/api/app/infraestructura/usuarios.py (data), apps/api/app/infraestructura/notificaciones.py (data), apps/api/app/infraestructura/enlaces.py (data), apps/api/app/infraestructura/horarios.py (data) · tests: apps/api/tests/unit/test_api_limpia.py "los repositorios confirman y deshacen en un solo lugar @ARQ-02-S2"
- T5 · S2 · apps/api/app/infraestructura/db.py (data) · tests: apps/api/tests/integracion/test_api_limpia_persistencia.py "una sede dada de alta sobrevive a reiniciar la API sobre la misma base @ARQ-02-S2"
- T3 · S2 · apps/api/app/dominio/notificaciones.py (rule), apps/api/app/dominio/horarios.py (rule), apps/api/app/dominio/sedes.py (rule) · tests: apps/api/tests/unit/test_api_limpia.py "la zona del club, el lector de horas y el identificador se definen una vez @ARQ-02-S2"
- T4 · S1,ARQ-02-ASM-02,ARQ-02-ASM-03 · apps/api/app/interfaz/metricas.py (presentation), apps/api/pyproject.toml, apps/api/uv.lock · tests: apps/api/tests/unit/test_api_limpia.py "las métricas salen de prometheus-client con las mismas series y un registro propio @ARQ-02-S1 @assumption:ARQ-02-ASM-02"; apps/api/tests/unit/test_api_limpia.py "email-validator deja de ser dependencia y nadie la importa @assumption:ARQ-02-ASM-03"

## Changes to existing behavior

- Ninguna respuesta de la API cambia; `openapi.json` queda igual
- `/metrics` agrega las series `_created` que publica `prometheus-client`; las de hoy siguen con los mismos nombres y etiquetas
- `apps/api/pyproject.toml`: suma `prometheus-client` y saca `email-validator`

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider
lint: sh D:/Temp/w/herramientas/ruff-mypy-api-arq02.sh apps/api/app apps/api/tests
app: sh D:/Temp/w/herramientas/arq01-app.sh arq02_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh arq02_app --json --no-ambient --common-headers "X-Request-ID, Content-Security-Policy" --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
migrate-upgrade: cd apps/api && sh -c "DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8701/club_arq02_migra uv run --no-sync alembic upgrade head"
mutate apps/api/app/infraestructura/db.py: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -x tests/unit/test_api_limpia.py tests/integracion/test_reservas_api.py
mutate apps/api/app/dominio/horarios.py: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -x tests/unit
no-visual: recuperacion.py arma una página HTML, pero la card sólo cambia cómo responde sus errores; ninguna pantalla cambia
```

## Log

- L1 · veo varias cosas en el codigo que reinventan la rueda, si hay una libreria que lo hace, ponela, asi simplificamos el codigo, quiero que sea legible · bueno si podemos reducir lineas de codigo agregando librerias o no repitiendo codigo, lo agradeceria · sino podemos simplemente hacer que el codigo sea mas limpio y este mas organizado? · lo que se puede manejar con librerias se hace con librerias, lo que esta duplicado se comparte y lo demas se lo deja limpio y bien ordenado
- L2 · 2026-10-25 · declared · mutate · apps/api/app/interfaz/reservas.py · la card sólo cambia cómo convierte los errores comunes; lo que la ruta hace lo cubren los escenarios de CU-09, CU-10, CU-11, CU-14 y CU-15 de la suite
- L3 · 2026-10-25 · declared · unique · S2 habla de código duplicado, no de registros duplicados: la card no cambia ninguna regla de unicidad de datos
- L4 · 2026-10-25 · declared · fault-db · los repositorios sólo cambian dónde confirman y deshacen; el comportamiento ante una base caída lo cubren los escenarios de REV-02 (`base-caida`, `/ready` 503) de la suite
- L5 · 2026-10-25 · declared · restart · la card no cambia qué se guarda ni cómo: no hay registro nuevo que tenga que sobrevivir a un reinicio
- L6 · 2026-10-25 · declared · migrate-upgrade · la card no agrega ni toca migraciones
- L7 · 2026-10-25 · declared · ARQ-02-ASM-03 · el 429 de esta suposición es el que ya responde el límite de pedidos, que la card no toca; lo cubren los escenarios de REV-01 (`demasiados-pedidos`) de la suite
- L8 · 2026-10-25 · declared · ARQ-02-ASM-01 · 20, 14 y 9 son las rutas que hoy atrapan cada error; el test estático de S2 comprueba que ninguna lo siga haciendo
