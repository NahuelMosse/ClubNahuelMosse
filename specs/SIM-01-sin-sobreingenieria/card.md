# SIM-01 · sin sobreingeniería de producción

status: proposed
cap: 6 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-26): «despues de terminar esto, podrias borrar la sobreingenieria que se hizo por esta en nivel produccion porfa» · «No se fijate que cosas son sobreingenieria, el punto es que es dificil de entender, principalmente porque es un TP de la facu, asi que limpia todo lo que este sobreestimado, sobreingenierado para un TP de la facu» · «por que esta en nivel produccion, siempre dije que queria en nivel MVP»"
  - "enunciado · ../Trabajo Práctico_2026.docx.pdf: pide Swagger/OpenAPI, base relacional, nube, README y los errores de sin conexión, servidor caído, login incorrecto y usuario ya registrado; no pide métricas, límites de pedidos, logs, respaldos ni rendimiento"
  - "relevamiento · inventario de lo que agregaron REV-01, REV-02 y REV-03 por el grado production, con los archivos de código, tests, configuración y documentación de cada cosa (2026-10-26)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "limpia todo lo que este sobreestimado, sobreingenierado para un TP de la facu" · acceptance: la API no tiene `/metrics` ni `prometheus-client`, límite de pedidos (429), CSP ni filtro de Host, `X-Request-ID` ni logs en JSON con referencia de error, tiempos de espera de la base con 503, chequeo del emulador contra credenciales reales, scripts de respaldo ni de usuario de base con privilegios mínimos, generador de avisos de terceros ni `THIRD_PARTY_NOTICES.md`, paginación por marcador, `/ready`, reintentos de avisos, ni topes de largo y de caracteres de control en las entradas; la app no tiene el aviso «despertando», la espera de 60 s, la captura de errores no manejados ni la pantalla de error de arranque
- S2 · "el punto es que es dificil de entender, principalmente porque es un TP de la facu" · acceptance: lo que queda hace lo que piden los casos de uso igual que antes (la suite de lo que sigue pasa), sin código, configuración ni documentación de lo que se sacó
- S3 · "La API REST deberá estar documentada mediante Swagger/OpenAPI" (enunciado) · acceptance: `/docs` y `/openapi.json` responden en todos los entornos, también con la configuración de `render.yaml`
- S4 · "sin conexión a internet, servidor caído" (enunciado) · acceptance: la app sigue mostrando los avisos de sin conexión y de servidor que no responde
- SIM-01-ASM-01 · el historial propio (`GET /reservas?cuando=…`) devuelve todas las reservas del período, ordenadas como hoy, sin `despues` ni `siguiente` (el CU-08 pide «listado ordenadas por fecha» y no pagina); el historial del administrador (`GET /reservas/todas`) conserva su `pagina` con `OFFSET` · S1
- SIM-01-ASM-02 · un aviso se toma una vez (`enviando`, que evita mandarlo dos veces) y queda `enviada` o `fallida`; no se reintenta ni se recupera uno atascado en `enviando`. Las columnas `intentos` y `tomada_en` se borran con una migración nueva, porque las ya aplicadas no se editan · S1
- SIM-01-ASM-03 · un error no previsto responde 500 con el manejo por defecto de FastAPI, sin cuerpo propio ni referencia · S1
- SIM-01-ASM-04 · la app espera una respuesta de la API hasta 30 s y después muestra el aviso de servidor que no responde; ya no hay aviso intermedio · S4
- SIM-01-ASM-05 · las validaciones que piden los casos de uso se quedan: campos obligatorios, formatos, horas de 1 a 4, fechas; salen sólo los topes de largo máximo y el rechazo de caracteres de control · S1
- SIM-01-ASM-06 · `registrarError` de la app pasa a `debugPrint`: los lugares que lo llaman siguen avisando en la consola de desarrollo · S1
- SIM-01-ASM-07 · la migración 0009 pasa a `fallida` los avisos que estén en `enviando` al migrar (como hizo la 0006) y después borra `intentos` y `tomada_en`; sin eso, nada los recuperaría · S1

## Tasks

- T1 · S1,S2,SIM-01-ASM-03 · apps/api/app/main.py (presentation), apps/api/app/config.py (data), apps/api/app/dependencias.py (presentation), apps/api/app/interfaz/metricas.py (presentation), apps/api/app/interfaz/limites.py (presentation), apps/api/app/interfaz/protecciones.py (presentation), apps/api/app/interfaz/registro_errores.py (presentation), apps/api/app/interfaz/salud.py (presentation), apps/api/app/interfaz/registro.py (presentation), apps/api/app/interfaz/recuperacion.py (presentation), apps/api/app/interfaz/sesion.py (presentation), apps/api/app/infraestructura/db.py (data), apps/api/pyproject.toml, apps/api/uv.lock, render.yaml · tests: apps/api/tests/unit/test_sin_sobreingenieria.py "la API no publica métricas, no limita pedidos ni agrega encabezados de seguridad, id de pedido ni /ready @SIM-01-S1"; apps/api/tests/unit/test_sin_sobreingenieria.py "un error no previsto responde 500 sin cuerpo propio @SIM-01-S1 @assumption:SIM-01-ASM-03"; apps/api/tests/unit/test_sin_sobreingenieria.py "prometheus-client deja de ser dependencia @SIM-01-S2"; apps/api/tests/unit/test_sin_sobreingenieria.py "la API no tiene tiempos de espera de la base, chequeo del emulador, filtro de Host ni logs en JSON @SIM-01-S1"; apps/api/tests/unit/test_sin_sobreingenieria.py "el contrato no anuncia el 429 del límite de pedidos ni el 503, y sigue el 429 de Firebase al iniciar sesión @SIM-01-S1"
  reuses: el manejo de errores y la documentación por defecto de FastAPI (`FastAPI(docs_url, openapi_url)`, `HTTPException`)
- T2 · S3 · apps/api/app/main.py (presentation), apps/api/app/config.py (data), render.yaml · tests: apps/api/tests/unit/test_sin_sobreingenieria.py "/docs y /openapi.json responden también con la configuración de render.yaml, sin opción para apagarlos @SIM-01-S3"
  reuses: apps/api/app/main.py crear_app (sin `config.documentacion_interactiva`)
- T3 · S1,SIM-01-ASM-05 · apps/api/app/interfaz/entradas.py (presentation), apps/api/app/interfaz/espacios.py (presentation), apps/api/app/interfaz/horarios.py (presentation), apps/api/app/interfaz/notificaciones.py (presentation), apps/api/app/interfaz/reservas.py (presentation), apps/api/app/interfaz/sedes.py (presentation) · tests: apps/api/tests/unit/test_sin_sobreingenieria.py "un texto largo o con caracteres de control ya no se rechaza y las horas siguen siendo de 1 a 4 @SIM-01-S1 @assumption:SIM-01-ASM-05"
  reuses: apps/api/app/interfaz/entradas.py leer_hora, Identificador, errores_de_forma
- T4 · S1,SIM-01-ASM-01 · apps/api/app/dominio/reservas.py (rule), apps/api/app/aplicacion/reservas.py (rule), apps/api/app/infraestructura/reservas.py (data), apps/api/app/interfaz/reservas.py (presentation), apps/api/app/interfaz/marcador.py (presentation) · tests: apps/api/tests/integracion/test_sin_sobreingenieria_api.py "el historial propio es el listado ordenadas por fecha, entero y sin marcador @SIM-01-S1 @assumption:SIM-01-ASM-01"; apps/api/tests/integracion/test_sin_sobreingenieria_api.py "el historial del administrador sigue paginando por número de página @SIM-01-S2 @assumption:SIM-01-ASM-01"; apps/api/tests/integracion/test_sin_sobreingenieria_api.py "una reserva sobrevive a reiniciar la API sobre la misma base @SIM-01-S2"
  reuses: apps/api/app/infraestructura/reservas.py historial (la `pagina` con `OFFSET` del historial global)
- T5 · S1,SIM-01-ASM-02 · apps/api/app/dominio/notificaciones.py (rule), apps/api/app/aplicacion/notificaciones.py (rule), apps/api/app/infraestructura/notificaciones.py (data), apps/api/migraciones/versions/0009_avisos_sin_reintentos.py (data) · tests: apps/api/tests/integracion/test_sin_sobreingenieria_api.py "un aviso que falla queda fallido y no se vuelve a intentar @SIM-01-S1 @assumption:SIM-01-ASM-02"; apps/api/tests/integracion/test_sin_sobreingenieria_api.py "la base ya no tiene intentos ni tomada_en en notificacion @assumption:SIM-01-ASM-02"; apps/api/tests/integracion/test_sin_sobreingenieria_api.py "la migración 0009 pasa a fallida un aviso que estaba enviando @assumption:SIM-01-ASM-07"
  reuses: apps/api/app/infraestructura/notificaciones.py tomar_siguiente (el estado `enviando` como toma)
- T6 · S1,S2 · apps/api/scripts/respaldo.py (data), apps/api/scripts/usuario_de_la_app.py (data), apps/api/scripts/avisos_de_terceros.py (data), THIRD_PARTY_NOTICES.md, README.md, apps/api/README.md, docs/technical/runbook.md, docs/technical/system-design.md, docs/technical/arquitectura.md, docs/technical/mapa-del-codigo.md, sitio-docs/docs/ · tests: apps/api/tests/unit/test_sin_sobreingenieria.py "no quedan scripts, avisos de terceros ni documentación de lo que se sacó @SIM-01-S2"
  reuses: los documentos existentes, recortados
- T7 · S1,S4,SIM-01-ASM-04,SIM-01-ASM-06 · apps/mobile/lib/main.dart (presentation), apps/mobile/lib/app.dart (presentation), apps/mobile/lib/api/cliente_api.dart (data), apps/mobile/lib/comun/aviso_despertando.dart (presentation), apps/mobile/lib/comun/pantalla_error_de_arranque.dart (presentation), apps/mobile/lib/comun/errores_no_manejados.dart (presentation), apps/mobile/lib/comun/dialogo_error.dart (presentation) · tests: apps/mobile/test/sin_sobreingenieria_test.dart "la app no avisa que el servidor despierta ni captura errores no manejados @SIM-01-S1"; apps/mobile/test/sin_sobreingenieria_test.dart "a los 30 s sin respuesta la app avisa que el servidor no responde @SIM-01-S4 @assumption:SIM-01-ASM-04"; apps/mobile/test/sin_sobreingenieria_test.dart "sin conexión la app lo avisa @SIM-01-S4"; apps/mobile/test/sin_sobreingenieria_test.dart "registrarError escribe en la consola de desarrollo @assumption:SIM-01-ASM-06"; apps/mobile/test/sin_sobreingenieria_test.dart "la app arranca sin pantalla de error de arranque @SIM-01-S1"
  reuses: apps/mobile/lib/api/cliente_api.dart SinConexion, ServidorSinRespuesta; apps/mobile/lib/comun/dialogo_error.dart
- T8 · S1,SIM-01-ASM-01 · apps/mobile/lib/reservas/reservas.dart (data), apps/mobile/lib/reservas/pantalla_mis_reservas.dart (presentation), apps/mobile/lib/inicio/pantalla_inicio.dart (presentation), apps/mobile/lib/admin/historial_reservas.dart (data) · tests: apps/mobile/test/sin_sobreingenieria_test.dart "mis reservas trae la lista entera de una vez @SIM-01-S1 @assumption:SIM-01-ASM-01"
  reuses: apps/mobile/lib/reservas/reservas.dart el pedido de `GET /reservas`

## Changes to existing behavior

- `GET /metrics`, `GET /ready` · dejan de existir (404)
- límite de pedidos · ya no hay 429 de la API; el 429 de Firebase al iniciar sesión sigue
- encabezados `Content-Security-Policy`, `X-Request-ID` y filtro de Host · dejan de agregarse o aplicarse
- un error no previsto · 500 por defecto de FastAPI, sin referencia
- base que no responde · ya no hay 503 propio; el error que dé la conexión
- `GET /reservas` · sin `despues` y sin `siguiente`: devuelve la lista entera del período
- notificaciones · un envío que falla queda `fallida`, sin reintentos; la migración 0009 borra `intentos` y `tomada_en`
- entradas · sin topes de largo ni rechazo de caracteres de control
- `render.yaml` · `/docs` queda encendido; sin `DATABASE_URL_APP`, `METRICAS_TOKEN` ni ajustes de proxy; el chequeo de salud es `/health`
- app · sin aviso «despertando», sin pantalla de error de arranque; espera 30 s antes de avisar que el servidor no responde
- los tests de lo que sale se borran (L2)

## Look

- ref: specs/SIM-01-sin-sobreingenieria/ref/app-actual.png
- behavior: none · se sacan el aviso «despertando» y la pantalla de error de arranque; el resto de las pantallas se ve igual
- tokens: los de la app, en apps/mobile/lib/tema/tokens.dart
- copy: los textos actuales de la app

## Gate

```
suite: sh D:/Temp/w/herramientas/sim01-suite.sh
lint: sh D:/Temp/w/herramientas/sim01-lint.sh
app: sh D:/Temp/w/herramientas/arq01-app.sh sim01_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh sim01_app --json --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
captures: sh D:/Temp/w/herramientas/arq03-capturas.sh
migrate-upgrade: cd apps/api && sh -c "DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8701/club_sim01_migra uv run --no-sync alembic upgrade head"
mutate apps/api/app/dominio/reservas.py: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -x tests/unit
mutate apps/api/app/dominio/notificaciones.py: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -x tests/unit/test_despacho_de_confirmaciones.py tests/unit/test_mensaje_cancelacion_forzosa.py tests/unit/test_recordatorios.py
```

## Log

- L1 · despues de terminar esto, podrias borrar la sobreingenieria que se hizo por esta en nivel produccion porfa · No se fijate que cosas son sobreingenieria, el punto es que es dificil de entender, principalmente porque es un TP de la facu, asi que limpia todo lo que este sobreestimado, sobreingenierado para un TP de la facu · por que esta en nivel produccion, siempre dije que queria en nivel MVP
- L2 · 2026-10-26 · la persona decidió borrar los tests de lo que se saca («Borrarlos»), en vez de dejarlos en el repo como reemplazados: un archivo congelado que mezcla tests que siguen con tests que salen se reescribe en un archivo nuevo con los que siguen, con su nombre y sus tags, y el viejo se borra
- L3 · 2026-10-26 · el grado del kit pasó a `mvp` (la persona, `kit.json`): la mutación es sólo del dominio
- L4 · 2026-10-26 · declared · S3 · la única «lista» de S3 son `/docs` y `/openapi.json`, que verifica un solo test; «despertando» y «listado ordenadas por fecha» son de S1 y ASM-01
- L5 · 2026-10-26 · declared · SIM-01-ASM-01 · «08» no es un valor del supuesto sino parte de «CU-08»
- L6 · 2026-10-26 · declared · fault-db · la base es Postgres, no un archivo; que la API siga funcionando con su base lo cubre la suite de integración
- L7 · 2026-10-26 · declared · mutate · apps/api/app/main.py · el grado mvp muta sólo el dominio, y main.py sólo arma la app; lo que deja de agregar lo verifican los tests de T1 y T2
- L8 · 2026-10-26 · declared · SIM-01-ASM-07 · «0006» es la migración que se toma como antecedente, no un valor que la 0009 deba producir
- L9 · 2026-10-26 · plan judge: ACT-01..04 cerrados con tests nuevos en T1, T2, T5 y T7 y SIM-01-ASM-07; ver judge.md
- L10 · 2026-10-26 · replaces: tests/unit/{test_limites,test_protecciones,test_registro_errores,test_api_limpia_metricas,test_marcador}.py y tests/integracion/test_registro_de_errores_api.py · probaban módulos retirados por T1/T3/T4 · by: git rm, sin reemplazo (T1, T4 prueban su ausencia)
- L11 · 2026-10-26 · replaces: tests/unit/test_entradas.py (alias Texto40/Texto120/Busqueda/Correo/Clave/Codigo/TokenDeDispositivo/Parrafo y sus topes) · T3 los retiró · by: tests/unit/test_entradas.py (sólo Identificador y errores_de_forma)
- L12 · 2026-10-26 · replaces: tests/escenarios/test_datos_tandas_y_cola.py «tandas de 20», «no aparece en tandas ya vistas», «página avanzada», «marcador a mano», «OpenAPI documenta despues/siguiente» · T4 quitó el marcador · by: tests/escenarios/test_datos_tandas_y_cola.py (conserva empate, contadores, próximas, migración 0008 y avisos; historial propio sin tandas)
- L13 · 2026-10-26 · T4 · test_casos_de_uso_reservas.py adaptado a `de_usuario(usuario_id, cuando) -> list[Reserva]`; apps/api/openapi.json regenerado (README, comando de «Contrato»); .env.example ya estaba limpio
- L14 · 2026-10-26 · gate red · suite API incompleta · la suite se cuelga en tests/escenarios/test_operacion.py (503 por pool/bloqueo/timeout, /ready, /metrics: prueban lo retirado en T1); 121 pasan, 27 fallan antes del cuelgue (13 test_datos.py, 4 test_datos_tandas_y_cola, 3 test_operacion y otros por /metrics, /ready, 429/503); falta reescribir test_operacion.py y afines por L2
