# ENG-11 · sedes, espacios, sesión, usuarios, notificaciones y el router de la app están en inglés y en capas

status: proposed
cap: 2 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «no me gusta nada que todo el codigo este en español» · elige «Todo, base y API incluidas» · «en la app no hay capas, y es complicadisimo de entender por eso, la logica esta al lado de los componentes» · «terminala en paralelo» · «dejala en su propia branch, sin tocar main» · «quien te dijo que frenes, capaz llegamos, pero hacelo rapido»"
  - "glosario · docs/technical/glosario-ingles.md (R1: `Rol` y `TipoDeNotificacion` reciben `label` en castellano y valor de API explícito antes de renombrarse); la base de la app y la regla de capas ya están en inglés en ENG-08 (`lib/features/users` ya existe)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "no me gusta nada que todo el codigo este en español" · acceptance: lo que hoy está en `apps/mobile/lib/{sedes,espacios,sesion,usuarios,notificaciones}/`, y `lib/rutas.dart` vive en `lib/features/{venues,spaces,session,users,notifications}/` y `lib/router.dart` con nombres (el cliente `lib/api/` pasa con la card del contrato), comentarios y docs en inglés según el glosario; no quedan las carpetas ni los archivos en castellano
- S2 · "en la app no hay capas [...] la logica esta al lado de los componentes" · acceptance: cada una de esas funcionalidades está partida en `data/`, `domain/` y `presentation/` y cumple la regla de capas de test/capas_test.dart
- S3 · "Todo, base y API incluidas" · acceptance: iniciar sesión, registrarse, recuperar la contraseña, el perfil, las sedes, los espacios y las notificaciones hacen y muestran lo mismo que hoy; los textos, las rutas de la API, las claves JSON, los valores que manda la API y las rutas de pantalla no cambian; sus tests siguen pasando
- ENG-11-ASM-01 · `Rol` pasa a `Role` y `TipoDeNotificacion` a `NotificationKind` con `label` en castellano y el valor de la API explícito (R1 del glosario) · S3
- ENG-11-ASM-02 · los tests cambian sólo imports, símbolos y rutas de archivo con `refactor-tests:`; títulos y nombres de archivo de test quedan en castellano · S1
- ENG-11-ASM-03 · el router sólo cambia su nombre de archivo y sus símbolos; las rutas de pantalla (`/inicio`, `/sedes/...`) siguen iguales hasta la card del contrato · S3

## Tasks

- T1 · S1,S2,S3,ENG-11-ASM-01,ENG-11-ASM-02,ENG-11-ASM-03 · apps/mobile/lib/features/venues/data (data), apps/mobile/lib/features/venues/domain (rule), apps/mobile/lib/features/venues/presentation (presentation), apps/mobile/lib/features/spaces/data (data), apps/mobile/lib/features/spaces/domain (rule), apps/mobile/lib/features/spaces/presentation (presentation), apps/mobile/lib/features/session/data (data), apps/mobile/lib/features/session/domain (rule), apps/mobile/lib/features/session/presentation (presentation), apps/mobile/lib/features/users/data (data), apps/mobile/lib/features/users/presentation (presentation), apps/mobile/lib/features/notifications/data (data), apps/mobile/lib/features/notifications/domain (rule), apps/mobile/lib/features/notifications/presentation (presentation), apps/mobile/lib/router.dart (presentation), docs/technical/glosario-ingles.md (presentation) · tests: apps/mobile/test/cuenta_en_ingles_test.dart "sedes, espacios, sesión, usuarios, notificaciones y el router viven en inglés y no quedan carpetas en castellano @ENG-11-S1 @assumption:ENG-11-ASM-02"; apps/mobile/test/cuenta_en_ingles_test.dart "cada funcionalidad está partida en data, domain y presentation y cumple la regla de capas @ENG-11-S2"; apps/mobile/test/cuenta_en_ingles_test.dart "los textos, rutas de la API, claves JSON y rutas de pantalla son los de antes @ENG-11-S3 @assumption:ENG-11-ASM-03"; apps/mobile/test/cuenta_en_ingles_test.dart "Role y NotificationKind muestran su label en castellano y leen el valor de la API de siempre @assumption:ENG-11-ASM-01"
  reuses: cada archivo se mueve y se traduce; lib/features/users de ENG-08; apps/mobile/test/capas_test.dart (la regla de capas de ENG-08)
  why-layer: el pedido del usuario: «en la app no hay capas, y es complicadisimo de entender por eso, la logica esta al lado de los componentes»

## Changes to existing behavior

- none: las pantallas se ven y se comportan igual

## Gate

```
suite [timeout 1 h]: sh D:/Temp/w/herramientas/flutter-mobile.sh
fmt: D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test/cuenta_en_ingles_test.dart
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
refactor-tests: sedes, espacios, sesión, usuarios, notificaciones y el router de la app pasan a inglés: los tests cambian sólo imports, símbolos y rutas de archivo
no-visual: las pantallas se ven igual; cambian nombres y carpetas
no-docs: nombres internos de la app (el glosario se actualiza en T1)
```

## Log

- L1 · no me gusta nada que todo el codigo este en español · Todo, base y API incluidas · en la app no hay capas, y es complicadisimo de entender por eso, la logica esta al lado de los componentes · terminala en paralelo · dejala en su propia branch, sin tocar main · quien te dijo que frenes, capaz llegamos, pero hacelo rapido
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base: sólo la app
- L3 · 2026-10-27 · declared · attacks · la card no cambia la API: el cliente cambia de nombre y pide las mismas rutas y cuerpos
- L4 · 2026-10-27 · parte de ENG-08, en paralelo con ENG-09 y ENG-10; termina en la rama `ingles`, nunca en main
