# NOT-04 · la campana de la portada se ve en modo claro

status: proposed
cap: 30 min
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «todavia veo el bug de que el icono de notificaciones no se ve por contraste en el modo claro» · «cuando esta en negro en modo claro no se ve» · «cuando no tiene notificaciones»"
  - "repo · apps/mobile/lib/notificaciones/campana.dart (`BotonNotificaciones` pinta el ícono con `textPrimary`), apps/mobile/lib/inicio/hero_de_inicio.dart (la campana va sobre la foto; «sus colores son los `on-media`, iguales en los dos modos»)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "cuando esta en negro en modo claro no se ve" · acceptance: en la portada, la campana sin avisos sin leer se pinta con `textOnMedia` (el color del texto sobre la foto, igual en modo claro y oscuro), no con `textPrimary`, que en modo claro es casi negro sobre la foto oscura
- NOT-04-ASM-01 · la campana con avisos sin leer conserva su contador en `accentBase`; sólo cambia el color del ícono · S1

## Tasks

- T1 · S1,NOT-04-ASM-01 · apps/mobile/lib/notificaciones/campana.dart (presentation) · tests: apps/mobile/test/campana_sobre_foto_test.dart "en modo claro y oscuro la campana de la portada se pinta con el color sobre foto @NOT-04-S1"; apps/mobile/test/campana_sobre_foto_test.dart "con avisos sin leer el contador sigue en el acento @assumption:NOT-04-ASM-01"
  reuses: `textOnMedia` de la paleta, que ya usa el resto de la portada

## Changes to existing behavior

- la campana de la portada pasa de casi negra a blanca en modo claro

## Gate

```
suite: sh D:/Temp/w/herramientas/flutter-mobile.sh test/campana_sobre_foto_test.dart test/notificaciones_test.dart test/campana_marca_leidas_test.dart
fmt: D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test/campana_sobre_foto_test.dart
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
no-docs: un color de un ícono; el contrato y el modelo de datos no cambian
no-visual: cambia el color de un ícono a un token que ya existe; lo verifica el test en los dos modos
```

## Log

- L1 · todavia veo el bug de que el icono de notificaciones no se ve por contraste en el modo claro · cuando esta en negro en modo claro no se ve · cuando no tiene notificaciones
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
