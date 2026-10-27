# NOT-03 · abrir y cerrar la campana deja leídas las notificaciones; tocar un push lo marca leído

status: proposed
cap: 1 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «al abrir las notificaciones no se marcan las notificaciones como leidas» · respuesta a la pregunta: «digo en la app, si tocas la campanita y la cerras, las notificaciones no se marcan como leidas, la notificaciones push si hay que tocarlas»"
  - "repo · apps/mobile/lib/notificaciones/pantalla_notificaciones.dart, centro.dart (`marcarLeida`, `marcarTodas`), campana.dart, app.dart (`alTocarDesdeElSistema`, `abiertaPor`), sistema.dart (`AvisoTocado`: tipo y reserva, sin id de notificación)"
  - "CU-24.1 FA3: «El usuario ignora la notificación. Queda en el centro de notificaciones marcada como no leída.»"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "si tocas la campanita y la cerras, las notificaciones no se marcan como leidas" · acceptance: al salir del centro de notificaciones abierto desde la campana, todas las que se mostraron sin leer quedan leídas (en la app y en la API, con `leer-todas`) y la campana deja de contarlas; mientras el centro está abierto siguen marcadas como sin leer, para que se distingan
- S2 · "la notificaciones push si hay que tocarlas" · acceptance: tocar un aviso en la bandeja del sistema (con la app abierta, en segundo plano o cerrada) marca leídas en el centro las notificaciones sin leer de ese mismo tipo y reserva, además de abrir la reserva como hoy
- NOT-03-ASM-01 · un push que llega y no se toca sigue sin leer hasta que se abre la campana, como pide el caso de uso del recordatorio cuando la persona ignora el aviso · S2
- NOT-03-ASM-02 · si la API no contesta al marcar, la app las muestra leídas y la próxima lectura corrige, igual que `marcarTodas` hoy · S1

## Tasks

- T1 · S1,NOT-03-ASM-02 · apps/mobile/lib/notificaciones/pantalla_notificaciones.dart (presentation) · tests: apps/mobile/test/campana_marca_leidas_test.dart "abrir la campana y volver deja leídas las que se mostraron y la campana en cero @NOT-03-S1"; apps/mobile/test/campana_marca_leidas_test.dart "con el centro abierto las nuevas siguen marcadas sin leer @NOT-03-S1"; apps/mobile/test/campana_marca_leidas_test.dart "si la API no contesta al salir se ven leídas y la próxima lectura corrige @assumption:NOT-03-ASM-02"
  reuses: apps/mobile/lib/notificaciones/centro.dart `marcarTodas`
- T2 · S2,NOT-03-ASM-01 · apps/mobile/lib/notificaciones/centro.dart (presentation), apps/mobile/lib/app.dart (presentation) · tests: apps/mobile/test/campana_marca_leidas_test.dart "tocar un push marca leídas las de ese tipo y reserva y abre la reserva @NOT-03-S2"; apps/mobile/test/campana_marca_leidas_test.dart "un push que no se toca sigue sin leer @assumption:NOT-03-ASM-01"
  reuses: apps/mobile/lib/notificaciones/centro.dart `marcarLeida`; apps/mobile/lib/notificaciones/sistema.dart `AvisoTocado`

## Changes to existing behavior

- salir del centro de notificaciones marca todas como leídas (hoy quedan sin leer); tocar un push marca leída su notificación (hoy no)

## Gate

```
suite: sh D:/Temp/w/herramientas/flutter-mobile.sh test/campana_marca_leidas_test.dart test/notificaciones_test.dart test/permiso_al_entrar_notificaciones_test.dart
fmt: D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test/campana_marca_leidas_test.dart
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
no-docs: cuándo una notificación queda leída; el contrato y el modelo de datos no cambian
refactor-tests: sacar un import sin uso y extraer el montaje repetido de los dos tests de push (lint y K4); no cambia lo que verifican
no-visual: la pantalla se ve igual; cambia cuándo se marcan leídas
```

## Log

- L1 · al abrir las notificaciones no se marcan las notificaciones como leidas · digo en la app, si tocas la campanita y la cerras, las notificaciones no se marcan como leidas, la notificaciones push si hay que tocarlas
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base: sólo la app
- L3 · 2026-10-27 · declared · attacks · la card no cambia la API: usa `leer-todas` y `leer` como hoy
- L4 · 2026-10-27 · T1 · `node .claude/tools/verify.mjs` exit 0; los 3 tests de campana_marca_leidas_test.dart (S1, ASM-02) pasan; `dispose` de PantallaNotificaciones llama `marcarTodas` en un microtask
- L5 · 2026-10-27 · T2 · mismo gate; `marcarLasDelAviso` en centro.dart, llamado desde los dos caminos de app.dart; tests S2 y ASM-01 pasan
- L6 · 2026-10-27 · refactor-tests · campana_marca_leidas_test.dart · un import sin uso y el montaje repetido (lint y K4) · declarado en `## Gate`
