# MAIL-02 · los correos de recuperación, confirmación de reserva y recordatorio tienen el diseño de la app

status: proposed
cap: 2 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «el email de recuperacion de contrase;a es horrible, se puede mejorar?» · «y ademas al reservar una cancha no se puede enviar un email tambien para confirmar la reserva, los dos emails que esten lindos. Tambien quiero un email para cuando falta 1h para la reserva, asi llega notificacion mas email» · «los tres email los quiero lindo y aprovechando el dise;o de la app»"
  - "repo · apps/api/app/modules/recuperacion/casos_de_uso.py (`pedir_enlace` arma el `Mensaje` en texto plano), reglas.py (`Mensaje`), correo.py (`enviar`, `_por_brevo`, `_por_smtp`, `_al_buzon`); apps/api/app/modules/reservas/rutas.py (`hacer_reserva`, `BackgroundTasks`); apps/api/app/modules/notificaciones/casos_de_uso.py (`enviar_recordatorios`), reglas.py (`Recordatorio`); apps/api/app/modules/sesion/perfil.py (`Perfil.correo`, `Perfil.nombre`); apps/mobile/lib/tema/tokens.dart (`bgBase` #0A0A0B, `bgSurface` #141416, `accentBase` #D4FF3D, `textSecondary` #A1A1AA)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "el email de recuperacion de contrase;a es horrible, se puede mejorar?" · acceptance: el correo de recuperación sale también en HTML con la plantilla de la app (ver MAIL-02-ASM-03), el saludo con el nombre, un botón «Crear contraseña nueva» al mismo enlace de hoy, el vencimiento («vence en 30 minutos y sirve una sola vez») y el aviso de que si no lo pidió lo ignore
- S2 · "se puede mejorar?" · acceptance: cada correo sigue llevando su versión de texto, y el HTML repite como texto todo enlace que tenga un botón
- S3 · "al reservar una cancha no se puede enviar un email tambien para confirmar la reserva" · acceptance: cuando una persona hace una reserva (`POST /reservas` responde 201), le llega un correo «Tu reserva está confirmada» con la plantilla de la app: deporte y tipo de cancha, sede, día, horario de inicio a fin y total; el correo sale después de responder y no demora ni cambia la respuesta
- S4 · "quiero un email para cuando falta 1h para la reserva, asi llega notificacion mas email" · acceptance: cuando el barrido registra el recordatorio de una hora antes, además del push sale un correo «Tu reserva es en 1 hora» con la plantilla de la app, deporte, sede y horario; sale una sola vez por reserva, igual que el push
- MAIL-02-ASM-01 · `Mensaje.html` es opcional (por defecto `None`): por Brevo va en `htmlContent` junto con `textContent` sólo si está; por SMTP va como alternativa HTML sólo si está; el buzón de desarrollo guarda sólo el texto; los `Mensaje` de hoy sin `html` siguen andando · S1
- MAIL-02-ASM-02 · todo dato de la persona o de la reserva (nombre, sede, deporte) se escapa en el HTML: un `<` o `&` no rompe ni inyecta marcado · S1
- MAIL-02-ASM-03 · «aprovechando el diseño de la app» es la paleta oscura de la app: fondo `#0A0A0B`, tarjeta `#141416` con borde redondeado, la marca «CLUB NAHUEL MOSSE» en `#D4FF3D`, títulos blancos, texto secundario `#A1A1AA`, botones `#D4FF3D` con texto `#0A0A0B`; estilos en línea y tablas (lo que los clientes de correo respetan), sin imágenes externas ni scripts; una sola plantilla para los tres correos · S1
- MAIL-02-ASM-04 · si un correo de reserva o de recordatorio no sale, queda en el log como el de recuperación (asunto y tipo de error, sin la dirección) y no afecta la reserva ni el push · S3
- MAIL-02-ASM-05 · el correo de confirmación sale sólo al hacer una reserva nueva; modificar, cancelar o anular no mandan correo (siguen con su push como hoy) · S3

## Tasks

- T1 · S1,S2,MAIL-02-ASM-01,MAIL-02-ASM-02,MAIL-02-ASM-03 · apps/api/app/shared/plantilla_correo.py (rule), apps/api/app/modules/recuperacion/reglas.py (rule), apps/api/app/modules/recuperacion/casos_de_uso.py (rule), apps/api/app/shared/correo.py (data), apps/api/app/shared/mensaje.py (rule), apps/api/app/modules/recuperacion/__init__.py (presentation), apps/api/app/modules/recuperacion/rutas.py (presentation; `enviar` viene de shared), apps/api/app/modules/notificaciones/__init__.py (presentation; exporta `tipo_corto`), apps/api/pyproject.toml (el test nuevo en el per-file-ignores de E501) · tests: apps/api/tests/unit/test_correos_con_diseno.py "el correo de recuperación sale en HTML con la plantilla, el saludo, el botón al enlace y el vencimiento @MAIL-02-S1 @assumption:MAIL-02-ASM-03"; apps/api/tests/unit/test_correos_con_diseno.py "cada correo sigue llevando su texto y el HTML repite el enlace del botón @MAIL-02-S2"; apps/api/tests/unit/test_correos_con_diseno.py "Brevo recibe htmlContent sólo si hay HTML, SMTP la alternativa y el buzón sólo el texto @assumption:MAIL-02-ASM-01"; apps/api/tests/unit/test_correos_con_diseno.py "un nombre o una sede con marcado salen escapados en el HTML @assumption:MAIL-02-ASM-02"; apps/api/tests/unit/test_plantilla_correo.py "un correo sin detalles no muestra None ni una tabla de detalles vacía @MAIL-02-S1"
  reuses: `Mensaje` (suma `html` opcional) y `enviar`, `_por_brevo`, `_por_smtp`, `_al_buzon`, que pasan de recuperacion a apps/api/app/shared/correo.py para que reservas y notificaciones los usen sin ciclo; recuperacion los re-exporta
  new: apps/api/app/shared/plantilla_correo.py `html_de_correo`: ninguna plantilla de correo existía
- T2 · S3,MAIL-02-ASM-04,MAIL-02-ASM-05 · apps/api/app/modules/reservas/rutas.py (presentation), apps/api/app/modules/reservas/correo.py (rule) · tests: apps/api/tests/unit/test_correos_con_diseno.py "al hacer una reserva sale el correo de confirmación con deporte, sede, día, horario y total @MAIL-02-S3"; apps/api/tests/unit/test_correos_con_diseno.py "si el correo de confirmación falla la reserva responde igual y queda en el log sin la dirección @assumption:MAIL-02-ASM-04"; apps/api/tests/unit/test_correos_con_diseno.py "modificar, cancelar o anular no mandan correo @assumption:MAIL-02-ASM-05"
  reuses: apps/api/app/shared/correo.py `enviar`, `Mensaje`; apps/api/app/shared/plantilla_correo.py `html_de_correo`; `Perfil.correo`, `Perfil.nombre`
- T3 · S4,MAIL-02-ASM-04 · apps/api/app/modules/notificaciones/casos_de_uso.py (rule), apps/api/app/modules/notificaciones/reglas.py (rule), apps/api/app/modules/notificaciones/repositorio.py (data) · tests: apps/api/tests/unit/test_correos_con_diseno.py "el recordatorio de una hora antes sale por push y por correo, una sola vez @MAIL-02-S4"; apps/api/tests/unit/test_correos_con_diseno.py "si el correo del recordatorio falla el push sale igual @assumption:MAIL-02-ASM-04"
  reuses: apps/api/app/modules/notificaciones/casos_de_uso.py `enviar_recordatorios`, `entregar`; `Recordatorio` (suma correo y nombre de quien reservó); apps/api/app/shared/correo.py `enviar`, `Mensaje`

## Changes to existing behavior

- el correo de recuperación suma una versión HTML con el diseño de la app; hacer una reserva manda un correo de confirmación; el recordatorio de una hora antes sale también por correo

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_correos_con_diseno.py tests/unit/test_plantilla_correo.py tests/unit/test_correo.py tests/unit/test_correo_brevo.py tests/unit/test_recuperacion_caso_de_uso.py tests/unit/test_recordatorios.py tests/integracion/test_recuperacion_api.py tests/integracion/test_reservas_api.py tests/integracion/test_notificaciones_api.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests/unit/test_correos_con_diseno.py
app: sh D:/Temp/w/herramientas/arq01-app.sh mail02_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh mail02_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
no-docs: el diseño y el envío de tres correos; el contrato y el modelo de datos no cambian
no-visual: la card no toca ninguna pantalla de la app; la plantilla es HTML de correo, que se verifica en el test de S1
```

## Log

- L1 · el email de recuperacion de contrase;a es horrible, se puede mejorar?
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
- L3 · 2026-10-27 · el usuario suma: y ademas al reservar una cancha no se puede enviar un email tambien para confirmar la reserva, los dos emails que esten lindos. Tambien quiero un email para cuando falta 1h para la reserva, asi llega notificacion mas email · los tres email los quiero lindo y aprovechando el dise;o de la app · S3, S4, MAIL-02-ASM-03
- L4 · 2026-10-27 · el juez del plan pide declarar el diseño elegido (ACT-01: MAIL-02-ASM-03, con la frase de L3) y que `html` sea opcional para los `Mensaje` de hoy (ACT-02: MAIL-02-ASM-01; test_correo.py entra en la suite)
- L5 · 2026-10-27 · declared · S2 · «cada correo» son los tres de S1, S3 y S4; el test de S2 recorre los tres en el mismo caso
- L6 · 2026-10-27 · declared · MAIL-02-ASM-03 · los colores y la marca de la plantilla los verifica el test de S1 sobre el HTML; el título no repite los valores para no pasar el largo de línea
- L7 · 2026-10-27 · T1 · `Mensaje` y el envío (`enviar`, `_al_buzon`, `_por_smtp`, `_por_brevo`) pasan a apps/api/app/shared/mensaje.py y shared/correo.py para cortar el ciclo recuperacion -> usuarios -> reservas -> notificaciones; recuperacion exporta `correo` (el módulo de shared), `enviar` y `Mensaje`, así los tests y los imports de hoy siguen andando; los tests del buzón, SMTP y Brevo no cambian: parchean el mismo módulo · ruff y mypy --strict de app limpios; suite de unit: 50 passed
- L8 · 2026-10-27 · T2 · `hacer_reserva` encola `enviar(correo_de_reserva(...))` en BackgroundTasks · tests de S3, ASM-04 y ASM-05 en test_correos_con_diseno.py pasan
- L9 · 2026-10-27 · T3 · `enviar_recordatorios` manda el correo junto al push, tras el registro único · tests de S4 y ASM-04 pasan
- L10 · 2026-10-27 · declared · lint · tests/unit/test_correos_con_diseno.py queda en el per-file-ignores de E501 de pyproject.toml, como los otros tests congelados con títulos largos
- L11 · 2026-10-27 · declared · I-tokens · apps/api/app/shared/plantilla_correo.py · es HTML de correo: Gmail y los demás clientes sólo respetan estilos en línea, así que los colores y medidas de la paleta de la app van escritos ahí (MAIL-02-ASM-03); no hay tokens de pantalla que importar desde la API
- L12 · 2026-10-27 · declared · I-tokens · apps/api/tests/unit/test_correos_con_diseno.py · el test verifica esos mismos colores en el HTML
- L13 · 2026-10-27 · declared · K4 · apps/api/tests/unit/test_correos_con_diseno.py · el montaje del correo de reserva y del recordatorio se repite en los tests de S3, S4 y ASM-04, que están congelados desde el RED
