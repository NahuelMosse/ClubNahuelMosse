# REV-01 · seguridad de la API

card: REV-01
status: proposed
cap: 12 h
sources:
  - specs/REVISION-kit3.md @138bc54 — encabezado (líneas 1-5) y hallazgos 1, 5, 6, 7, 9, 16 completos; hallazgo 25 sólo encabezado y viñetas S2, Emulador de Auth y Dispositivos
  - pedido (texto) — mensaje del coordinador, transcripto tal cual
  - enunciado — D:/desktop folders/estudio/Universidad de moron/Electiva general/Trabajo Práctico_2026.docx.pdf (pdftotext -enc UTF-8 -layout)
  - CU-03 — D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-03 Registrar usuario.pdf (pdftotext -layout)
  - CU-04b — D:/desktop folders/estudio/Universidad de moron/Electiva general/CU-nuevos/CU-04b - Recuperar contraseña.md (Read)
  - CU-06 — D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-06 - Editar perfil.pdf (pdftotext -layout)
  - CU-09 — D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-09_Reservar_cancha_MartinGaser .pdf (pdftotext -layout)
  - CU-14 — D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-14_Especificacion_Francisco_Luciano.pdf (pdftotext -layout)
not_read:
  - Jira, card REV-01: no consultada. El pedido llega como texto y no hay card de Jira que leer en esta sesión.
  - specs/REVISION-kit3.md, leído completo pero NO transcripto (fuera del pedido): secciones «Costo», «Qué corrió», «Cuenta por grupo de criterios», «Sin hallazgo», «Qué no se pudo correr», «CU sin cubrir por los tests»; hallazgos 2, 3, 4, 8, 10, 11, 12, 13, 14, 15, 17, 18, 19, 20, 21, 22, 23, 24, 26, 27 y 28; en el hallazgo 25, S12 (según el mensaje que lanzó este snapshot, va a REV-07) y S18 (según el mismo mensaje, queda fuera).
  - Código citado en los hallazgos transcriptos (apps/api/app/..., apps/mobile/lib/..., render.yaml, uv.lock, pubspec.lock): no abierto. Las líneas citadas no fueron verificadas en esta sesión.
  - Carpetas CU/ y CU-nuevos/ fuera de CU-03, CU-04b, CU-06, CU-09 y CU-14: no leídas (no pedidas). Dentro de CU/ hay además un archivo Distribucion CUs.jpeg no leído (no pedido).
  - PDFs de CU y enunciado: se extrajo sólo el texto. Imágenes o capturas incrustadas en esos PDF no se leyeron.

## Specs

- S1 · "el envío de correo rechaza un servidor SMTP con certificado no válido para su nombre"
- S2 · "una reserva con una cantidad de horas desmesurada se rechaza como dato inválido, sin error del servidor"
- S3 · "una reserva que termina después del último día representable se rechaza como dato inválido"
- S4 · "pedir una página enorme del historial global se rechaza como dato inválido"
- S5 · "un carácter nulo en un campo de texto se rechaza como dato inválido en todas las rutas que reciben texto"
- S6 · "pedir recuperaciones de contraseña en ráfaga queda frenado por un límite de frecuencia"
- S7 · "intentar registros en ráfaga queda frenado por un límite de frecuencia"
- S8 · "probar DNI ajenos en el perfil en serie queda frenado y no sirve para saber quién es socio"
- S9 · "probar correos ajenos en el registro no sirve para saber quién tiene cuenta"
- S10 · "la API no depende de una versión de certifi con vulnerabilidad conocida"
- S11 · "un rechazo del servidor de correo no deja la dirección de la persona en el log"
- S12 · "el log de accesos no guarda el correo ni el DNI que busca el administrador"
- S13 · "una ruta con saltos de línea no puede falsificar una línea del log"
- S14 · "contraseñas, tokens y códigos de recuperación no llegan al log"
- S15 · "la documentación interactiva de la API no se publica en producción"
- S16 · "las respuestas llevan una política de contenido que impide incrustarlas"
- S17 · "un pedido con un Host ajeno se rechaza"
- S18 · "la API se niega a arrancar con el emulador de autenticación junto a credenciales reales"
- S19 · "registrar el token de dispositivo de otra persona no se lo quita"
- REV-01-ASM-01 · los mensajes «Este correo ya está registrado» y «Este DNI ya está registrado» siguen (CU-03 FA2); la consulta en serie se frena: `/registro` comparte el límite por origen y `PUT /yo` admite 10 pedidos por hora por cuenta (any-answer: no — si se pide un mensaje neutro cambia el texto) · S8,S9
- REV-01-ASM-02 · largos máximos: correo 254, contraseña 128, código 128, token 4096, nombre de sede y dirección 120, búsqueda 100, los de dominio quedan (nombre 60, motivo `MOTIVO_MAXIMO`); NUL o caracteres de control → 422 «Tiene caracteres no permitidos»; `horas` 1..4 y `pagina` 1..10000 antes de calcular; los errores de forma responden `{"errores": {campo: mensaje}}` sin repetir el valor recibido (any-answer: yes) · S4
- REV-01-ASM-03 · `/registro` y `/recuperacion`: 10 pedidos por minuto por origen; 429 con `Retry-After: 60` y `{"mensaje": "Hiciste demasiados intentos. Esperá un minuto y volvé a probar."}` (any-answer: yes) · S6
- REV-01-ASM-04 · un token de dispositivo activo de otra cuenta no cambia de dueño y la baja de un token ajeno no hace nada; las dos responden 204 como si hubieran andado (any-answer: no — un teléfono compartido sin cierre de sesión deja sin avisos a la segunda persona) · S19
- REV-01-ASM-05 · `/docs` y `/redoc` se apagan con `DOCUMENTACION_INTERACTIVA=false`, que define el blueprint de Render; local y pruebas los mantienen; `/openapi.json` sigue público (enunciado, RNF-01-H06-01) y el contrato se versiona en `apps/api/openapi.json` (any-answer: no — si la corrección pide la página interactiva en la nube, se prende con la variable) · S15
- REV-01-ASM-06 · si el servidor de correo no presenta un certificado válido el envío falla, queda registrado sin la dirección, y la persona ve lo mismo que siempre (202) (any-answer: yes) · S1
- REV-01-ASM-07 · `GET /health` responde 200 sin tocar dependencias y es el chequeo de Render; el chequeo de dependencias (`/ready`) es de REV-02 (any-answer: yes) · S15
- REV-01-ASM-08 · el contador vive en la memoria de cada instancia de la app, con candado; Render free corre una sola instancia (any-answer: yes) · S6
- REV-01-ASM-09 · un 429 o un Host ajeno se registran como rechazo con método, ruta escapada, código y usuario, sin IP ni datos personales (any-answer: yes) · S17
- REV-01-ASM-10 · con `FIREBASE_AUTH_EMULATOR_HOST` definida, la API no arranca si hay credenciales de servicio (`FIREBASE_CREDENCIALES_JSON` o `GOOGLE_APPLICATION_CREDENTIALS`) o si el proyecto no empieza con `demo-` (any-answer: yes) · S18
- REV-01-ASM-11 · detrás del proxy de Render (`DETRAS_DE_PROXY=true`) el origen es el último valor de `X-Forwarded-For`, el que agrega Render; sin proxy, la dirección del socket (any-answer: yes) · S6
- REV-01-ASM-12 · la lista de Host permitidos es `localhost`, `127.0.0.1`, `10.0.2.2`, el host de `URL_PUBLICA` y lo que agregue `HOSTS_PERMITIDOS` (any-answer: yes) · S17
- REV-01-ASM-13 · `GET /health` queda fuera del filtro de Host, para que el chequeo de Render responda con el Host que use; sigue sin tocar dependencias · S17
- REV-01-ASM-14 · la app muestra el 429 con el mensaje que manda el servidor, en su diálogo de error de siempre; no se agrega pantalla · S6
- REV-01-ASM-15 · el blueprint de Render define `DETRAS_DE_PROXY=true`; detrás del proxy, un `X-Forwarded-For` con valores falsificados delante no cambia el origen que cuenta el límite · S6
- REV-01-ASM-16 · un cuerpo que no es JSON válido responde 400 con `{"errores": {"cuerpo": "El cuerpo no es JSON válido"}}`, sin repetir lo recibido; los datos con forma inválida siguen en 422 · S5

## Tasks

- T1 · S2,S3,S4,S5,S6,S7,S8,S9 · apps/api/app/interfaz/entradas.py (rule), apps/api/app/dominio/horarios.py (rule), apps/mobile/lib/api/cliente_api.dart (data), apps/mobile/lib/comun/dialogo_error.dart (presentation), apps/api/app/interfaz/limites.py (rule), apps/api/app/aplicacion/reservas.py (rule), apps/api/app/interfaz/notificaciones.py (presentation), apps/api/app/interfaz/horarios.py (presentation), apps/api/app/interfaz/respuestas.py (presentation), apps/api/app/dominio/notificaciones.py (rule), apps/api/app/interfaz/registro.py (presentation), apps/api/app/interfaz/recuperacion.py (presentation), apps/api/app/interfaz/sesion.py (presentation), apps/api/app/interfaz/sedes.py (presentation), apps/api/app/interfaz/espacios.py (presentation), apps/api/app/interfaz/reservas.py (presentation), apps/api/tests/unit/test_limites.py, apps/api/tests/unit/test_entradas.py · tests: apps/api/tests/escenarios/test_seguridad_api.py "una reserva con horas desmesuradas se rechaza como dato inválido @REV-01-S2"; apps/api/tests/escenarios/test_seguridad_api.py "el borde de cuatro horas sigue aceptándose @REV-01-S2"; apps/api/tests/escenarios/test_seguridad_api.py "una reserva que termina después del último día representable es inválida @REV-01-S3"; apps/api/tests/escenarios/test_seguridad_api.py "pedir una página enorme del historial global se rechaza como dato inválido @REV-01-S4"; apps/api/tests/escenarios/test_seguridad_api.py "el borde de la página 10000 sigue respondiendo @REV-01-S4 @assumption:REV-01-ASM-02"; apps/api/tests/escenarios/test_seguridad_api.py "un carácter nulo en un campo de texto se rechaza como dato inválido @REV-01-S5"; apps/api/tests/escenarios/test_seguridad_api.py "un carácter nulo en un campo de texto de un socio es un dato inválido @REV-01-S5"; apps/api/tests/escenarios/test_seguridad_api.py "un carácter nulo en un campo de texto del admin es un dato inválido @REV-01-S5"; apps/api/tests/escenarios/test_seguridad_api.py "un carácter nulo en la búsqueda del historial global es un dato inválido @REV-01-S5"; apps/api/tests/escenarios/test_seguridad_entradas_extra.py "un carácter nulo en el correo de /registro es un dato inválido @REV-01-S5"; apps/api/tests/escenarios/test_seguridad_entradas_extra.py "un carácter nulo en el correo de /recuperacion es un dato inválido @REV-01-S5"; apps/api/tests/escenarios/test_seguridad_entradas_extra.py "un carácter nulo en el token de /dispositivos es un dato inválido @REV-01-S5"; apps/api/tests/escenarios/test_seguridad_entradas_extra.py "un texto más largo que su máximo es un dato inválido y el error no repite el valor @REV-01-S5 @assumption:REV-01-ASM-02"; apps/api/tests/escenarios/test_seguridad_entradas_extra.py "un carácter de control distinto del nulo es un dato inválido @REV-01-S5 @assumption:REV-01-ASM-02"; apps/api/tests/escenarios/test_seguridad_api.py "pedir recuperaciones de contraseña en ráfaga queda frenado por un límite @REV-01-S6 @assumption:REV-01-ASM-03"; apps/api/tests/escenarios/test_seguridad_api.py "cambiar X-Forwarded-For sin proxy no saltea el límite @REV-01-S6 @assumption:REV-01-ASM-11"; apps/api/tests/escenarios/test_seguridad_entradas_extra.py "detrás del proxy un X-Forwarded-For falsificado delante no saltea el límite @REV-01-S6 @assumption:REV-01-ASM-15"; apps/api/tests/escenarios/test_seguridad_entradas_extra.py "el blueprint de Render define DETRAS_DE_PROXY=true @REV-01-S6 @assumption:REV-01-ASM-15"; apps/mobile/test/limite_de_frecuencia_test.dart "la app muestra el 429 con el mensaje del servidor en su diálogo de error @REV-01-S6 @assumption:REV-01-ASM-14"; apps/api/tests/escenarios/test_seguridad_api.py "intentar registros en ráfaga queda frenado por un límite de frecuencia @REV-01-S7"; apps/api/tests/escenarios/test_seguridad_api.py "probar DNI ajenos en el perfil en serie queda frenado @REV-01-S8 @assumption:REV-01-ASM-01"; apps/api/tests/escenarios/test_seguridad_api.py "probar correos ajenos en el registro no sirve para saber quién tiene cuenta @REV-01-S9 @assumption:REV-01-ASM-01"; apps/api/tests/escenarios/test_seguridad_api.py "el contador de frecuencia vive en la instancia y no pierde cuentas con pedidos simultáneos @REV-01-S6 @assumption:REV-01-ASM-08"
- T2 · S12,S13,S14,S15,S16,S17 · apps/api/app/interfaz/registro_errores.py (presentation), apps/api/app/interfaz/protecciones.py (presentation), apps/api/app/config.py (rule), apps/api/app/main.py (presentation), apps/api/app/interfaz/salud.py (presentation) · tests: apps/api/tests/escenarios/test_seguridad_api.py "el log de accesos no guarda el correo ni el DNI que busca el administrador @REV-01-S12"; apps/api/tests/escenarios/test_seguridad_api.py "una ruta con saltos de línea no puede falsificar una línea del log @REV-01-S13"; apps/api/tests/escenarios/test_seguridad_api.py "contraseñas, tokens y códigos de recuperación no llegan al log @REV-01-S14"; apps/api/tests/escenarios/test_seguridad_api.py "la documentación interactiva no se publica en producción @REV-01-S15 @assumption:REV-01-ASM-05"; apps/api/tests/escenarios/test_seguridad_api.py "las respuestas llevan una política de contenido que impide incrustarlas @REV-01-S16"; apps/api/tests/escenarios/test_seguridad_api.py "un pedido con un Host ajeno se rechaza @REV-01-S17 @assumption:REV-01-ASM-12"; apps/api/tests/escenarios/test_seguridad_api.py "una reserva con sesión y Host ajeno se rechaza @REV-01-S17"; apps/api/tests/escenarios/test_seguridad_entradas_extra.py "un 429 o un Host ajeno queda registrado con método, ruta escapada, código y usuario, sin IP ni datos personales @REV-01-S17 @assumption:REV-01-ASM-09"
- T3 · S1,S11,S18,S19 · apps/api/app/infraestructura/correo.py (data), apps/api/app/infraestructura/identidad.py (data), apps/api/app/infraestructura/notificaciones.py (data) · tests: apps/api/tests/escenarios/test_seguridad_api.py "el envío de correo pide un TLS que verifica certificado y nombre @REV-01-S1"; apps/api/tests/escenarios/test_seguridad_api.py "con un certificado inválido no se entregan usuario ni contraseña SMTP @REV-01-S1 @assumption:REV-01-ASM-06"; apps/api/tests/escenarios/test_seguridad_api.py "quien pide recuperar ve lo mismo aunque el TLS del correo falle @REV-01-S1 @assumption:REV-01-ASM-06"; apps/api/tests/escenarios/test_seguridad_api.py "un rechazo del servidor de correo no deja la dirección de la persona en el log @REV-01-S11"; apps/api/tests/escenarios/test_seguridad_api.py "la API se niega a arrancar con el emulador junto a credenciales reales @REV-01-S18"; apps/api/tests/escenarios/test_seguridad_api.py "la API se niega a arrancar con el emulador y un archivo de credenciales @REV-01-S18"; apps/api/tests/escenarios/test_seguridad_api.py "la API se niega a arrancar con el emulador y un proyecto que no es de demo @REV-01-S18"; apps/api/tests/escenarios/test_seguridad_api.py "con el emulador, un proyecto de demo y sin credenciales la API arranca @REV-01-S18 @assumption:REV-01-ASM-10"; apps/api/tests/escenarios/test_seguridad_api.py "registrar el token de dispositivo de otra persona no se lo quita @REV-01-S19 @assumption:REV-01-ASM-04"; apps/api/tests/escenarios/test_seguridad_api.py "un teléfono que cerró sesión pasa a la siguiente persona @REV-01-S19 @assumption:REV-01-ASM-04"; apps/api/tests/escenarios/test_seguridad_entradas_extra.py "dar de baja un token ajeno no hace nada y responde 204 @REV-01-S19 @assumption:REV-01-ASM-04"; apps/api/tests/escenarios/test_seguridad_entradas_extra.py "un fallo de TLS del correo no deja la dirección en el log @REV-01-S11 @assumption:REV-01-ASM-06"
- T4 · S10,S15 · apps/api/uv.lock, apps/api/openapi.json, render.yaml, apps/api/README.md, apps/api/tests/conftest.py · tests: apps/api/tests/escenarios/test_seguridad_api.py "la API no depende de una versión de certifi con vulnerabilidad conocida @REV-01-S10"; apps/api/tests/escenarios/test_seguridad_api.py "el blueprint de producción apaga la documentación interactiva y se chequea por /health @REV-01-S15 @assumption:REV-01-ASM-05 @assumption:REV-01-ASM-07"; apps/api/tests/escenarios/test_seguridad_api.py "el contrato OpenAPI versionado coincide con lo que la API publica @REV-01-S15"; apps/api/tests/escenarios/test_seguridad_entradas_extra.py "el contrato OpenAPI documenta el 429, el 400 por Host ajeno y el 422 de forma @REV-01-S15"; apps/api/tests/escenarios/test_seguridad_entradas.py "/health responde aunque el Host no esté en la lista @REV-01-S17 @assumption:REV-01-ASM-13"; apps/api/tests/escenarios/test_seguridad_cuerpo.py "un cuerpo que no es JSON válido responde 400 y no repite lo recibido; un dato con forma inválida sigue en 422 @REV-01-S5 @assumption:REV-01-ASM-16"

## Changes to existing behavior

- README: `apps/api/README.md` suma los supuestos de operación (límites, documentación, health, Host, proxy, emulador) y el comando del contrato
- ASVS: unchanged — la matriz la crea REV-07; esta card anota en el cierre los capítulos que toca
- `/docs` y `/redoc` dejan de existir en Render; `/openapi.json` sigue
- `render.yaml`: el chequeo de salud pasa de `/docs` a `/health`
- Los errores de forma (tipo o JSON inválido) pasan de `{"detail": [...]}` a `{"errores": {...}}`
- `PUT /dispositivos` con un token activo de otra cuenta deja de reasignarlo; responde 204 igual
- Nuevo: 429 en `/registro`, `/recuperacion` y `PUT /yo`; 400 con Host ajeno; CSP en toda respuesta
- Lo demás queda igual: rutas, permisos y respuestas de éxito

## Gate

```
suite: sh D:/Temp/w/herramientas/pytest-api.sh -q -p no:cacheprovider
lint: cd apps/api && uv run --no-sync ruff check . && uv run --no-sync ruff format --check app tests/escenarios/test_seguridad_api.py && uv run --no-sync mypy --strict app
scenarios: sh D:/Temp/w/herramientas/pytest-api.sh -q -p no:cacheprovider tests/escenarios --card REV-01
mutate apps/api/app/interfaz/limites.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py tests/unit
mutate apps/api/app/interfaz/entradas.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py tests/unit
mutate apps/api/app/interfaz/protecciones.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py tests/integracion/test_protecciones_api.py
mutate apps/api/app/interfaz/registro_errores.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py tests/escenarios/test_registro_de_errores.py
mutate apps/api/app/infraestructura/correo.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py
mutate apps/api/app/infraestructura/identidad.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/unit/test_identidad_ingreso.py
mutate apps/api/app/infraestructura/notificaciones.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py tests/unit
mutate apps/api/app/main.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py
mutate apps/api/app/config.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py
mutate apps/api/app/interfaz/registro.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py
mutate apps/api/app/interfaz/recuperacion.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py
mutate apps/api/app/interfaz/sesion.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py
mutate apps/api/app/interfaz/sedes.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py
mutate apps/api/app/interfaz/espacios.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py
mutate apps/api/app/interfaz/reservas.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py
mutate apps/api/app/interfaz/notificaciones.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py tests/escenarios/test_seguridad_entradas.py
mutate apps/api/app/interfaz/salud.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py
no-visual: la página de recuperacion.py no cambia su markup; la card sólo valida las entradas de sus rutas
lint-app: dart format --output=none --set-exit-if-changed apps/mobile/lib/api/cliente_api.dart apps/mobile/lib/comun/dialogo_error.dart apps/mobile/test/limite_de_frecuencia_test.dart && cd apps/mobile && flutter analyze
mutate apps/mobile/lib/api/cliente_api.dart [timeout 90 min]: cd apps/mobile && flutter test test/limite_de_frecuencia_test.dart
mutate apps/mobile/lib/comun/dialogo_error.dart [timeout 90 min]: cd apps/mobile && flutter test test/limite_de_frecuencia_test.dart
mutate apps/api/app/interfaz/horarios.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py tests/escenarios/test_seguridad_entradas_extra.py
mutate apps/api/app/interfaz/respuestas.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_seguridad_api.py tests/escenarios/test_seguridad_entradas_extra.py
mutate apps/api/app/dominio/notificaciones.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/unit
mutate apps/api/app/dominio/horarios.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/unit tests/escenarios/test_seguridad_api.py
app: sh D:/Temp/w/herramientas/api-app.sh rev01_app
attacks: sh D:/Temp/w/herramientas/api-attacks.sh rev01_app --json --no-ambient --common-headers "Content-Security-Policy" --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --read /reservas/todas
```

## Log

- L1 · Transcripción sin interpretación. Cada bloque dice de qué fuente sale. Los bloques van en el texto original; no se corrigieron espacios ni acentos.

**Encabezado del documento** (source: specs/REVISION-kit3.md @138bc54, líneas 1-5)

```text
# Revisión general · ClubNahuelMosse · kit SDD 3.0.0 · grado production

Rama `kit-3` @ 932cf77 · 2026-10-20 · módulos activos: ui, api, data, infra, observability, security-l2 (ci, docs e
i18n apagados por decisión). Revisión de la app entera —API, app Flutter, datos, despliegue y seguridad— contra los
177 criterios activos de `node .claude/tools/bar.mjs`. No se corrigió código ni se abrieron cards.
```

**Hallazgo 1** (source: specs/REVISION-kit3.md @138bc54, hallazgo 1 completo)

```text
1. **El correo SMTP no verifica el certificado del servidor** · ASVS V12.3.2 · falló · medido
   - `apps/api/app/infraestructura/correo.py:30-32`: `smtp.starttls()` sin `context`; el contexto por defecto no
     verifica (`verify_mode 0`, `check_hostname False`).
   - Evidencia: contra un SMTP falso con certificado autofirmado `CN=atacante.invalid`, el cliente aceptó el TLS y el
     servidor capturó el usuario y la contraseña SMTP y el enlace `/enlace/recuperar#codigo=…`.
   - Impacto: quien esté en el camino de red entre Render y el SMTP se lleva las credenciales y cada enlace de
     recuperación, es decir, la cuenta de cualquiera que pida recuperar la contraseña.
```

**Hallazgo 5** (source: specs/REVISION-kit3.md @138bc54, hallazgo 5 completo)

```text
5. **Entradas sin cota dan 500** · K8, ASVS V1.4.2, V2.2.1 · falló · medido
   - `POST /reservas` con `horas = 10**12` → 500 (OverflowError en `aplicacion/reservas.py:162`, antes de validar). Con
     `fecha 9999-12-31, desde 23:00, horas 4` → 500 (date out of range, misma línea).
   - `GET /reservas/todas?pagina=2**70` → 500 (`infraestructura/reservas.py:506`; `Query` sin `le` en
     `interfaz/reservas.py:380`).
   - Un NUL en nombre, sede, motivo, token o correo → 500 (psycopg DataError) en 7 rutas, dos de ellas sin sesión
     (`/registro`, `/recuperacion`).
   - Impacto: cualquiera fuerza 500 y cada uno deja un ERROR con traceback; sin sesión se puede inundar el log.
```

**Hallazgo 6** (source: specs/REVISION-kit3.md @138bc54, hallazgo 6 completo)

```text
6. **La API no tiene límite de frecuencia y deja consultar DNI y correos** · S24, ASVS V2.4.1 · falló · medido
   - `apps/api/app/main.py:41-62`: 30 `POST /recuperacion` en 0,9 s → 30 × 202; 20 `POST /registro` en 0,4 s → 20 × 422
     sin 429.
   - Oráculo: `PUT /yo` con DNI ajenos 31000001…31000007 → `[409, 200, 200, …]`, con el 409 «Este DNI ya está registrado»
     (`interfaz/sesion.py:163-167`); `/registro` con un correo ajeno → 409 «Este correo ya está registrado»
     (`interfaz/registro.py:70-78`).
   - Impacto: cualquiera con sesión consulta sin freno si un DNI es socio; `/registro` crea cuentas de Firebase sin
     verificar el correo y sin límite.
```

**Hallazgo 7** (source: specs/REVISION-kit3.md @138bc54, hallazgo 7 completo)

```text
7. **Dependencia con vulnerabilidad conocida** · S11 · falló · medido
   - `apps/api/uv.lock:133-134`: certifi 2026.7.22 tiene PYSEC-2026-4320 / GHSA-6q48-6c7w-9gw2 (intermedias emSign
     comprometidas); corregido en ≥ 2026.10.18. `pubspec.lock`: 0 avisos en OSV.
   - Impacto: firebase-admin confía en esas intermedias al bajar las claves que validan los ID tokens; explotarlo
     requiere estar en el camino de red.
```

**Hallazgo 9** (source: specs/REVISION-kit3.md @138bc54, hallazgo 9 completo)

```text
9. **Datos personales en los logs, y log falsificable** · P2, O5, S14, ASVS V16.4.1 · falló · medido
   - Un `SMTPRecipientsRefused` escribe el correo de la persona en el log (`infraestructura/correo.py:42`).
   - El access log de uvicorn guarda el query string: `GET /reservas/todas?q=…%40ejemplo.com` y `?q=39222333`, es decir,
     correo y DNI que busca el admin.
   - `interfaz/registro_errores.py:62-63` registra `scope["path"]` sin escapar: un `POST` sin token a
     `/reservas/1%0a2026-10-20 00:00:00,000 ERROR clubnahuelmosse.errores FALSO/cancelar` dejó una línea ERROR
     falsificada.
   - Ningún test manda un secreto (contraseña, token, código de recuperación) para verificar que no llegue al log.
```

**Hallazgo 16** (source: specs/REVISION-kit3.md @138bc54, hallazgo 16 completo)

```text
16. **Swagger abierto en producción y sin CSP** · W8, S7 · falló · lectura
    - `apps/api/app/main.py:43-47` no apaga `docs_url`, y `render.yaml:14` usa `/docs` como health check: una API interna
      con datos personales expone su mapa y un «Try it out».
    - No hay contrato OpenAPI versionado ni linteado. Ninguna respuesta trae `Content-Security-Policy` ni
      `frame-ancestors` (`interfaz/protecciones.py:5`); `/docs` carga JS de un CDN.
```

**Hallazgo 25** (source: specs/REVISION-kit3.md @138bc54, hallazgo 25: encabezado y viñetas S2, Emulador de Auth y Dispositivos; S12 y S18 no transcriptos, ver not_read)

```text
25. **Seguridad menor** · falló · medido
    - **S2:** se acepta un `Host` ajeno; con token, `Host: attacker.example` → 200/201 (`app/main.py:41-62`).
    - **Emulador de Auth:** con `FIREBASE_AUTH_EMULATOR_HOST` definido, firebase-admin acepta tokens sin firma (un JWT
      `alg none` con el uid del admin dio rol admin). Lo único que lo frena es que `render.yaml` no defina la variable;
      la API no se niega a arrancar si aparece junto a credenciales reales (`infraestructura/identidad.py:19-25`).
    - **Dispositivos:** `PUT /dispositivos` con el token FCM de otro reasigna el dispositivo
      (`infraestructura/notificaciones.py:294-297`). Hace falta conocer el token ajeno.
```

**Pedido del coordinador** (source: pedido (texto))

```text
Corregir los hallazgos 1, 5, 6, 7, 9, 16 y 25 (S2, emulador de Auth, dispositivos) de la revisión kit 3.0.0 siguiendo el kit. Archivos principales: infraestructura/correo.py, interfaz/{sesion,registro,reservas,protecciones,registro_errores}.py, main.py, identidad.py, uv.lock.
```

**Enunciado** (source: D:/desktop folders/estudio/Universidad de moron/Electiva general/Trabajo Práctico_2026.docx.pdf, pdftotext -enc UTF-8 -layout; se omitieron caracteres de ancho cero que el PDF trae y no se imprimen)

```text
                           Universidad de Morón - Docente: Marcelo Camicha

           ELECTIVA GENERAL
               Trabajo Práctico

Gestión de espacios deportivos

Desarrollar una aplicación móvil para la gestión de espacios deportivos

La aplicación permitirá:
    ●  que los usuarios reserven espacios deportivos desde sus celulares
    ●  consultar disponibilidad de espacios deportivos de diferentes sedes
    ●  recibir notificaciones push sobre reservas próximas.

El sistema deberá incluir tanto el desarrollo de APIs para la gestión de reservas, sedes,
espacios deportivos y perfiles de usuarios, como el desarrollo de la aplicación móvil en
Flutter.

Requerimientos Funcionales

1.  Registración, inicio de sesión y recuperación de contraseña
    ●  Registro de usuarios mediante correo electrónico y contraseña.
    ●  Una vez iniciada la sesión, la aplicación deberá mostrar una página inicial (Home

         Page).
    ●  Los usuarios que olviden su contraseña deberán disponer de un mecanismo seguro

         para recuperarla o establecer una nueva contraseña.

2.  Perfil de usuario:
    ●  Se deben mostrar todos los datos del perfil de usuario y permitir su edición, salvo la
         dirección de correo electrónico.

    ●  El perfil deberá incluir, como mínimo, nombre, apellido y fecha de nacimiento.
    ●  Se deberá poder cerrar la sesión.

3.  Gestión de reservas
    ●  Los horarios disponibles para las reservas deberán estar comprendidos dentro de
         los horarios de funcionamiento de la sede correspondiente.

    ●  Una reserva corresponde a un espacio deportivo, una fecha, una hora de inicio y una
         hora de finalización.

    ●  La duración mínima de una reserva será de una hora. Los horarios de inicio y
         finalización deberán corresponder a horas completas, es decir, deberán comenzar y
         finalizar en el minuto 00. Por ejemplo: 18:00 a 19:00, 18:00 a 20:00, etc.

                                                                                                                          1
                          Universidad de Morón - Docente: Marcelo Camicha

    ●  La hora de finalización de una reserva no podrá superar el horario de cierre de la
         sede.

    ●  Las reservas deberán realizarse para horarios futuros respecto del momento en que
         se efectúa la reserva.

    ●  Al reservar un espacio deportivo para una fecha y horario determinados, dicho
         espacio no podrá ser reservado por otro usuario para la misma fecha si existe
         superposición de horarios. El backend deberá validar la disponibilidad del espacio
         deportivo antes de registrar una reserva.

    ●  Se deberá:
              ○  Poder consultar la disponibilidad de espacios deportivos según la sede.
              ○  Reservar un espacio deportivo para una fecha y horario determinados.
              ○  Listar las reservas realizadas por el usuario, indicando sede, espacio
                   deportivo, fecha y horario.
              ○  Cancelar una reserva. Al cancelar una reserva, el espacio deportivo deberá
                   volver a estar disponible para ese mismo horario.
              ○  Recibir notificaciones push sobre reservas próximas.

4.  Módulo de Sedes
    ●  Cada sede deberá contar, como mínimo, con un nombre, una dirección y horarios de
         funcionamiento.

    ●  Mostrar el listado de sedes, sus horarios de funcionamiento y permitir seleccionar
         una sede para consultar sus espacios deportivos y horarios disponibles.

5.  Módulo de Espacios deportivos
    ●  Mostrar el listado de espacios deportivos indicando la sede donde se ubica cada
         uno.

    ●  Cada espacio deportivo deberá estar asociado a una sede y contar, como mínimo,
         con un tipo y un nombre compuesto por la sede, dirección, tipo de espacio deportivo
         y un número. Por ejemplo: Moron_Rivadavia_19850_Paddle_1.

    ●  Permitir filtrar los espacios deportivos por tipo (Fútbol, Paddle, Básquet, etc.).

6.  Historial de reservas
    ●  Acceder al historial de reservas realizadas, incluyendo las reservas cuyo horario ya
         haya finalizado.

7.  Manejo de errores
    ●  Se debe poder manejar los errores que puedan surgir durante el uso de la
         aplicación. Por ejemplo sin conexión a internet, servidor caído, login incorrecto,
         usuario ya registrado, etc.

                                                                                                                         2
                           Universidad de Morón - Docente: Marcelo Camicha

8.  Nombre de la aplicación
    ●  El nombre de la aplicación debe ser Club [Nombre y Apellido del alumno o alumna].
         Por ejemplo: ClubJuanaGonzalez.

9.  Nombre del repositorio GITHUB
    ●  El nombre del repositorio de GitHub deberá coincidir con el nombre de la aplicación.
         Por ejemplo: ClubJuanaGonzalez.

Requerimientos No Funcionales

1.  Aplicación móvil
    ●  El diseño de UX/UI se deberá realizar utilizando Figma
    ●  La aplicación móvil se deberá realizar utilizando Flutter

2.  Repositorio
    ●  El proyecto deberá gestionarse mediante un repositorio GitHub.
    ●  Cada alumno deberá utilizar su propia cuenta de GitHub y realizar commits durante

         el desarrollo del proyecto.
    ●  El historial del repositorio podrá ser considerado como parte del proceso de

         evaluación.

3.  REST API:
    ●  La API REST deberá estar documentada mediante Swagger/OpenAPI.
    ●  Se podrá elegir el lenguaje que se desee. (Preferentemente Python)

4.  BBDD:
    ●  Se podrá elegir cualquier base de datos relacional. (Preferentemente PostgreSQL)

5.  Cloud
    ●  La API REST y la base de datos deberán estar disponibles en la nube.
    ●  Se podrán utilizar servicios como Render para el despliegue de la API y base de

         datos, y Firebase para autenticación y notificaciones push.
    ●  Las operaciones de la API relacionadas con usuarios y reservas deberán identificar

         al usuario autenticado.

                                                                                                                          3
                           Universidad de Morón - Docente: Marcelo Camicha

6.  Readme
    ●  Tanto la aplicación móvil como el backend deberán contar con un archivo README
         que explique todos los pasos necesarios para configurar, ejecutar y, cuando
         corresponda, desplegar cada proyecto.

Entregables para evaluación

1.  Entrega 1 (Diseño)
    ●  Mockup y prototipo navegable desarrollado en Figma.
    ●  La Entrega 1 será presentada y defendida grupalmente.
    ●  Cada alumno deberá subir a Blackboard la documentación que se indicará luego de
         la presentación.

2.  Entrega 2 (Desarrollo y Modelo)
    ●  Backend desplegado en la nube y aplicación móvil conectada a la API REST.
    ●  Aplicación móvil en Flutter
    ●  Icono
    ●  Inicio de sesión, registración y recuperación de contraseña
    ●  Gestión de reservas
    ●  Modelo de datos de la aplicación, incluyendo entidades, atributos y relaciones.
    ●  Manejo de errores (sin conexión a internet, servidor caído, login incorrecto, usuario
         ya registrado, etc.)
    ●  Mostrar aplicación funcionando en emulador.
    ●  Subir a la plataforma Blackboard, antes de la exposición, el código del backend (ZIP)
         y el código de la aplicación móvil (ZIP).
    ●  La Entrega 2 será individual y deberá ser defendida individualmente. Cada alumno
         deberá demostrar conocimiento del funcionamiento general de su aplicación y de las
         decisiones de diseño e implementación adoptadas.

                                                                                                                          4
```

**CU-03 · Registrar usuario** (source: D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-03 Registrar usuario.pdf, pdftotext -layout)

```text
      ESPECIFICACIÓN DE CU

Nombre del Proyecto / Sistema: Gestión de espacios deportivos
Nombre del Alumno: Gonzalo Gil
Matrícula: 5301-1995
Fecha de Entrega: 08-09-2026
Caso(s) de Uso Asignado(s): Registrarse en la aplicacion
Definición General del Caso de Uso

     ● Nombre del Caso de Uso: Registrarse en la aplicacion

     ● ID / Código: CU-03

     ● Actor(es) Principal(es): Usuario

     ● Objetivo: Permitir que un nuevo usuario cree una cuenta dentro de la aplicación móvil
        ingresando su nombre, apellido, dni, fecha de nacimiento, correo electrónico y contraseña,
        para así poder acceder a la plataforma y realizar reservas deportivas.

     ● ¿Qué problema resuelve?: Resuelve la necesidad de autenticar e identificar de manera
        única a los usuarios en el sistema, permitiéndoles acceder a funcionalidades personalizadas
        como la consulta de disponibilidad, gestión de reservas y edición del perfil de usuario.

Precondiciones y Poscondiciones

Precondiciones

     ● La aplicación móvil debe estar instalada y ejecutándose en el dispositivo.
     ● El dispositivo debe contar con conexión activa a internet.

Poscondiciones (Estado final del sistema)

     ● Se crea con éxito la cuenta del usuario en la base de datos y backend del sistema.
     ● El sistema devuelve al usuario a la pantalla de login

Flujo Principal (Camino Feliz)

               Paso          Acción del Actor           Respuesta / Validación del
1                                                                   Sistema
                     El usuario selecciona la opción
2                    para registrarse.                 El sistema muestra el
3                                                      formulario de registro
                     El usuario ingresa los datos y    solicitando nombre, apellido,
                     presiona el botón de "crear       dni, fecha de nacimiento,
                     cuenta".                          correo electrónico y
                     El backend procesa la             contraseña.
                     solicitud, crea el nuevo perfil   El sistema valida el formato de
                     de usuario y autentica la sesión  los datos ingresados y envía la
                                                       solicitud al servidor/backend.
                                                       El sistema notifica al usuario
                                                       que su cuenta fue registrada
                                                       con exito

4                    El usuario presiona el boton de El sistema carga la pantalla de
                     “Volver al login”                 inicio de sesion de la
                                                       aplicacion
Flujos Alternativos y Excepciones

Flujo Alternativo 1: Datos incompletos

     ● Paso de origen: Paso 2 del flujo principal.
     ● Condición: Falta completar algún campo obligatorio.
     ● Acción del sistema: Se muestra un mensaje/tooltip en pantalla indicando los campos

        faltantes

Flujo Alternativo 2: Usuario ya registrado

     ● Paso de origen: Paso 3 del flujo principal
     ● Condición: El correo electrónico y/o el dni ingresado ya se encuentra registrado

        previamente en la base de datos del sistema
     ● Acción del sistema: El sistema retorna un mensaje de error indicando que el usuario ya está

        registrado, permaneciendo en la pantalla de registro para permitir modificar los datos.

Diseño UX/UI (Resolución en Figma)

Pantallas y Vistas Involucradas

     ● Pantalla 1: [Pantalla de login]
● Pantalla 2: [Pantalla de inicio de registro]
● Pantalla 3: [Registro – datos parciales]
● Pantalla 4: [Registro – error campos vacios]
● Pantalla 5: [Registro – datos ingresados]
● Pantalla 6: [Registro – usuario ya registrado]
● Pantalla 7: [Registro – usuario cambia email y dni]
● Pantalla 8: [Registro – exitoso]
Componentes del Sistema de Diseño Utilizados

     ● Criterio Unificado:
              ● Botones: Boton "Crear cuenta” con los datos ingresados, boton “Volver” para
                 regresar a la pantalla de login y boton “volver al login” para regresar a la pantalla de
                 login

              ● Campos / Inputs: Campos para ingresar el nombre, apellido, dni, email y contraseña

              ● Mensajes / Feedback: mensaje de error al no completar todos los campos o al
                 intentar registrar un usuario ya existente
```

**CU-04b · Recuperar contraseña** (source: D:/desktop folders/estudio/Universidad de moron/Electiva general/CU-nuevos/CU-04b - Recuperar contraseña.md, Read)

```text
# CU-04b · Recuperar contraseña

**Módulo:** Autenticación · **Actor principal:** Usuario registrado sin sesión iniciada
**Estado:** NO figura en la lista de reparto de casos de uso. El enunciado lo exige
(Requerimientos Funcionales, punto 1: "Los usuarios que olviden su contraseña deberán disponer de
un mecanismo seguro para recuperarla o establecer una nueva contraseña"), y CU-01 FA3 lo referencia
como destino, pero nadie lo tenía asignado. En el Figma grupal existían dos frames sueltos
("Olvidé mi contraseña" y "Email enviado") sin sección, sin caso de uso y sin conexiones.

## Objetivo
Permitir que un usuario que no recuerda su contraseña establezca una nueva sin necesidad de
conocer la anterior, verificando su identidad mediante un enlace enviado a su correo.

## Problema que resuelve
Es la única vía de reingreso para alguien que quedó afuera de su cuenta. Sin esto, el usuario
pierde el acceso de forma definitiva.

## Precondiciones
- El usuario está en la pantalla de Login, sin sesión iniciada.
- Hay conexión con el backend.

## Postcondiciones
- Si el correo estaba registrado, se emitió un enlace de un solo uso con vencimiento a 30 minutos.
- Al completarse, la contraseña queda reemplazada y todas las sesiones previas se invalidan.
- El usuario queda en el login para entrar con la contraseña nueva.

## Flujo principal
| # | Acción del usuario | Respuesta del sistema |
|---|---|---|
| 1 | Presiona "¿Olvidaste tu contraseña?" en el login. | Navega a la pantalla Recuperar contraseña. |
| 2 | Escribe su correo electrónico. | Valida el formato y habilita "Enviar enlace". |
| 3 | Presiona "Enviar enlace". | Solicita el envío al backend y muestra la pantalla de correo enviado. |
| 4 | Abre el enlace desde su correo. | Valida el token y muestra la pantalla de contraseña nueva. |
| 5 | Escribe y repite la contraseña nueva. | Valida las reglas y habilita "Guardar contraseña". |
| 6 | Presiona "Guardar contraseña". | Reemplaza la contraseña, invalida el enlace y las sesiones previas, y muestra la confirmación. |
| 7 | Presiona "Volver al login". | Regresa al login. |

## Regla de seguridad
El sistema **responde siempre lo mismo** exista o no el correo en la base: "Si el correo está
registrado, te enviamos un enlace". Decir "ese correo no existe" permitiría enumerar qué
direcciones tienen cuenta. Es el mismo criterio con el que CU-01 FA2 pide un mensaje genérico
para las credenciales inválidas.

## Flujos alternativos
- **FA1 · El correo no está registrado** (origen paso 3). El sistema muestra la misma pantalla de
  correo enviado y no envía ningún mail. Ver la regla de seguridad.
- **FA2 · Formato de correo inválido** (origen paso 2). El botón permanece deshabilitado y el campo
  queda marcado.
- **FA3 · El enlace venció o ya se usó** (origen paso 4). Se muestra la pantalla "El enlace no es
  válido", con la opción de pedir uno nuevo.
- **FA4 · Las contraseñas no coinciden** (origen paso 5). El botón permanece deshabilitado.
- **FA5 · El usuario reenvía el correo** (origen paso 3). Desde la pantalla de correo enviado puede
  pedir un reenvío, que invalida el enlace anterior.
- **FA6 · Error de conexión o del servidor** (origen pasos 3 y 6). Se abre el overlay compartido
  correspondiente. No se cambia nada.

## Pantallas
`CU-04b · Recuperar contraseña · Solicitar` · `CU-04b · Recuperar contraseña · Email enviado` ·
`CU-04b · Recuperar contraseña · Nueva contraseña` · `CU-04b · Recuperar contraseña · Enlace inválido`

## Componentes
`AppBar` · `Input` de correo y de contraseña · `Btn` Primary con estado Disabled · pantalla de
resultado a pantalla completa con `Icon/mail` y `Icon/alert-triangle` · `Modal` para errores.

## Mensajes
- "Si el correo está registrado, te enviamos un enlace para crear una contraseña nueva. El enlace vence en 30 minutos."
- "El enlace no es válido. Este enlace ya se usó o venció."
```

**CU-06 · Editar perfil** (source: D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-06 - Editar perfil.pdf, pdftotext -layout)

```text
ESPECIFICACIÓN DE CU

Nombre del Proyecto / Sistema: Gestión de espacios deportivos
Nombre del Alumno: Nicolás Colli
Matrícula: 53010795
Fecha de Entrega: 08-09-2026
Caso(s) de Uso Asignado(s): CU-06 Editar Perfil
Definición General del Caso de Uso

     ● Nombre del Caso de Uso: Editar perfil

     ● ID / Código: CU-06

     ● Actor(es) Principal(es): Usuario Registrado

     ● Objetivo: El usuario registrado modifique los datos de su perfil.

     ● ¿Qué problema resuelve?: permitir editar datos al usuario ya sea por algún error en la
        carga o cambio de preferencia en tema.

Precondiciones y Poscondiciones

Precondiciones

     ● El usuario debe haber iniciado sesión en la plataforma

Poscondiciones (Estado final del sistema)

     ● Los datos modificados del cliente quedan guardados en su perfil.

Flujo Principal (Camino Feliz)

   Paso  Acción del Actor                Respuesta / Validación del
                                                     Sistema
1        El usuario selecciona la
         opción “Perfil” del menu       El sistema carga y muestra los
         inferior                       datos del usuario con la opción
                                        modo oscuro y eliminar cuenta
2        Seleccionar botón “editar” en  El sistema cambia la interfaz
         box “datos personales”         para que los datos personales
                                        sean editables y coloca el
3        Rellenar campos con datos      botón “Guardar”
         nuevos                         El sistema muestra en pantalla
                                        los nuevos datos modificados
                                        por el usuario
4        Seleccionar botón “guardar”
                                        El sistema valida que el
5        Selección botón “modo          formato de los datos sean
         oscuro”                        correctos y guarda los datos
                                        modificados
                                        El sistema cambia el modo al
                                        opuesto que se encuentra en
                                        ese instante
Flujos Alternativos y Excepciones

Flujo Alternativo 1: Formato de datos invalido.

     ● Paso de origen: Paso 4 del flujo principal.

     ● Condición: Formato de datos invalido.

     ● Acción del sistema: Muestra un mensaje de error "El formato de los datos no es valido",
        muestra en rojo aquellos datos que no pueden ser guardados por formato invalido y en verde
        aquellos que estén correctos y vuelve al paso 3 del flujo principal.

Flujo Alternativo 2: Error de conexión.

     ● Paso de origen: Paso 4 del flujo principal.

     ● Condición: Error de conexión con la aplicación.

     ● Acción del sistema: Muestra un mensaje de error "Error de conectividad", informa que no
        tiene conexión con la aplicación y vuelve al paso 3 del flujo principal.
Diseño UX/UI

Pantallas y Vistas Involucradas

     ● Pantalla 1: Mi perfil:
● Pantalla 2: Mi perfil modo edición:
· Pantalla 3: Mi perfil modo claro:
· Pantalla 4: Error formato de datos
· Pantalla 5: error de conexión
```

**CU-09 · Reservar cancha** (source: D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-09_Reservar_cancha_MartinGaser .pdf, pdftotext -layout)

```text
ESPECIFICACIÓN DE CU

Nombre del Proyecto / Sistema: Gestión de espacios deportivos
Nombre del Alumno: Martín Gaser
Matrícula: 5501-2072
Fecha de Entrega: 08-09-2026
Caso(s) de Uso Asignado(s): CU-09: Reservar cancha
Nota: Todos los integrantes del equipo deben utilizar este mismo formato para
mantener el criterio unificado de presentación exigido para la entrega en PDF.

Definición General del Caso de Uso

    ● Nombre del Caso de Uso: Reservar cancha
    ● ID / Código: CU-09
    ● Actor(es) Principal(es): Usuario registrado
    ● Objetivo: Permitir que el usuario registrado reserve una cancha disponible,

         eligiendo sede, cancha, fecha y horario, para asegurarse su turno de juego.
    ● ¿Qué problema resuelve?: Elimina la necesidad de reservar turnos de forma

         manual o telefónica, permitiendo al usuario autogestionar su reserva en tiempo
         real y evitando superposiciones de horarios en una misma cancha.

Precondiciones y Poscondiciones

Precondiciones
    ● El usuario debe estar autenticado en la plataforma.
    ● Debe existir al menos una sede cargada y habilitada.
    ● La cancha debe estar en estado "Habilitada" y tener horarios cargados.

Poscondiciones (Estado final del sistema)
    ● La reserva queda registrada en estado "Confirmada", asociada al usuario, la
         cancha, la fecha y el horario elegidos.
    ● Se descuenta la disponibilidad de ese horario para esa cancha y fecha,
         quedando bloqueado para otros usuarios.
    ● Se envía una notificación/correo de confirmación de la reserva al usuario.

Flujo Principal (Camino Feliz)

Paso Acción del Actor             Respuesta / Validación del Sistema

1  El usuario selecciona la sede  El sistema carga y muestra las
   deseada.                       canchas disponibles para esa sede.

2  Selecciona la cancha deseada.  El sistema habilita el selector de fecha
                                  y muestra el calendario de
3  Selecciona la fecha deseada.   disponibilidad.

                                  El sistema consulta y despliega las
                                  franjas horarias disponibles para esa
                                  cancha y fecha.
Paso Acción del Actor              Respuesta / Validación del Sistema

4  Selecciona el horario deseado.  El sistema habilita el botón "Confirmar
                                   Reserva" y muestra el resumen
5  Presiona "Confirmar Reserva".   (cancha, fecha, horario y costo).

                                   El sistema valida los datos, registra la
                                   reserva en estado "Confirmada" e
                                   informa la confirmación al usuario.

Flujos Alternativos y Excepciones

Flujo Alternativo 1: Horario No Disponible

     ● Paso de origen: Paso 4 del flujo principal.
     ● Condición: El horario seleccionado para la cancha ya no se encuentra libre (otro usuario lo
          reservó primero).
     ● Acción del sistema: Muestra un mensaje de advertencia "El horario seleccionado ya no está
          disponible. Por favor elija otro turno", deshabilita el botón de confirmación y actualiza la grilla de
          horarios disponibles.

Flujo Alternativo 2: Datos Incompletos o Inválidos
    ● Paso de origen: Cualquier paso del flujo.
    ● Condición: Falta seleccionar algún campo obligatorio (ej. cancha, fecha u
         horario sin elegir).
    ● Acción del sistema: El botón "Confirmar Reserva" permanece deshabilitado
         (disabled). Se muestra un tooltip o mensaje indicando el campo faltante.

Flujo Alternativo 3: Usuario No Autenticado
    ● Paso de origen: Al intentar ingresar al flujo de reserva de cancha.
    ● Condición: La sesión del usuario expiró o no ha iniciado sesión.
    ● Acción del sistema: Redirecciona a la pantalla de Login, guardando el estado o
         intención previa de reserva de cancha.

Diseño UX/UI (Resolución en Figma)

Pantallas y Vistas Involucradas
● Pantalla 1: Confirmá tu reserva

    Muestra en pantalla a través de una tarjeta la cancha que se esta reservando, el
    día, el horario y el precio y el botón para confirmar la reserva.
● Pantalla 2: Comprobante de Reserva Confirmada
    En esta pantalla nos muestra que nuestra reserva ya fue confirmada, y
    automaticamente te redirige a la sección en la aplicación de tus reservas.

● Pantalla 3: Variantes en Modo Nocturno
Componentes del Sistema de Diseño Utilizados
● Criterio Unificado: Estilo visual sobre interfaz clara/blanca en la vista de
    confirmación, manteniendo como color de acento principal el verde lima
    (#D4FF3D) para acciones primarias y estados activos, texto oscuro/negrito para
    los títulos e información clave, gris intermedio para las etiquetas secundarias, y
    rojo para las acciones destructivas o de cancelación. AppBar-Simple: Barra
    superior con botón circular de "volver" y título en negrita (ej. "Confirmá tu
    reserva")

● AppBar-Simple: Barra superior de navegación en fondo claro que incluye el
    botón de retroceso (<) y el título principal en negrita "Confirmá tu reserva".

● Stepper de progreso: Componente Stepper-Progreso de 3 pasos (1. Elegí
    cancha / 2. Confirmás / 3. ¡Listo!), con ícono de check en lima sobre los pasos
    completados, número dentro de círculo lima resaltando el paso activo, y línea de
    progreso lima entre pasos cumplidos (gris en los pendientes)

● Link-Breadcrumb: Enlace de retorno interno (< Sedes) situado dentro de la
    cabecera de la tarjeta para navegar hacia atrás sin perder la referencia de la
    ubicación.

● Card-Reserva: Componente de tarjeta estructurado como resumen de reserva,
    compuesto por:

○ Header visual: Banner superior con imagen temática, superposición

azulada, etiqueta de categoría     (FÚTBOL - FÚTBOL 5) y el
nombre destacado de la sede (SEDE MORÓN).

○ Cuerpo de información: Contenedor claro con bordes redondeados y
    división por líneas horizontales.

● Row-DetalleReserva: Filas de información estructuradas con la etiqueta en gris
    a la izquierda (Cancha, Fecha, Horario, Total) y los valores alineados a la
    derecha en tipografía oscura en negrita. La fila Total resalta su valor ($7.600)
    utilizando el color de acento verde lima.

● Botones (Acciones principales):

○ Btn-Primary: Botón de acción principal de ancho completo en color verde
    lima (#D4FF3D), esquinas redondeadas y texto en negrita negra:
    "CONFIRMAR RESERVA".

○ Btn-Outline-Danger: Botón secundario de cancelación de ancho completo
    con fondo transparente, contorno rojo y texto rojo: "Cancelar".
```

**CU-14 · Consultar historial global de reservas (Administrador)** (source: D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-14_Especificacion_Francisco_Luciano.pdf, pdftotext -layout)

```text
      ESPECIFICACIÓN DE CU

Nombre del Proyecto / Sistema: Gestión de espacios deportivos
Nombre del Alumno: Francisco Luciano
Matrícula: 54010262
Fecha de Entrega: 08-09-2026
Caso(s) de Uso Asignado(s): CU-14: Consultar el historial de todas las
reservas del sistema (Administrador)
Nota: Todos los integrantes del equipo deben utilizar este mismo formato para mantener el criterio
unificado de presentación exigido para la entrega en PDF.

Definición General del Caso de Uso

     ● Nombre del Caso de Uso: Consultar historial global de reservas (Panel de Administración)
     ● ID / Código: CU-14
     ● Actor(es) Principal(es): Administrador del club (usuario autenticado con rol de

        administración). Actor secundario: el sistema de reservas, que provee los datos consultados.
     ● Objetivo: Acceder a la totalidad de las reservas registradas en el sistema de todas las sedes,

        todos los espacios y todos los usuarios, poder filtrarlas y consultar el detalle de cualquiera de
        ellas, para controlar el uso de las instalaciones y responder consultas o reclamos.
     ● ¿Qué problema resuelve?: Un administrador no puede gestionar el club viendo únicamente
        sus propias reservas: la pantalla "Mis reservas" está acotada al usuario que la consulta. Sin
        una vista global no hay forma de saber quién reservó cada espacio, con qué frecuencia se usa
        cada cancha, ni qué pasó con una reserva cancelada. Este caso de uso resuelve necesidades
        concretas del negocio: auditar la actividad del club, resolver reclamos de socios sobre
        reservas puntuales, detectar usos indebidos o cancelaciones reiteradas, y obtener evidencia
        para decidir horarios, precios y mantenimiento. Es principalmente un flujo de consulta y
        auditoría; además, desde la misma vista el administrador puede anular una reserva vigente
        mediante una acción con confirmación, que libera la franja horaria.

Precondiciones y Poscondiciones

Precondiciones

     ● El administrador se encuentra autenticado en la plataforma y su sesión está vigente.
     ● La cuenta posee rol de Administrador, que habilita el permiso de lectura sobre las reservas

        de todos los usuarios y la acción de anular.
     ● Existe al menos una sede cargada y habilitada en el sistema.
     ● Existe al menos una reserva registrada, vigente o histórica, sobre la cual consultar.
     ● La aplicación tiene conexión con la API de reservas.

Poscondiciones (Estado final del sistema)

     ● La consulta del historial no modifica el estado del sistema: no crea ni edita reservas.
     ● Se muestra el listado de reservas de todos los usuarios, agrupado por fecha y ordenado de la

        más reciente a la más antigua, con un contador de resultados.
     ● Los filtros y la búsqueda aplicados quedan visibles en pantalla y pueden limpiarse para

        volver al listado completo.
     ● Si el administrador anula una reserva vigente, esta pasa al estado Cancelada, se libera la
   franja horaria y la anulación queda registrada con su trazabilidad (autor y fecha).

● La operación queda registrada en el log de auditoría del backend (fecha, administrador,
   filtros utilizados y acción realizada).

Flujo Principal (Camino Feliz)

               Paso  Acción del Actor                  Respuesta / Validación del
1                                                                  Sistema
2
3                    Desde el Panel de                 El sistema valida que la sesión
                     Administración, el                tenga rol de Administrador y
4                    administrador entra a la          solicita a la API el historial
5                    pestaña "Reservas".               completo de reservas.
6
7                    Aguarda la respuesta del          El sistema muestra el estado
                     sistema.                          de carga mientras resuelve la
8                                                      consulta, evitando una pantalla
                                                       en blanco.

                     Visualiza el listado de reservas  El sistema despliega las
                     ("Todas").                        reservas de todos los usuarios,
                                                       mostrando en cada tarjeta el
                                                       deporte, la sede, el nombre
                                                       técnico del espacio, el usuario
                                                       que reservó, la franja horaria,
                                                       el precio y el estado de la
                                                       reserva. Encabeza el listado el
                                                       contador total.

                     Usa las pestañas de estado        El sistema filtra el listado por
                     (Todas, Activas, Completadas,     el estado elegido y actualiza el
                     Anuladas).                        contador de resultados.

                     Presiona el botón "Filtros".      El sistema despliega el panel
                                                       de filtros con los criterios
                                                       disponibles: buscador por
                                                       texto, sede, deporte, estado y
                                                       rango de fechas.

                     Selecciona los criterios          El sistema valida el rango de
                     deseados y presiona "Aplicar".    fechas, cierra el panel y
                                                       solicita a la API el listado
                                                       filtrado. Muestra una barra de
                                                       filtros activos y la cantidad de
                                                       resultados obtenidos.

                     Escribe el nombre de un           El sistema filtra el listado en
                     usuario, sede o espacio en el     vivo y muestra solo las
                     campo de búsqueda.                reservas que coinciden con el
                                                       texto ingresado, actualizando
                                                       el contador. La búsqueda se
                                                       combina con los filtros que ya
                                                       estuvieran aplicados.

                     Toca una de las reservas del El sistema abre el detalle en
               Paso         Acción del Actor        Respuesta / Validación del
9                    listado.                                   Sistema
10
                     Sobre una reserva vigente,    modo lectura: deporte y
                     presiona "Anular" y confirma  espacio, sede y dirección,
                     la acción.                    usuario, fecha y horario,
                     Presiona "Volver".            precio, estado y la trazabilidad
                                                   de la reserva (creación y, si
                                                   corresponde, anulación).

                                                   El sistema pide confirmación;
                                                   al confirmar, cambia el estado
                                                   de la reserva a Cancelada,
                                                   libera la franja horaria y
                                                   muestra el detalle con la
                                                   trazabilidad de la anulación
                                                   ("Anulada por el
                                                   administrador").

                                                   El sistema regresa al listado
                                                   conservando los filtros
                                                   aplicados y la posición en la
                                                   que estaba el administrador.

Flujos Alternativos y Excepciones

Flujo Alternativo 1: Sin resultados para los criterios aplicados

     ● Paso de origen: Pasos 6 o 7 del flujo principal.

     ● Condición: La combinación de filtros seleccionada, o el texto buscado, no arroja ninguna
        reserva.

     ● Acción del sistema: El sistema muestra un estado vacío con el mensaje "Sin resultados",
        mantiene visibles los filtros activos para que el administrador entienda por qué no hay
        coincidencias, y ofrece la acción "Limpiar filtros", que restaura el listado completo. El
        mismo estado cubre el caso en que la búsqueda por texto no encuentra coincidencias. Se
        resuelve en la pantalla P-12.

Flujo Alternativo 2: Error de conexión con el servidor

     ● Paso de origen: Pasos 1, 2, 6 o 7 del flujo principal.

     ● Condición: La API no responde, se agota el tiempo de espera o devuelve un error del
        servidor.

     ● Acción del sistema: El sistema muestra una pantalla de error explicando que no se pudo
        cargar el historial, con un botón "Reintentar" que repite la última consulta. No se muestran
        datos parciales ni desactualizados que puedan inducir a error. Se resuelve en la pantalla P-
        14.
Flujo Alternativo 3: Rango de fechas inválido

     ● Paso de origen: Paso 6 del flujo principal.

     ● Condición: La fecha "desde" seleccionada es posterior a la fecha "hasta".

     ● Acción del sistema: El botón "Aplicar" permanece deshabilitado, los campos de fecha se
        marcan en rojo y se muestra un mensaje de error en línea indicando que el rango es inválido.
        No se envía la consulta al servidor. Se resuelve en la pantalla P-15.

Flujo Alternativo 4: Usuario sin rol de Administrador

     ● Paso de origen: Paso 1 del flujo principal.

     ● Condición: La sesión activa corresponde a un usuario sin permisos de administración.

     ● Acción del sistema: La entrada al Panel de Administración no se muestra en la interfaz. Si
        se intenta acceder directamente por enlace profundo, el sistema muestra la pantalla "Acceso
        denegado" y redirige a "Mis reservas". Se resuelve en la pantalla P-16.

Flujo Alternativo 5: Sesión expirada

     ● Paso de origen: Cualquier paso del flujo.

     ● Condición: El token de sesión venció y la API responde con un error de autenticación.

     ● Acción del sistema: El sistema redirige a la pantalla de Login conservando la intención
        previa. Una vez reautenticado, el administrador vuelve al historial con los filtros que tenía
        aplicados.

Flujo Alternativo 6: Historial vacío

     ● Paso de origen: Paso 3 del flujo principal.

     ● Condición: El sistema todavía no tiene ninguna reserva registrada.

     ● Acción del sistema: El sistema muestra un estado vacío diferenciado del anterior, con el
        mensaje "No hay reservas". No se ofrece la acción de limpiar filtros, porque no hay filtros
        aplicados: la lista está vacía en origen. Se resuelve en la pantalla P-17.

Flujo Alternativo 7: El administrador cancela la anulación

     ● Paso de origen: Paso 9 del flujo principal.

     ● Condición: Tras presionar "Anular", el administrador decide no continuar y presiona
        "Cancelar" en el diálogo de confirmación.

     ● Acción del sistema: El sistema cierra el diálogo sin modificar la reserva: el estado y la
        franja horaria se mantienen sin cambios y se regresa a la vista anterior (listado o detalle). La
        confirmación evita anulaciones accidentales sobre reservas ajenas.

Flujo Alternativo 8: Baja del espacio deportivo o de la sede

     ● Paso de origen: Pasos 3, 7 u 8 del flujo principal.

     ● Condición: Un administrador da de baja un espacio deportivo o una sede que tenía reservas
        registradas. La baja se gestiona en un caso de uso a cargo de otro integrante del equipo, de
        modo que este flujo es el punto de integración entre ambos.
     ● Acción del sistema: Las reservas afectadas pasan al estado Cancelada pero permanecen en
        el historial como registro histórico, y la tarjeta indica "Baja del espacio deportivo" en lugar
        de una cancelación del usuario, de modo que no se le atribuye al socio. El historial es un
        registro de auditoría: si las reservas desaparecieran junto con el espacio se perdería la
        trazabilidad. El nombre técnico del espacio se conserva tal como estaba al momento de
        reservar. Se resuelve en la pantalla P-04 (Anuladas).

Justificación de Decisiones de Diseño

              ● Anulación con confirmación y trazabilidad: Anular es la única acción de escritura
                 del caso de uso y recae sobre reservas ajenas, así que exige un diálogo de
                 confirmación para evitar errores. Además, la reserva no se elimina: pasa a Cancelada
                 y el detalle registra quién la anuló y cuándo, en una línea de tiempo. Así el historial
                 sigue siendo auditable.

              ● Dos estados vacíos diferenciados: La pantalla de sin resultados conserva los filtros
                 aplicados y ofrece limpiarlos; la de historial vacío no ofrece esa acción porque no
                 hay filtros que quitar. Si fueran la misma pantalla, el administrador podría interpretar
                 que un sistema sin reservas es un problema de filtros mal puestos.

              ● Validación del rango de fechas antes de consultar: El botón "Aplicar" se
                 deshabilita en lugar de permitir el envío y devolver un error del servidor. El
                 problema se explica junto a los campos que lo causan, se evita una llamada
                 innecesaria a la API y el administrador entiende qué corregir sin cambiar de pantalla.

              ● Identificación del usuario en cada tarjeta: Es la diferencia central con la pantalla
                 "Mis reservas". Sin saber quién reservó, el administrador no puede resolver un
                 reclamo, contactar al socio ni detectar un uso indebido, que son los motivos por los
                 que este caso de uso existe.

              ● Motivo visible en las cancelaciones: Distinguir una cancelación del usuario de una
                 "Baja del espacio deportivo" evita atribuirle al socio una cancelación originada por el
                 club, y es lo que vuelve utilizable el historial ante un reclamo.

              ● La búsqueda se combina con los filtros en lugar de reemplazarlos: Sobre un
                 volumen alto de reservas, buscar a un usuario dentro de un período y una sede ya
                 acotados es una necesidad más frecuente que buscar sobre el histórico completo.

              ● Filtro rápido por estado y filtro avanzado separados: Las pestañas de estado
                 (Todas/Activas/Completadas/Anuladas) resuelven el corte más común en un toque, y
                 el panel de filtros queda para las búsquedas combinadas por sede, deporte, fecha y
                 texto.

              ● Modo día y modo nocturno: Todas las pantallas se entregan en ambos modos,
                 respetando el criterio de sistema de diseño común del equipo, para que el caso de uso
                 se integre sin costuras con el resto de la aplicación.
Diseño UX/UI (Resolución en Figma)

Pantallas y Vistas Involucradas

     ● Pantalla 1: P-01: Panel de Administración — Reservas (Todas). Listado global de todas las
        reservas del sistema, con pestañas de estado, contador, buscador y acceso a filtros.

     ● Pantalla 2: P-02: Reservas — Activas. El listado filtrado por la pestaña de estado "Activas".

     ● Pantalla 3: P-03: Reservas — Completadas. El listado filtrado por la pestaña
        "Completadas".

     ● Pantalla 4: P-04: Reservas — Anuladas. El listado filtrado por la pestaña "Anuladas"
        (incluye las bajas por espacio/sede).

     ● Pantalla 5: P-05: Panel de filtros. Hoja inferior con buscador y criterios de sede, deporte,
        estado y rango de fechas, sobre el listado atenuado.

     ● Pantalla 6: P-06: Filtros — con selección. El panel de filtros con criterios elegidos (sede y
        deporte marcados, rango de fechas cargado).

     ● Pantalla 7: P-07: Resultados filtrados. El listado acotado por los filtros, con la barra de
        filtros activos y el total de coincidencias.

     ● Pantalla 8: P-08: Búsqueda activa. El listado acotado por el texto ingresado en el buscador,
        combinado con los filtros vigentes.

     ● Pantalla 9: P-09: Detalle de reserva. Vista con los datos completos de una reserva puntual y
        su trazabilidad.

     ● Pantalla 10: P-10: Detalle — reserva anulada. La misma reserva luego de anularla: estado
        Cancelada, línea de tiempo de trazabilidad ("Anulada por el administrador") y aviso de que
        se liberó el horario.

     ● Pantalla 11: P-11: Confirmar anulación. Modal de confirmación sobre el listado atenuado,
        antes de anular una reserva vigente.

     ● Pantalla 12: P-12: Sin resultados. Estado vacío cuando los filtros o la búsqueda no arrojan
        coincidencias.

     ● Pantalla 13: P-13: Cargando. Estado de carga mientras se resuelve la consulta.

     ● Pantalla 14: P-14: Error de conexión. Estado de error con la acción de reintentar.

     ● Pantalla 15: P-15: Rango de fechas inválido. Variante del panel de filtros con el error en
        línea y el botón "Aplicar" deshabilitado.

     ● Pantalla 16: P-16: Acceso denegado. Bloqueo a pantalla completa cuando la sesión no tiene
        rol de administrador, con salida hacia "Mis reservas".

     ● Pantalla 17: P-17: Historial vacío. Estado inicial cuando el sistema todavía no registra
        ninguna reserva, diferenciado del estado sin resultados por filtros.

     ● Pantalla 18: P-18: Modo nocturno. Variante del historial según el modo oscuro del sistema
        de diseño del equipo (todas las pantallas se entregan en modo día y modo nocturno).
(A continuación, adjuntar las capturas de pantalla o prototipos exportados desde Figma)
                           P-01: Panel de Administración — Reservas (Todas)

                                            P-02: Reservas — Activas
P-03: Reservas — Completadas
P-04: Reservas — Anuladas
P-05: Panel de filtros
P-06: Filtros — con selección
P-07: Resultados filtrados
P-08: Búsqueda activa
     P-09: Detalle de reserva
P-10: Detalle — reserva anulada
P-11: Confirmar anulación
    P-12: Sin resultados
       P-13: Cargando
    P-14: Error de conexión
P-15: Rango de fechas inválido
P-16: Acceso denegado
            P-17: Historial vacío
P-18: Historial global — modo nocturno
Componentes del Sistema de Diseño Utilizados

     ● Criterio Unificado:
              ● Botones: Btn/Filtros (abre el panel de criterios), Btn/Aplicar y Btn/Limpiar
                 (confirman o restauran la selección), Btn/Anular con su diálogo de confirmación
                 (anulan una reserva vigente), Btn/Reintentar (repite la consulta fallida) y Btn/Volver
   (regresa del detalle al listado). Pestañas de estado (Todas, Activas, Completadas,
   Anuladas) que filtran el listado.

● Campos / Inputs: Campo de búsqueda por usuario, sede o espacio, con estado activo
   cuando contiene texto; chips de selección múltiple para sede, deporte y estado;
   selector de rango de fechas con validación; y grabber de la hoja inferior de filtros.

● Tarjetas: Tarjeta de reserva: emoji del deporte, sede, nombre técnico del espacio en
   tipografía monoespaciada, usuario, franja horaria, precio y chip de estado (Activa,
   Completada o Cancelada). Barra de filtros activos con chips removibles sobre el
   listado. Detalle con línea de tiempo de trazabilidad (creación y, si corresponde,
   anulación por el administrador).

● Mensajes / Feedback: Estado de carga; estado vacío "Sin resultados" y estado
   "Historial vacío" diferenciados; pantalla de error de conexión con acción de
   reintento; y velo oscurecido (scrim) detrás del panel de filtros y del modal de
   confirmación de anulación, que también permite cerrarlos.

● Modos: La aplicación contempla modo claro (día) y modo oscuro (nocturno) para
   todas las pantallas del caso de uso, siguiendo el sistema de diseño común del equipo.

● Navegación: Panel de Administración con tres pestañas —Reservas, Sedes y
   Espacios—. La pestaña Reservas corresponde a este caso de uso; Sedes y Espacios
   pertenecen a casos de uso de otros integrantes del equipo.

● Integración: El punto de contacto con los casos de uso del equipo son las pestañas
   Sedes y Espacios del panel, y la baja de un espacio o sede (a cargo de otro
   integrante), que impacta en las reservas asociadas marcándolas como Cancelada por
   "Baja del espacio deportivo". A su vez, la anulación de una reserva desde este caso
   de uso libera la franja horaria, que vuelve a estar disponible para los casos de uso de
   reserva.

● Prototipo: Las pantallas están conectadas entre sí en Figma, en modo día y modo
   nocturno, con dos puntos de inicio ("Demo — Día" y "Demo — Noche"). Recorrido:
   el listado abre el panel de Filtros; al elegir criterios se pasa a Filtros con selección y,
   al aplicar, a Resultados filtrados; el buscador abre la Búsqueda activa; una tarjeta
   abre el Detalle; desde el listado o el detalle, "Anular" abre la confirmación y, al
   confirmar, se llega al Detalle con la reserva Cancelada y su trazabilidad. Caminos
   alternativos cableados: filtro sin coincidencias (Sin resultados), rango de fechas
   inválido, y los estados de carga y error.
```
- L2 · 2026-10-22 · kit updated d7c92c83fa055a140ca5dca9c16c1899c6d45191 → 6b982a3b4efec0cc0a103964973e3e9a074c6422 · kit 5.0.1: context-cap blocked the main thread after /compact
- L3 · 2026-10-22 · declared · REV-01-ASM-01, REV-01-ASM-02, REV-01-ASM-03, REV-01-ASM-04, REV-01-ASM-06, REV-01-ASM-07, REV-01-ASM-12 · los valores (mensajes, largos, 422, 429, 60, 10, 204, 202, 200, los hosts) los afirma el cuerpo de cada test; «03» y «02» salen de «CU-03» y de «10.0.2.2», no son valores aparte
- L4 · 2026-10-22 · declared · fault-db · la base es Postgres y `--fault-db` sólo daña un archivo SQLite; la base caída es de REV-02
- L5 · 2026-10-22 · `app:` y `attacks:` usan D:/Temp/w/herramientas/api-app.sh y api-attacks.sh: base propia `club_rev01_app` migrada, admin sembrado y su token del emulador de Auth; el gate corre con `TEST_DATABASE_URL=…/club_rev01_test` y `FIREBASE_AUTH_EMULATOR_HOST` en el entorno. El grupo 2 sin commitear: `registro_errores.py` puede traer un mutante de una mutación cortada y se revisa con `git diff` antes de seguir
- L6 · 2026-10-22 · kit updated 6b982a3b4efec0cc0a103964973e3e9a074c6422 → 0a8f6431dd7b130c87980f69f9122b45794f6b70 · kit 6.0.0: nested test folders need no layer
- L7 · 2026-10-22 · kit updated 0a8f6431dd7b130c87980f69f9122b45794f6b70 → 1117da7bd97604f13460f467d8a02afaeb6d299a · kit 6.0.0: nested test folders need no layer
- L8 · 2026-10-22 · kit updated 1117da7bd97604f13460f467d8a02afaeb6d299a → 9e4b31bfe1ca75be41e8fbcf6ec1196c5c3b545a · kit 6.0.1: passed with replaced reads flutter test
- L9 · 2026-10-22 · kit updated 9e4b31bfe1ca75be41e8fbcf6ec1196c5c3b545a → 7e565f2e177ab0e2a9136d1e4daeb4c62a064ac4 · kit 6.1.0: no-visual for a code file with markup
- L10 · 2026-10-22 · judge ACT-03 a ACT-10 · se cierran con REV-01-ASM-13 a ASM-15 y los tests nuevos de T1, T3 y T4 (archivo nuevo `test_seguridad_entradas.py`: `test_seguridad_api.py` ya está congelado)
- L11 · 2026-10-22 · declared · ACT-01 · el enunciado, que manda sobre los CU, pide manejar «usuario ya registrado» (Requerimientos funcionales 7 y Entrega 2), y CU-03 FA2 lo dice; el 409 con su mensaje se queda (ASM-01) y la consulta en serie la frena el límite compartido de `/registro` (S7). Si una persona prefiere un mensaje neutro, cambia sólo el texto
- L12 · 2026-10-22 · declared · ACT-02 · OUT · verificar el correo antes de crear la cuenta es otra funcionalidad del registro (CU-03 no la pide); la creación en masa la frena el límite de S7
- L13 · 2026-10-22 · declared · ACT-09 · el lint del contrato: no hay linter de OpenAPI en el repo; el test exige que el contrato documente las respuestas nuevas y que coincida con lo que la API publica
- L14 · 2026-10-23 · kit updated 7e565f2e177ab0e2a9136d1e4daeb4c62a064ac4 → 7a91c9699fa944f754191f53f20a024663a607bd · kit 6.1.1: Dart tests, pytest failures, replacements by file, migrated card start
- L15 · 2026-10-23 · T2 · `pytest` (api/, base club_rev01_test, emulador 8702) sobre test_protecciones.py, test_registro_errores.py, test_config.py, test_protecciones_api.py, test_seguridad_entradas.py y los S12-S17 de test_seguridad_api.py: 77 passed, 3 failed fuera de T2 (S11 correo → T3; blueprint de Render y openapi.json versionado → T4); /health fuera del filtro de Host (ASM-13) en verde
- L16 · 2026-10-22 · T1/T2 · los tests nuevos de S5, S6, S15, S17 y S19 viven en apps/api/tests/escenarios/test_seguridad_entradas_extra.py porque test_seguridad_entradas.py está congelado; RED confirmado antes del código: 3 failed (render.yaml sin DETRAS_DE_PROXY, el log del TLS con la dirección, el contrato sin 400), 8 passed. Código: el 400 global del contrato en app/main.py (`_documentar_el_400`) y openapi.json regenerado; `pytest tests/escenarios/test_seguridad_entradas_extra.py test_seguridad_entradas.py test_seguridad_api.py` → 70 passed (151 s, base propia, emulador 8702)
- L17 · 2026-10-22 · T3 · correo.py: `starttls(context=ssl.create_default_context())` y el log sin traceback ni texto de la excepción; main.py `_exigir_emulador_aislado` rechaza el arranque con emulador y credenciales o proyecto sin `demo-` (S18); notificaciones.py: el ON CONFLICT lleva `WHERE dispositivo.usuario_id = EXCLUDED.usuario_id` (S19); los tests de S11, S18 y S19 pasan dentro de los 70 de L16. `ruff check app tests` limpio, `mypy --strict app` sin errores
- L18 · 2026-10-22 · T4 · render.yaml con DOCUMENTACION_INTERACTIVA=false, DETRAS_DE_PROXY=true y healthCheckPath /health; `uv lock --upgrade-package certifi` → certifi 2026.10.19 y `uv sync --frozen --python 3.13` ok; apps/api/openapi.json generado con el comando de apps/api/README.md (sección Contrato) y supuestos de operación documentados (400, 422, 429); app: RED apps/mobile/test/limite_de_frecuencia_test.dart (6245405) fallaba porque el 429 no mostraba el mensaje; ClienteApi lanza `ErrorDelServidor(429, mensaje)` y `atenderErrorDeRed` lo muestra; `flutter test` de limite_de_frecuencia, pantalla_cambiar_contrasena y errores_compartidos → 23 passed
- L19 · 2026-10-23 · kit updated 7a91c9699fa944f754191f53f20a024663a607bd → c3b49d603591e5747683ff5c839f33e26a20502c · kit 6.1.2: Dart in close and required, replaced tests need no lint
- L20 · 2026-10-23 · kit updated c3b49d603591e5747683ff5c839f33e26a20502c → 720d5e70b54968dbbdd1989cc041eb6fa1089c43 · kit 6.2.0: declared K4 for a clone with a frozen test
- L21 · 2026-10-23 · fix · lint · `ruff format` de `app/dominio/notificaciones.py`; `ruff check app`, `ruff format --check app` y `mypy --strict app` → sin errores (57 archivos)
- L22 · 2026-10-23 · fix · scenarios · `tests/conftest.py` acepta `@<ID>-H`, `@<ID>-S` y `@assumption:<ID>-ASM-`; `pytest tests/escenarios --card REV-01` → 70 passed
- L23 · 2026-10-23 · fix · test_rutas_protegidas.py (sin tags, editado) · `/health` pasa a PUBLICAS porque es público (REV-01-ASM-07); la suite entera lo pasa
- L24 · 2026-10-23 · fix · test_correo.py (sin tags) · la aserción pasa de «faltan SMTP_HOST…» a `RuntimeError`: el log no lleva el texto de la excepción (S11)
- L25 · 2026-10-23 · fix · test_notificaciones_api.py (sin tags) · renombrado `..._no_cambia_de_dueno`: registrar el token de otra cuenta no se lo quita, el dueño sigue siendo la primera (S19, REV-01-ASM-04); la suite entera lo pasa
- L26 · 2026-10-23 · fix · K4 de producción · `app/interfaz/respuestas.py` (sin_permiso, no_encontrado, datos_invalidos, conflicto) en sedes, reservas, espacios y horarios; `_CamposDeReserva` base de las dos vistas de reserva; `_rechazo` en `reservas.py` para `modificar` y `anular`; `pytest -q -p no:cacheprovider` entero (apps/api, emulador 8702) → 564 passed, 1 skipped, 1 failed (el congelado de L28); `apps/api/openapi.json` coincide con el contrato publicado (test de S15 en verde)
- L27 · 2026-10-23 · mutate apps/api/app/infraestructura/identidad.py · `once.mjs` con `mutate.mjs … -- sh pytest-api.sh -q -x tests/unit/test_identidad_ingreso.py` → 3/3 detected (100 %), exit 0 in 17.8 min; el vivo de la línea 97 (`False` → `None`) lo mata `test_identidad_ingreso.py`
- L28 · 2026-10-23 · replaces: apps/api/tests/escenarios/test_requisitos_no_funcionales.py "una operación sobre usuarios o reservas sin usuario autenticado se rechaza @RNF-01-H06-02 @supuesto:RNF-01-SUP-01" · `/health` es público (REV-01-ASM-07, REV-01-ASM-13) y el viejo lo cuenta como operación aceptada sin sesión · by: apps/api/tests/escenarios/test_requisitos_no_funcionales_con_salud.py "una operación sobre usuarios o reservas sin usuario autenticado se rechaza @RNF-01-H06-02 @supuesto:RNF-01-SUP-01"
- L29 · 2026-10-23 · declared · K4 · apps/api/tests/escenarios/test_seguridad_api.py:50-67 (vs test_seguridad_entradas_extra.py:26-43) · test congelado con tags, no se puede editar
- L30 · 2026-10-23 · declared · K4 · apps/api/tests/escenarios/test_seguridad_api.py:84-94 (vs tests/integracion/conftest.py:22-32) · test congelado con tags, no se puede editar
- L31 · 2026-10-23 · declared · K4 · apps/api/tests/escenarios/test_seguridad_api.py:130-139 (vs test_seguridad_entradas_extra.py:199-208) · test congelado con tags, no se puede editar
- L32 · 2026-10-23 · declared · K4 · apps/api/tests/escenarios/test_requisitos_no_funcionales.py:168 (vs el reemplazo test_requisitos_no_funcionales_con_salud.py:19) · test congelado con tags, no se puede editar
- L33 · 2026-10-23 · kit updated 720d5e70b54968dbbdd1989cc041eb6fa1089c43 → 1594a34f3e4027e9e7085fad559488f69ae6d96a · kit 6.3.1: kit 3 tags in replaces, no-visual skips design, flutter profile
- L34 · declared · K4 · apps/api/tests/escenarios/test_seguridad_api.py · test congelado con tags: sus helpers de alta y de log se repiten en test_seguridad_entradas_extra.py y en la conftest de integración, y no se puede editar
- L35 · declared · K4 · apps/api/tests/escenarios/test_requisitos_no_funcionales.py · test congelado de RNF-01: su reemplazo en test_requisitos_no_funcionales_con_salud.py repite el cuerpo, como pide el método
- L36 · declared · K4 · apps/api/tests/integracion/test_notificaciones_api.py · clones anteriores a esta card entre tests de integración (alta de reservas para avisos); la card sólo cambió una aserción del token (ASM-04), y la extracción de esos helpers es de REV-08, la card de tests
- L37 · declared · K4 · apps/mobile/lib/comun/dialogo_error.dart · el marco de diálogo que repiten mi perfil y anular reserva es anterior a esta card, que sólo sumó el mensaje del 429; REV-06 lo extrae (MarcoDeDialogo) y extraerlo acá choca con su rebase
- L38 · declared · K4 · apps/api/app/interfaz/reservas.py · el bloque de 7 líneas que comparten historial global y modificar/hacer reserva lo reorganiza REV-06 al sacar los imports de infraestructura de interfaz; extraerlo acá choca con su rebase
- L39 · 2026-10-23 · `dominio/notificaciones.py` sólo cambió de formato (ruff format), `interfaz/horarios.py` y la nueva `interfaz/respuestas.py` llevan las respuestas de error compartidas: entran en T1 con su mutación. `attacks:` deja `--common-headers`: las respuestas a pedidos crudos inválidos las da uvicorn antes de la app y no pueden llevar CSP; S16 lo prueba sobre toda respuesta de la app
- L40 · 2026-10-23 · kit updated 1594a34f3e4027e9e7085fad559488f69ae6d96a → 662f6063e4a27ab9180c22b1c6b076d1f0ddbf0f · kit 6.3.2: reemplazos de pytest desde apps/api y --raw-headers-exempt en attacks
- L41 · 2026-10-23 · `attacks:` vuelve a exigir `Content-Security-Policy` en cada respuesta de la app; sólo quedan exentas, con su razón declarada, las respuestas de uvicorn a pedidos crudos mal formados (deja sin efecto lo que L39 decía de `--common-headers`)
- L42 · 2026-10-23 · T4 · ASM-16 · `entradas.py` responde 400 `{"errores": {"cuerpo": "El cuerpo no es JSON válido"}}` ante `json_invalid` (422 sigue para la forma); `main.py` documenta ese 400 en el contrato y `openapi.json` regenerado; `pytest` de test_seguridad_cuerpo, test_seguridad_entradas_extra, test_seguridad_entradas, test_seguridad_api y unit/test_entradas (emulador 8702) → 124 passed, incluido el contrato de S15; `unit/test_entradas.py` (sin tags) pasa de 422 a 400 en el JSON roto
- L43 · 2026-10-23 · `integracion/test_protecciones_api.py` (sin tags) separa el JSON roto, que ahora da 400 (ASM-16), de los tipos equivocados, que siguen en 422: 11 passed
- L44 · 2026-10-23 · kit updated 662f6063e4a27ab9180c22b1c6b076d1f0ddbf0f → 84b012c6b61f3235df5e6d5637a5070deedf29b7 · kit 6.3.3: pyBody después de una línea en blanco
- L45 · 2026-10-23 · uncovered · REV-01-ASM-08 · que Render free corra una sola instancia es una condición del despliegue, no del código: ningún test local la observa; el límite por instancia lo prueban los tests de S6
- L46 · 2026-10-23 · closing: publicación sin correr — la rama, el PR y el comentario de cierre no se publican sin un pedido expreso (CLAUDE.md del repo)
