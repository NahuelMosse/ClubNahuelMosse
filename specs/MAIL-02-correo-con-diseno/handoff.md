# Handoff MAIL-02

## Hecho (commit RED c3d3bcc + commit WIP)
- Tests: apps/api/tests/unit/test_correos_con_diseno.py (commit c3d3bcc).
- Código escrito: shared/plantilla_correo.py (`html_de_correo(titulo, parrafos, boton, pie, detalles)`), `Mensaje.html`, Brevo/SMTP con html opcional, `pedir_enlace` con HTML, recuperacion/__init__ exporta `enviar` y `Mensaje`, reservas/correo.py (`correo_de_reserva`), reservas/rutas.py (`hacer_reserva` con `despues: BackgroundTasks` y `add_task(enviar, ...)`), notificaciones: `Recordatorio.correo/nombre`, `vencidos` con `u.correo, u.nombre AS nombre_usuario`, `correo_recordatorio` en reglas, `_avisar_por_correo` en casos_de_uso, `tipo_corto` exportado en __init__.

## Bloqueo (decisión estructural que la card no vio)
`notificaciones -> recuperacion` y `reservas -> recuperacion` cierran un ciclo: recuperacion -> usuarios -> reservas -> notificaciones. Falla el import (ImportError circular) y `test_una_funcionalidad_importa_otra_solo_por_su_init_y_no_hay_ciclos`.
Salida propuesta: mover `Mensaje` y el envío (`enviar`, `_al_buzon`, `_por_smtp`, `_por_brevo`, `_ENVIADORES`) a `apps/api/app/shared/correo.py`; `recuperacion/reglas.py` y `recuperacion/correo.py` los re-exportan (los tests viejos usan `correo.enviar`, `correo._por_brevo`, `Mensaje` desde recuperacion.reglas); notificaciones y reservas importan `enviar`/`Mensaje` de `app.shared.correo`, y se sacan los imports a `app.modules.recuperacion` de notificaciones/reglas.py, notificaciones/casos_de_uso.py, reservas/correo.py, reservas/rutas.py y el `enviar`/`Mensaje` de recuperacion/__init__.py.
Ojo: el test del buzón (RED, no editable) parchea `correo.motor` en `recuperacion.correo`; con el envío en shared hay que parchear `app.shared.correo.motor` -> test de reemplazo en archivo nuevo con el mismo tag `@assumption:MAIL-02-ASM-01` + línea `replaces:` en el Log. Alternativa: dejar `_al_buzon` y `motor` en recuperacion/correo.py.

## Falta
- Resolver lo anterior, correr: `export UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv"; sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_correos_con_diseno.py tests/unit/test_correo.py tests/unit/test_correo_brevo.py tests/unit/test_recordatorios.py tests/unit/test_arquitectura_funcionalidades.py`
- Fakes de `vencidos` en tests existentes usan `Recordatorio` posicional: los campos nuevos tienen defecto, deberían andar.
- Gate completo (`node .claude/tools/verify.mjs`), formato (ruff), Log en card.md (una línea por tarea, con Edit), `reuses:`/`new:` en T1..T3 de la card.
- Revisar el test de S2 (usa MonkeyPatch inline; funciona pero es feo).
