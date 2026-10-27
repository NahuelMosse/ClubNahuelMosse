# MAIL-01 · el correo de recuperación sale por la API HTTP de Brevo

status: proposed
cap: 1 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «el servicio de email funciona? pedi recuperar contrase;a a mi email con el + para hacer un submail y no me llega» · log de Render 14:25:42: «no se pudo enviar el correo «Creá una contraseña nueva»: OSError», diez segundos después del 202"
  - "repo · apps/api/app/modules/recuperacion/correo.py (`_por_smtp`, `enviar`), apps/api/app/shared/config.py (`correo_modo`), render.yaml"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"
  - "la documentación de Render sobre puertos SMTP bloqueados en el plan gratuito: no la leí en esta sesión; el OSError a los 10 s (el timeout de la conexión) es consistente con ese bloqueo"

## Specs

- S1 · "el servicio de email funciona? [...] no me llega" · acceptance: con `CORREO_MODO=brevo`, `enviar` manda el correo por `POST https://api.brevo.com/v3/smtp/email` con la cabecera `api-key` (`BREVO_API_KEY`), remitente `CORREO_REMITENTE`, destinatario, asunto y cuerpo de texto del mensaje; no abre ninguna conexión SMTP
- S2 · "no me llega" · acceptance: si Brevo responde un error o no responde en 10 s, el envío queda en el log como hoy («no se pudo enviar el correo «<asunto>»: <tipo>», sin la dirección ni la clave) y la respuesta al pedido sigue siendo 202
- MAIL-01-ASM-01 · los modos `smtp` y `buzon` quedan como están; `brevo` es un tercer valor de `CORREO_MODO` y `render.yaml` pasa a `brevo` con `BREVO_API_KEY` como secreto cargado a mano (`sync: false`) · S1
- MAIL-01-ASM-02 · el pedido HTTP usa la biblioteca estándar (`urllib.request`), sin dependencias nuevas · S1

## Tasks

- T1 · S1,S2,MAIL-01-ASM-01,MAIL-01-ASM-02 · apps/api/app/modules/recuperacion/correo.py (data), apps/api/app/shared/config.py (data), render.yaml · tests: apps/api/tests/unit/test_correo_por_brevo.py "con CORREO_MODO=brevo el correo sale por la API de Brevo con su clave, remitente, destinatario, asunto y cuerpo @MAIL-01-S1 @assumption:MAIL-01-ASM-02"; apps/api/tests/unit/test_correo_por_brevo.py "si Brevo falla o no responde el error queda en el log sin la dirección y el pedido sigue en 202 @MAIL-01-S2"; apps/api/tests/unit/test_correo_por_brevo.py "smtp y buzon siguen igual y render.yaml usa brevo con la clave como secreto @assumption:MAIL-01-ASM-01"
  reuses: apps/api/app/modules/recuperacion/correo.py `enviar` (elige el modo y atrapa el error), `correo_log`; apps/api/app/shared/config.py `Settings`

## Changes to existing behavior

- en Render el correo de recuperación sale por Brevo y no por SMTP; con `CORREO_MODO=smtp` o `buzon` nada cambia

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_correo_por_brevo.py tests/unit/test_recuperacion_caso_de_uso.py tests/integracion/test_recuperacion_api.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests/unit/test_correo_por_brevo.py
app: sh D:/Temp/w/herramientas/arq01-app.sh mail01_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh mail01_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
no-docs: un modo más de envío de correo; el contrato y el modelo de datos no cambian
```

## Log

- L1 · el servicio de email funciona? pedi recuperar contrase;a a mi email con el + para hacer un submail y no me llega
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
- L3 · 2026-10-27 · declared · attacks · la card no cambia rutas ni cuerpos: sólo cómo sale el correo después del 202
