# MAIL-02 · el correo de recuperación tiene el diseño de la app

status: proposed
cap: 1 h
sources:
  - "pedido (texto) · mensaje del usuario en la sesión (2026-10-27): «el email de recuperacion de contrase;a es horrible, se puede mejorar?»"
  - "repo · apps/api/app/modules/recuperacion/casos_de_uso.py (`pedir_enlace` arma el `Mensaje` en texto plano), reglas.py (`Mensaje`), correo.py (`_por_brevo` manda `textContent`, `_por_smtp` texto); apps/mobile/lib/tema/tokens.dart (`bgBase` #0A0A0B, `bgSurface` #141416, `accentBase` #D4FF3D, `textSecondary` #A1A1AA)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "el email de recuperacion de contrase;a es horrible" · acceptance: el correo de recuperación sale también en HTML: fondo `#0A0A0B`, tarjeta `#141416`, la marca «CLUB NAHUEL MOSSE» en `#D4FF3D`, el saludo con el nombre, un botón «Crear contraseña nueva» en `#D4FF3D` con texto `#0A0A0B` que lleva al mismo enlace de hoy, y debajo el vencimiento («vence en 30 minutos y sirve una sola vez») y el aviso de que si no lo pidió lo ignore; estilos en línea y tablas, sin imágenes externas ni scripts
- S2 · "se puede mejorar?" · acceptance: el mismo correo sigue llevando la versión de texto de hoy, y el HTML repite el enlace como texto para quien no puede tocar el botón
- MAIL-02-ASM-01 · por Brevo el HTML va en `htmlContent` junto con `textContent`; por SMTP va como alternativa HTML del mismo mensaje; el buzón de desarrollo sigue guardando sólo el texto · S1
- MAIL-02-ASM-02 · el nombre de la persona se escapa en el HTML: un nombre con `<` o `&` no rompe ni inyecta marcado · S1

## Tasks

- T1 · S1,S2,MAIL-02-ASM-01,MAIL-02-ASM-02 · apps/api/app/modules/recuperacion/reglas.py (rule), apps/api/app/modules/recuperacion/casos_de_uso.py (rule), apps/api/app/modules/recuperacion/correo.py (data) · tests: apps/api/tests/unit/test_correo_con_diseno.py "el correo de recuperación sale en HTML con la marca, el saludo, el botón al enlace y el vencimiento @MAIL-02-S1"; apps/api/tests/unit/test_correo_con_diseno.py "el correo sigue llevando el texto de hoy y el HTML repite el enlace @MAIL-02-S2"; apps/api/tests/unit/test_correo_con_diseno.py "Brevo recibe htmlContent y textContent, SMTP la alternativa HTML y el buzón sólo el texto @assumption:MAIL-02-ASM-01"; apps/api/tests/unit/test_correo_con_diseno.py "un nombre con marcado sale escapado en el HTML @assumption:MAIL-02-ASM-02"
  reuses: apps/api/app/modules/recuperacion/reglas.py `Mensaje` (suma `html`); apps/api/app/modules/recuperacion/correo.py `_por_brevo`, `_por_smtp`, `_al_buzon`

## Changes to existing behavior

- el correo de recuperación suma una versión HTML con el diseño de la app; el texto, el asunto y el enlace no cambian

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_correo_con_diseno.py tests/unit/test_correo_brevo.py tests/unit/test_recuperacion_caso_de_uso.py tests/integracion/test_recuperacion_api.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests/unit/test_correo_con_diseno.py
app: sh D:/Temp/w/herramientas/arq01-app.sh mail02_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh mail02_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
no-docs: el diseño de un correo; el contrato y el modelo de datos no cambian
```

## Log

- L1 · el email de recuperacion de contrase;a es horrible, se puede mejorar?
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
