# Plan — REV-01 · seguridad de la API

## Time plan

1. Size and risk: unos 19 archivos de producción de la API (config, main, interfaz, aplicación, infraestructura, lock, contrato, render.yaml, README), sin pantalla ni migración · riesgo: seguridad, datos personales y permisos
2. without method: 90–150–240 min · goal: 750 min · cap: 12 h
3. Critical path: tests en rojo → plan → implementer por grupos (entradas y límites; registro y cabeceras; correo, emulador y dispositivos; lock, contrato y despliegue) → verify → juicio · on the side from the start: `uv sync` (hecho), emulador de Auth y Postgres compartidos
4. Split: plan 60 · code 240 · verification 240 · correction 180 min
5. Cut if it does not fit: el contrato OpenAPI versionado puede quedar con el comando que lo genera y su test; nunca un chequeo de la vara

## Verification

```
suite: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider
lint: cd apps/api && uv run --no-sync ruff check . && uv run --no-sync ruff format --check app tests/escenarios/test_seguridad_api.py && uv run --no-sync mypy --strict app
scenarios: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider tests/escenarios --card REV-01
mutate apps/api/app/interfaz/limites.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_seguridad_api.py tests/unit
mutate apps/api/app/interfaz/entradas.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_seguridad_api.py tests/unit
mutate apps/api/app/interfaz/protecciones.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_seguridad_api.py tests/integracion/test_protecciones_api.py
mutate apps/api/app/interfaz/registro_errores.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_seguridad_api.py tests/escenarios/test_registro_de_errores.py
mutate apps/api/app/infraestructura/correo.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_seguridad_api.py
mutate apps/api/app/infraestructura/identidad.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_seguridad_api.py
mutate apps/api/app/infraestructura/notificaciones.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_seguridad_api.py tests/unit
mutate apps/api/app/main.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_seguridad_api.py
mutate apps/api/app/config.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_seguridad_api.py
app: cd apps/api && uv run --no-sync uvicorn app.main:app --host 127.0.0.1 --port $PORT
```

El subconjunto de cada `mutate` es el que llega al archivo: la suite entera tarda de 3 a 8 min y `mutate.mjs` corta a los 10 min por archivo. Si un archivo que la vara pide mutar no tiene un subconjunto que entre en ese tope, queda «no se pudo correr» con el motivo. Los archivos de interfaz que sólo cambian el tipo de un campo (`registro.py`, `recuperacion.py`, `sesion.py`, `sedes.py`, `espacios.py`, `reservas.py`, `notificaciones.py` de interfaz) se mutan si `required.mjs` los pide, con el mismo subconjunto.

## File map

Grupo 1 · entradas y límites
- apps/api/app/interfaz/entradas.py — nuevo: los tipos de texto acotado (`Texto(maximo)`: sin NUL ni caracteres de control, largo máximo) y el manejador de errores de forma que responde `{"errores": {campo: mensaje}}` sin repetir lo recibido · rule · test: apps/api/tests/escenarios/test_seguridad_api.py
- apps/api/app/interfaz/limites.py — nuevo: el límite de frecuencia por ventana deslizante, en memoria de la instancia de la app (`app.state`), con candado; la clave es el origen (ver ASM-11) o la cuenta; responde 429 con `Retry-After` · rule · test: apps/api/tests/escenarios/test_seguridad_api.py
- apps/api/app/interfaz/registro.py — los campos con `Texto`; el límite por origen
- apps/api/app/interfaz/recuperacion.py — los campos con `Texto`; el límite por origen; CSP propia de `/enlace/recuperar` con el hash de su script
- apps/api/app/interfaz/sesion.py — los campos de `PUT /yo` con `Texto`; el límite por cuenta
- apps/api/app/interfaz/sedes.py, apps/api/app/interfaz/espacios.py — los campos de texto con `Texto`
- apps/api/app/interfaz/reservas.py — `horas` 1..4 y `pagina` 1..10000 en el modelo; `q` con `Texto(100)`; motivo con `Texto`
- apps/api/app/aplicacion/reservas.py — la fecha fuera de la ventana de anticipación se rechaza antes de calcular el fin del turno · rule · test: apps/api/tests/escenarios/test_seguridad_api.py

Grupo 2 · registro, cabeceras y arranque
- apps/api/app/interfaz/registro_errores.py — la ruta se escapa (caracteres de control como `\n` literal); un filtro sobre `uvicorn.access` que saca el query string; 429 y 400 por Host se registran como rechazo
- apps/api/app/interfaz/protecciones.py — `Content-Security-Policy: default-src 'none'; frame-ancestors 'none'` en toda respuesta salvo `/docs` y `/redoc` cuando están prendidos; Host fuera de la lista → 400
- apps/api/app/config.py — `documentacion_interactiva: bool = True`, `hosts_permitidos: str` (separados por coma; se suma el host de `url_publica`), `detras_de_proxy: bool = False`
- apps/api/app/main.py — `docs_url`/`redoc_url` según la configuración; la guarda del emulador antes de crear la app; el manejador de errores de forma; los límites en `app.state`; `GET /health`
- apps/api/app/interfaz/salud.py — nuevo: `GET /health` (vivo, sin tocar dependencias)

Grupo 3 · correo, emulador y dispositivos
- apps/api/app/infraestructura/correo.py — `starttls(context=ssl.create_default_context())`; un fallo se registra con el tipo de error y el asunto, sin destinatario ni traceback con la dirección
- apps/api/app/infraestructura/identidad.py — `exigir_emulador_seguro()`: con `FIREBASE_AUTH_EMULATOR_HOST`, `RuntimeError` si hay credenciales de servicio o el proyecto no empieza con `demo-`
- apps/api/app/infraestructura/notificaciones.py — un token activo de otra cuenta no cambia de dueño; la baja de un token ajeno no hace nada · rule · test: apps/api/tests/escenarios/test_seguridad_api.py

Grupo 4 · dependencias, contrato y despliegue
- apps/api/uv.lock — certifi ≥ 2026.10.18 (`uv lock --upgrade-package certifi`)
- apps/api/openapi.json — nuevo: el contrato, generado por comando (`uv run --no-sync python -c "import json; from app.main import crear_app; print(json.dumps(crear_app().openapi(), ensure_ascii=False, indent=2))"`)
- render.yaml — `DOCUMENTACION_INTERACTIVA=false`, `DETRAS_DE_PROXY=true`, `healthCheckPath: /health`
- apps/api/README.md — los supuestos de operación de esta card y el comando del contrato
- apps/api/tests/conftest.py — agrega `HOSTS_PERMITIDOS` con `testserver` para el cliente de pruebas (una línea nueva; ninguna existente cambia)

Tests
- apps/api/tests/escenarios/test_seguridad_api.py — los escenarios REV-01 (rojo, del hilo principal)
- apps/api/tests/unit/test_limites.py, apps/api/tests/unit/test_entradas.py — unitarios del implementer, para mutar sin la suite entera

- System design: unchanged — la card no agrega módulo, proceso, almacenamiento ni dependencia externa; el modelo de amenazas lo escribe REV-07
- ADR: unchanged — no cambia la arquitectura

## Assumptions

- REV-01-ASM-01 · los mensajes «Este correo ya está registrado» y «Este DNI ya está registrado» siguen (CU-03 FA2); la consulta en serie se frena: `/registro` comparte el límite por origen y `PUT /yo` admite 10 pedidos por hora por cuenta · any-answer: no — si se pide un mensaje neutro cambia el texto
- REV-01-ASM-02 · largos máximos: correo 254, contraseña 128, código 128, token 4096, nombre de sede y dirección 120, búsqueda 100, los de dominio quedan (nombre 60, motivo `MOTIVO_MAXIMO`); NUL o caracteres de control → 422 «Tiene caracteres no permitidos»; `horas` 1..4 y `pagina` 1..10000 antes de calcular; los errores de forma responden `{"errores": {campo: mensaje}}` sin repetir el valor recibido · any-answer: yes
- REV-01-ASM-03 · `/registro` y `/recuperacion`: 10 pedidos por minuto por origen; 429 con `Retry-After: 60` y `{"mensaje": "Hiciste demasiados intentos. Esperá un minuto y volvé a probar."}` · any-answer: yes
- REV-01-ASM-04 · un token de dispositivo activo de otra cuenta no cambia de dueño y la baja de un token ajeno no hace nada; las dos responden 204 como si hubieran andado · any-answer: no — un teléfono compartido sin cierre de sesión deja sin avisos a la segunda persona
- REV-01-ASM-05 · `/docs` y `/redoc` se apagan con `DOCUMENTACION_INTERACTIVA=false`, que define el blueprint de Render; local y pruebas los mantienen; `/openapi.json` sigue público (enunciado, RNF-01-H06-01) y el contrato se versiona en `apps/api/openapi.json` · any-answer: no — si la corrección pide la página interactiva en la nube, se prende con la variable
- REV-01-ASM-06 · si el servidor de correo no presenta un certificado válido el envío falla, queda registrado sin la dirección, y la persona ve lo mismo que siempre (202) · any-answer: yes
- REV-01-ASM-07 · `GET /health` responde 200 sin tocar dependencias y es el chequeo de Render; el chequeo de dependencias (`/ready`) es de REV-02 · any-answer: yes
- REV-01-ASM-08 · el contador vive en la memoria de cada instancia de la app, con candado; Render free corre una sola instancia · any-answer: yes
- REV-01-ASM-09 · un 429 o un Host ajeno se registran como rechazo con método, ruta escapada, código y usuario, sin IP ni datos personales · any-answer: yes
- REV-01-ASM-10 · con `FIREBASE_AUTH_EMULATOR_HOST` definida, la API no arranca si hay credenciales de servicio (`FIREBASE_CREDENCIALES_JSON` o `GOOGLE_APPLICATION_CREDENTIALS`) o si el proyecto no empieza con `demo-` · any-answer: yes
- REV-01-ASM-11 · detrás del proxy de Render (`DETRAS_DE_PROXY=true`) el origen es el último valor de `X-Forwarded-For`, el que agrega Render; sin proxy, la dirección del socket · any-answer: yes
- REV-01-ASM-12 · la lista de Host permitidos es `localhost`, `127.0.0.1`, `10.0.2.2`, el host de `URL_PUBLICA` y lo que agregue `HOSTS_PERMITIDOS` · any-answer: yes

## Uncovered assumptions

- REV-01-ASM-02, ASM-03, ASM-06 a ASM-12: cubiertos por los escenarios de su hallazgo y por los unitarios del implementer; ASM-11 (proxy de Render) y el Host que manda el chequeo de salud de Render sólo se prueban en la nube: «no se pudo correr», sin despliegue.

## Perimeter

Autenticación real con el emulador de Firebase Auth en `127.0.0.1:9099`; Postgres compartido, base `club_rev01_test`. El SMTP se reemplaza en el test por un doble que anota el contexto TLS: el TLS contra un servidor real con certificado inválido no se prueba. Fuera: S12 (REV-07), S18 (OUT), hallazgos 2, 14, 15 y 26 (REV-02), el hallazgo 8 (usuario de base propio, REV-02). La llamada HTTP de la app no cambia.

## Bar

- R1 · los escenarios recorren la API real por HTTP con sesiones del emulador; el log de accesos se prueba contra uvicorn levantado como en Render
- R2 · las diez preguntas y AMB-01 a AMB-10 en `ambiguities.md`
- R3 · cada ASM dice si sirve con cualquier respuesta
- R4 · los ASM que afectan a quien opera (límites, documentación, health, Host, proxy, emulador) van en `apps/api/README.md` con su ID
- R5 · las preguntas de `ambiguities.md` están en lenguaje del club, sin IDs ni jerga
- R6 · un test con tag por escenario, en `tests/escenarios/test_seguridad_api.py`
- R7 · cada hunk del diff corresponde a un hallazgo de la card; el inspector lo revisa
- R8 · lo ajeno visto va como `REV-01-OUT-NN`, sin tocar
- R9 · no applicable · la card no agrega requisitos no funcionales medibles; el presupuesto lo escribe REV-07
- R10 · ASVS nivel 2 (módulo security-l2); los capítulos que toca: V1.4, V2.2, V2.4, V12.3, V13 (documentación), V14 (cabeceras), V16.4; la matriz la escribe REV-07
- D1 · `entradas.py` y `limites.py` en interfaz, cada uno con una responsabilidad
- D2 · interfaz → aplicación → dominio; los módulos nuevos no importan infraestructura; el test de capas existente lo cubre para aplicación y dominio
- D3 · sin ciclos nuevos; `entradas` y `limites` no importan otras rutas
- D4 · `Texto(maximo)` y `limite(...)` esconden la validación y la ventana detrás de una interfaz chica
- D5 · un solo lugar para los largos y para la regla de caracteres
- D6 · nada de configuración que la card no pide; el límite tiene dos valores fijos
- D7 · se reusa `Protecciones` para cabeceras y Host, y `RegistroDeErrores` para el escape
- D8 · el SMTP ya tiene timeout de 10 s y no reintenta (el pedido es idempotente para la persona); la política completa la escribe REV-07
- D9 · amenazas de la card: enumeración, fuerza bruta, intercepción del SMTP, falsificación del log, incrustación, Host ajeno, tokens sin firma; cada una con su escenario
- D10 · las respuestas de error dejan de repetir lo recibido
- D11 · `notificaciones.py` de infraestructura sigue escribiendo sólo `dispositivo` y `notificacion`
- D12 · `Texto` y `limite` tipados, con firmas públicas
- D13 · no applicable · sin componentes de front
- D14 · no applicable · no cambia la arquitectura: sin módulo, proceso, almacenamiento ni dependencia externa nuevos
- D15 · no applicable · ninguna biblioteca nueva; el límite se escribe a mano para no agregar una dependencia
- K1 · `mypy --strict app` sin supresiones nuevas
- K2 · ruff sin problemas nuevos; Sonar no está en la máquina: «no se pudo correr»
- K3 · funciones cortas; la complejidad de Python se mide con ruff C901 si el inspector lo pide
- K4 · sin duplicación nueva: los tipos de texto se definen una vez
- K5 · sin código muerto
- K6 · nombres del dominio en español
- K7 · comentarios sólo para lo que no se deduce (por qué el último valor de `X-Forwarded-For`)
- K8 · toda entrada de texto y número de las rutas que toca la card queda acotada en el modelo
- K9 · el SMTP sigue en `with`; el contador no abre recursos
- K10 · `pagina` acotada; el contador poda su ventana en cada pedido
- K11 · sigue las convenciones del repo: español, `{"errores": {...}}`, docstring con tag
- E1 · no applicable · no cambia lo guardado
- E2 · no applicable · ninguna escritura nueva
- E3 · el contador usa un candado; dos pedidos simultáneos cuentan los dos
- E4 · el registro del dispositivo sigue idempotente para su dueño
- E5 · los 500 de la card pasan a 422 y el servidor sigue
- E6 · el fallo de correo se registra; ninguna respuesta lleva traza
- E7 · la API no arranca con el emulador mal combinado, con un mensaje claro
- E8 · SMTP con `timeout=10`; firebase-admin con `httpTimeout=4`
- E9 · no applicable · la card no agrega reintentos
- E10 · el 429 lleva `Retry-After`
- E11 · `DatosInvalidos` sigue cruzando de aplicación a interfaz como 422
- E12 · el fallo de correo se registra una vez, donde se maneja
- E13 · no applicable · los manejadores globales son de REV-02
- E14 · no applicable · sin colas nuevas
- E15 · cada rama de error nueva (422, 429, 400, arranque negado) tiene test
- E16 · el 429 dice qué pasó y qué hacer; el id de referencia es de REV-02
- T1 · los tests en rojo se commitean antes del código
- T2 · ningún test se ablanda
- T3 · mutación sobre cada archivo de producción con el subconjunto de tests (ver `## Verification`)
- T4 · cada test afirma un comportamiento observable por HTTP o en el log
- T5 · por comportamiento; H01-01 mira el contexto TLS que pide el cliente porque un SMTP real con certificado inválido no está en la máquina
- T6 · sin lógica en los tests; la espera del servidor vive en un fixture
- T7 · cada test crea sus cuentas; el contador vive en la app de cada test
- T8 · los nuevos se corren tres veces (`repeat.mjs`) antes de cerrar
- T9 · la regla del contador y la de texto tienen unitarios
- T10 · cada borde de `## Edges` tiene su test
- T11 · cobertura de líneas nuevas con `pytest --cov` si está; si no, «no se pudo correr»
- T12 · no applicable · sin pantalla
- T13 · `entradas.py`, `limites.py` y la regla de dispositivos marcados `rule` con su test
- T14 · no applicable · no es carril rápido
- S1 · no applicable · la API usa token Bearer, no credenciales ambientales
- S2 · Host ajeno → 400; cuerpo enorme → 413 (ya estaba); método que no aplica → 405 (ya estaba)
- S3 · el SQL sigue parametrizado; NUL rechazado en la entrada
- S4 · `/enlace/recuperar` con CSP; la API responde JSON
- S5 · los permisos no cambian; la reasignación de dispositivos se cierra
- S6 · no applicable · sin exportaciones
- S7 · CSP en toda respuesta; `nosniff` y `no-store` ya estaban
- S8 · no applicable · sin mensajes de resultado nuevos
- S9 · sin secretos en el diff
- S10 · no applicable · ninguna dependencia nueva; certifi sube de versión
- S11 · certifi ≥ 2026.10.18; `pip-audit` sobre el lock si está en la máquina, si no «no se pudo correr»
- S12 · no applicable · nada nuevo con licencia (S12 del hallazgo 25 es de REV-07)
- S13 · TLS del sistema con el contexto por defecto
- S14 · los rechazos se registran sin datos personales
- S15 · los capítulos de R10, anotados en el cierre para la matriz de REV-07
- S16 · el patrón (texto sin cota, reasignación por clave ajena) se busca en el resto de las rutas
- S17 · ZAP: «no se pudo correr» si no está en la máquina
- S18 · no applicable · S18 queda como OUT propuesto
- S19 · no applicable · THIRD_PARTY_NOTICES es de REV-07
- S20 · no applicable · el usuario propio de base es el hallazgo 8, de REV-02
- S21 · no applicable · el STRIDE lo escribe REV-07
- S22 · ningún secreto nuevo; los del SMTP siguen `sync: false`
- S24 · límite de frecuencia, Host permitido, documentación apagada en producción, guarda del emulador
- P1 · la card no agrega datos personales; saca correo y DNI del log
- P2 · H09-01 a H09-04 mandan correo, DNI, contraseña, token y código y miran log y respuestas
- P3 · los errores de forma dejan de repetir el valor recibido
- P4 · no applicable · sin cambio de esquema
- P5 · no applicable · sin migraciones
- P6 · no applicable · sin datos nuevos
- P7 · no applicable · sin datos nuevos
- P8 · no applicable · sin columnas nuevas
- P9 · no applicable · sin consultas nuevas
- P10 · no applicable · sin consultas nuevas
- P11 · no applicable · la paginación por clave es de REV-03
- P12 · no applicable · sin migraciones
- P13 · el correo sigue fuera de la transacción (tarea de fondo)
- P14 · no applicable · sin cambio de datos
- P15 · no applicable · el inventario es de REV-07
- P16 · ninguna migración se toca
- O1 · `uv sync` y arranca igual; las variables nuevas tienen valor por defecto
- O2 · todo por variables de entorno
- O3 · no applicable · O3 es de REV-02
- O4 · no cambia el apagado
- O5 · los rechazos nuevos con nombre estable en el mismo formato; el JSON es de REV-02
- O6 · 429 y Host ajeno quedan en el log
- O7 · no cambia
- O8 · render.yaml cambia sólo el chequeo de salud y dos variables, que la card pide
- O9 · todo se revierte por variable o por commit, sin datos
- O10 · no applicable · sin requisito de volumen; el contador es O(1) por pedido
- O11 · la suite entera corre una vez al final
- O12 · los logs de uvicorn del test van a `tmp_path`
- O13 · no applicable · el modelo de costos es de REV-07
- O14 · no applicable · system-design es de REV-07
- O15 · no applicable · sin front web
- O16 · no applicable · la versión única es de REV-02
- O17 · no applicable · la correlación es de REV-02
- O18 · `/health` existe y es el chequeo de Render; `/ready` es de REV-02
- O19 · no applicable · métricas de REV-02
- O20 · no applicable · SLOs de REV-07
- O21 · no applicable · el id de referencia es de REV-02
- O22 · no applicable · la prueba de carga es de REV-02
- O24 · no applicable · el artefacto único es de REV-02
- O29 · no applicable · smoke y rollback son de REV-02
- I1–I26 · no applicable · la card no toca pantallas; la página de `/enlace/recuperar` sólo suma una cabecera
- C1 · la app sigue andando: el cliente no manda Host ajeno, no pega NUL y no hace ráfagas; el e2e de registro y recuperación corre si el emulador Android está, si no «no se pudo correr»
- C2 · los textos legítimos con tildes, eñes y espacios pasan (borde)
- C3 · la suite entera sigue verde
- C4 · las respuestas de éxito no cambian; los errores de forma pasan al formato `{"errores": …}` que la app ya lee
- A1 · cada «pasó» con su comando y salida en `closing.md`
- A2 · el cierre nombra sólo lo que está en el diff
- A3 · AMB-01 a AMB-10 registradas, sin canal → ASM
- A4 · los hooks del kit y `verify.mjs`
- A5 · el diff de producción es proporcional a siete hallazgos
- A6 · cableado de punta a punta: render.yaml, README, contrato
- A7 · el juicio del inspector se repite si hay duda y no reemplaza un comando
- A8 · no applicable · la app no llama a un modelo
- A9 · ningún test se apaga ni se saltea
- V1 · snapshot congelado en c16d271
- V2 · este plan, antes del código
- V3 · commits con qué y por qué
- V4 · el registro de la sesión
- V5 · no applicable · sin pantalla
- V6 · el cierre sale de la salida de las validaciones
- V7 · lo aprueba una persona antes de integrar; no hay PR (sin remoto declarado)
- W5 · no applicable · el runbook es de REV-07
- W8 · la API documenta los códigos nuevos (400, 429) en OpenAPI y el contrato queda versionado
- W9 · el test del contrato compara `apps/api/openapi.json` con lo que publica la API
- ci · off by decision · not chosen at install: no signal found in the repo
- docs · off by decision · not chosen at install: no signal found in the repo
- i18n · off by decision · not chosen at install: no signal found in the repo

## Edges

- Defense against legitimate data · nombres con tildes, eñes, apóstrofos y espacios pasan; un correo de 254 caracteres pasa y uno de 255 no; `horas` 4 pasa y 5 no
- State after the action · el pedido frenado no deja nada a medias; el dispositivo ajeno queda con su dueño
- Honest notices · el 429 dice cuánto esperar; la recuperación responde igual con correo o sin él
- What does not exist · `/docs` apagado da 404; una reserva inexistente con motivo inválido da 422 antes del 404
- Writes · ninguna escritura nueva
- Origin of the request · Host ajeno → 400; el origen para el límite sale del socket o del último `X-Forwarded-For` detrás de Render
- What travels to another program · el log: la ruta escapada y sin query string; el SMTP: TLS verificado
- Restart · el contador se pierde al reiniciar (ASM-08)
- What no test notices · el Host que manda el chequeo de Render y el proxy de Render: «no se pudo correr» sin despliegue

## Changes to existing behavior

- README: `apps/api/README.md` suma los supuestos de operación (límites, documentación, health, Host, proxy, emulador) y el comando del contrato
- ASVS: unchanged — la matriz la crea REV-07; esta card anota en el cierre los capítulos que toca
- `/docs` y `/redoc` dejan de existir en Render; `/openapi.json` sigue
- `render.yaml`: el chequeo de salud pasa de `/docs` a `/health`
- Los errores de forma (tipo o JSON inválido) pasan de `{"detail": [...]}` a `{"errores": {...}}`
- `PUT /dispositivos` con un token activo de otra cuenta deja de reasignarlo; responde 204 igual
- Nuevo: 429 en `/registro`, `/recuperacion` y `PUT /yo`; 400 con Host ajeno; CSP en toda respuesta
- Lo demás queda igual: rutas, permisos y respuestas de éxito
