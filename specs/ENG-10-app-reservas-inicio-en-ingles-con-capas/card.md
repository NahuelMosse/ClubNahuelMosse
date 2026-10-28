# ENG-10 · las reservas y el inicio de la app están en inglés y en capas

status: proposed
cap: 2 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «no me gusta nada que todo el codigo este en español» · elige «Todo, base y API incluidas» · «en la app no hay capas, y es complicadisimo de entender por eso, la logica esta al lado de los componentes» · «terminala en paralelo» · «dejala en su propia branch, sin tocar main» · «quien te dijo que frenes, capaz llegamos, pero hacelo rapido»"
  - "glosario · docs/technical/glosario-ingles.md (R1: un enum cuyo nombre llega a la UI o a la API recibe primero `label` en castellano y valor de API explícito); la base de la app y la regla de capas ya están en inglés en ENG-08"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "no me gusta nada que todo el codigo este en español" · acceptance: lo que hoy está en `apps/mobile/lib/reservas/` y `apps/mobile/lib/inicio/` vive en `apps/mobile/lib/features/bookings/` y `apps/mobile/lib/features/home/` con archivos, clases, funciones, parámetros, campos, variables, comentarios y docs en inglés según el glosario; no quedan `lib/reservas/` ni `lib/inicio/`
- S2 · "en la app no hay capas [...] la logica esta al lado de los componentes" · acceptance: `features/bookings` y `features/home` están partidos en `data/`, `domain/` y `presentation/` y cumplen la regla de capas de test/capas_test.dart
- S3 · "Todo, base y API incluidas" · acceptance: reservar, ver, modificar y cancelar reservas y el inicio hacen y muestran lo mismo que hoy; los textos, las rutas de la API, las claves JSON, los valores de estado que manda la API y las rutas de pantalla no cambian; los tests de reservas e inicio siguen pasando
- ENG-10-ASM-01 · `EstadoDeReserva` pasa a `BookingStatus` con `label` en castellano y el valor de la API explícito (R1 del glosario) · S3
- ENG-10-ASM-02 · los tests cambian sólo imports, símbolos y rutas de archivo con `refactor-tests:`; títulos y nombres de archivo de test quedan en castellano · S1
- ENG-10-ASM-03 · una pieza que usan reservas y otra funcionalidad queda en `lib/common/` con nombre en inglés · S2

## Tasks

- T1 · S1,S2,S3,ENG-10-ASM-01,ENG-10-ASM-02,ENG-10-ASM-03 · apps/mobile/lib/features/bookings/data (data), apps/mobile/lib/features/bookings/domain (rule), apps/mobile/lib/features/bookings/presentation (presentation), apps/mobile/lib/features/home/data (data), apps/mobile/lib/features/home/domain (rule), apps/mobile/lib/features/home/presentation (presentation), apps/mobile/lib/rutas.dart (presentation), docs/technical/glosario-ingles.md (presentation) · tests: apps/mobile/test/reservas_en_ingles_test.dart "las reservas y el inicio viven en features/bookings y features/home con nombres en inglés @ENG-10-S1 @assumption:ENG-10-ASM-02"; apps/mobile/test/reservas_en_ingles_test.dart "bookings y home están partidos en data, domain y presentation y cumplen la regla de capas @ENG-10-S2 @assumption:ENG-10-ASM-03"; apps/mobile/test/reservas_en_ingles_test.dart "los textos, rutas de la API, claves JSON y rutas de pantalla de reservas e inicio son los de antes @ENG-10-S3"; apps/mobile/test/reservas_en_ingles_test.dart "BookingStatus muestra su label en castellano y lee el valor de la API de siempre @assumption:ENG-10-ASM-01"
  reuses: cada archivo de lib/reservas y lib/inicio se mueve y se traduce; apps/mobile/test/capas_test.dart (la regla de capas de ENG-08)
  why-layer: el pedido del usuario: «en la app no hay capas, y es complicadisimo de entender por eso, la logica esta al lado de los componentes»

## Changes to existing behavior

- none: reservas e inicio se ven y se comportan igual

## Gate

```
suite [timeout 1 h]: sh D:/Temp/w/herramientas/flutter-mobile.sh
fmt: D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test/reservas_en_ingles_test.dart
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
refactor-tests: lib/reservas y lib/inicio pasan a lib/features en inglés: los tests cambian sólo imports, símbolos y rutas de archivo
no-visual: las pantallas se ven igual; cambian nombres y carpetas
no-docs: nombres internos de la app (el glosario se actualiza en T1)
```

## Log

- L1 · no me gusta nada que todo el codigo este en español · Todo, base y API incluidas · en la app no hay capas, y es complicadisimo de entender por eso, la logica esta al lado de los componentes · terminala en paralelo · dejala en su propia branch, sin tocar main · quien te dijo que frenes, capaz llegamos, pero hacelo rapido
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base: sólo la app
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
- L4 · 2026-10-27 · parte de ENG-08, en paralelo con ENG-09 y ENG-11; termina en la rama `ingles`, nunca en main
- L5 · 2026-10-27 · T1 · lib/reservas y lib/inicio movidos a lib/features/{bookings,home}/{data,domain,presentation}; `flutter analyze` 0 errores; `flutter test test/capas_test.dart test/reservas_en_ingles_test.dart` 6/6 verdes; fmt passed; suite del gate sin terminar tras 40 min (CPU compartida con otras ramas)
