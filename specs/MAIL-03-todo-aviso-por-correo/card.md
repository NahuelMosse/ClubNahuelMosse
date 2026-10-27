# MAIL-03 · cada notificación sale también por correo, con el diseño de la app

status: proposed
cap: 1 h
sources:
  - "pedido (texto) · mensaje del usuario en la sesión (2026-10-27): «dijo, todo lo que tenga notificacion, puede tener su email tambien?»"
  - "repo · apps/api/app/modules/notificaciones/casos_de_uso.py (`entregar` manda cada aviso registrado al push; `despachar_pendientes` toma los de cancelación; `enviar_recordatorios` y `_avisar_por_correo` ya mandan el correo del recordatorio, MAIL-02), apps/api/app/shared/correo.py (`enviar`), apps/api/app/shared/plantilla_correo.py (`html_de_correo`)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "todo lo que tenga notificacion, puede tener su email tambien?" · acceptance: cada notificación que la API registra para una persona sale también por correo a su dirección, una sola vez, con la plantilla de la app: el mismo título y cuerpo del aviso y un botón «Abrir la app»; hoy son el recordatorio de una hora antes, la cancelación que hace el club o un administrador (también la agrupada por baja de sede o espacio) y la confirmación de la cancelación que hizo la persona
- S2 · "puede tener su email tambien?" · acceptance: el correo sale aunque la persona no tenga el push habilitado ni un teléfono registrado; si el correo falla queda en el log (tipo de error, sin la dirección) y el push y el estado del aviso no cambian
- MAIL-03-ASM-01 · el recordatorio no manda dos correos: el que ya mandaba pasa a salir por el mismo camino que los demás · S1
- MAIL-03-ASM-02 · el botón para abrir la app lleva al enlace público de la app (`URL_PUBLICA`), el mismo que usa el correo de recuperación; si el enlace no está configurado, el correo sale sin botón · S1
- MAIL-03-ASM-03 · el correo de una notificación que no se puede registrar (porque ya existía, por el índice único) no sale: correo y aviso van juntos · S1
- MAIL-03-ASM-04 · una cuenta dada de baja no recibe el correo del aviso, igual que la recuperación sólo escribe a cuentas activas · S1

## Tasks

- T1 · S1,S2,MAIL-03-ASM-01,MAIL-03-ASM-02,MAIL-03-ASM-03 · apps/api/app/modules/notificaciones/casos_de_uso.py (rule), apps/api/app/modules/notificaciones/correo.py (rule), apps/api/app/modules/notificaciones/repositorio.py (data), apps/api/app/modules/notificaciones/almacen.py (rule), apps/api/app/modules/notificaciones/reglas.py (rule) · tests: apps/api/tests/unit/test_aviso_por_correo.py "cada notificación registrada sale también por correo con su título, cuerpo y la plantilla de la app @MAIL-03-S1 @assumption:MAIL-03-ASM-02"; apps/api/tests/unit/test_aviso_por_correo.py "el correo sale aunque no haya push y si falla el aviso queda como estaba @MAIL-03-S2"; apps/api/tests/unit/test_aviso_por_correo.py "el recordatorio manda un solo correo @assumption:MAIL-03-ASM-01"; apps/api/tests/unit/test_aviso_por_correo.py "un aviso que no se registra no manda correo @assumption:MAIL-03-ASM-03"; apps/api/tests/unit/test_aviso_por_correo_por_tipo.py "el recordatorio, la cancelación del club, la agrupada y la propia salen cada una por correo @MAIL-03-S1"; apps/api/tests/integracion/test_destinatario_del_aviso.py "el destinatario de un aviso sale de la base con su correo y nombre, y una cuenta dada de baja no tiene destinatario @MAIL-03-S1 @assumption:MAIL-03-ASM-04"; apps/api/tests/unit/test_aviso_sin_correo.py "un aviso a una persona sin correo cargado no manda correo y sale igual por push @MAIL-03-S2"
  reuses: apps/api/app/modules/notificaciones/casos_de_uso.py `entregar` (el punto por el que pasa cada aviso), `_avisar_por_correo`; apps/api/app/shared/correo.py `enviar`; apps/api/app/shared/plantilla_correo.py `html_de_correo`

## Changes to existing behavior

- las cancelaciones (del club, de un administrador o de la persona) también llegan por correo; el recordatorio sigue mandando un solo correo

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_aviso_por_correo.py tests/unit/test_aviso_sin_correo.py tests/unit/test_aviso_por_correo_por_tipo.py tests/integracion/test_destinatario_del_aviso.py tests/unit/test_correos_con_diseno.py tests/unit/test_recordatorios.py tests/unit/test_despacho_de_confirmaciones.py tests/unit/test_cola_de_avisos.py tests/integracion/test_notificaciones_api.py tests/escenarios/test_cancelacion_forzosa.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests/unit/test_aviso_por_correo.py apps/api/tests/unit/test_aviso_sin_correo.py apps/api/tests/unit/test_aviso_por_correo_por_tipo.py apps/api/tests/integracion/test_destinatario_del_aviso.py
app: sh D:/Temp/w/herramientas/arq01-app.sh mail03_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh mail03_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
refactor-tests: apps/api/tests/unit/test_aviso_por_correo.py · dos títulos pasaban de 100 columnas (lint) y el canal falso duplicaba el de test_correos_con_diseno (K4); sólo cambian nombres y el falso, no lo que afirman
no-docs: un canal más para los avisos; el contrato y el modelo de datos no cambian
no-visual: la card no toca ninguna pantalla; el HTML del correo sale de la plantilla de MAIL-02
```

## Log

- L1 · dijo, todo lo que tenga notificacion, puede tener su email tambien?
- L2 · 2026-10-27 · declared · fault-db · la card no cambia cómo se conecta ni el esquema; lee el correo de la persona con el SQL del repositorio
- L3 · 2026-10-27 · T1 · verify.mjs: suite, lint, specs, attacks, layers, shape, overdesign, migrations, boundaries passed; required pendiente: mutation de casos_de_uso.py y correo.py, judge.md (riesgo escalado a high por almacen.py y reglas.py, ya nombrados en Tasks). `entregar` manda el correo antes del push (nuevo `destinatario` opcional: el recordatorio lo pasa y no consulta); `correo_de_aviso` en correo.py
- L4 · 2026-10-27 · replaces-in-place: test_aviso_por_correo.py · títulos de más de 100 columnas y canal falso duplicado (K4) · declarado como refactor-tests en ## Gate
- L5 · 2026-10-27 · T1 · judge: test_aviso_por_correo_por_tipo.py (recordatorio, cancelación del club, agrupada y propia, un correo cada una) y test_destinatario_del_aviso.py (destinatario desde la base; cuenta dada de baja sin destinatario, MAIL-03-ASM-04) agregados a la suite y al lint del Gate; `NotificacionesSql.destinatario` filtra `activo`
- L6 · 2026-10-27 · replaces-in-place: test_aviso_por_correo_por_tipo.py · el repositorio y el canal falsos duplicaban los de test_aviso_por_correo.py (K4); ahora los reutiliza, mismo afirmado
- L7 · 2026-10-27 · T1 · la mutación de casos_de_uso.py dejó vivo «or» → «and» en el chequeo del destinatario: lo cubre test_aviso_sin_correo.py; «None» → «0» en el valor por defecto de `destinatario` es equivalente (equivalents.md)
- L8 · 2026-10-27 · declared · mutate · apps/api/app/modules/notificaciones/almacen.py · es un Protocol: mutate.mjs no encuentra operadores que aplicar
- L9 · 2026-10-27 · declared · mutate · apps/api/app/modules/notificaciones/reglas.py · la card sólo suma el dataclass `Destinatario`: mutate.mjs no encuentra operadores que aplicar
