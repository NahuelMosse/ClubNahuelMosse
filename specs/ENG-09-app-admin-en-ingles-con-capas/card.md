# ENG-09 · el panel de administración de la app está en inglés y en capas

status: proposed
cap: 2 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «no me gusta nada que todo el codigo este en español» · elige «Todo, base y API incluidas» · «en la app no hay capas, y es complicadisimo de entender por eso, la logica esta al lado de los componentes» · «terminala en paralelo» · «dejala en su propia branch, sin tocar main» · «quien te dijo que frenes, capaz llegamos, pero hacelo rapido»"
  - "glosario · docs/technical/glosario-ingles.md; la base de la app y la regla de capas ya están en inglés en ENG-08 (`lib/common`, `lib/theme`, `lib/features/users`, test/capas_test.dart)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "no me gusta nada que todo el codigo este en español" · acceptance: lo que hoy está en `apps/mobile/lib/admin/` vive en `apps/mobile/lib/features/admin/` con archivos, clases, funciones, parámetros, campos, variables, comentarios y docs en inglés según el glosario; no queda `lib/admin/`
- S2 · "en la app no hay capas [...] la logica esta al lado de los componentes" · acceptance: `features/admin` está partido en `data/` (llamadas a la API y JSON), `domain/` (modelos y reglas, sin Flutter ni HTTP) y `presentation/` (pantallas, widgets y estado), y cumple la regla de capas que verifica test/capas_test.dart
- S3 · "Todo, base y API incluidas" · acceptance: el panel hace y muestra lo mismo que hoy: los textos que ve el usuario, las rutas de la API, las claves JSON y las rutas de pantalla no cambian; los tests del panel siguen pasando
- ENG-09-ASM-01 · los tests cambian sólo imports, símbolos y rutas de archivo con `refactor-tests:`; títulos y nombres de archivo de test quedan en castellano · S1
- ENG-09-ASM-02 · un nombre que el glosario no tiene se traduce con el mismo criterio y se agrega al glosario · S1
- ENG-09-ASM-03 · si una pieza del panel la usan otras funcionalidades, queda en `lib/common/` con nombre en inglés · S2

## Tasks

- T1 · S1,S2,S3,ENG-09-ASM-01,ENG-09-ASM-02,ENG-09-ASM-03 · apps/mobile/lib/features/admin/data (data), apps/mobile/lib/features/admin/domain (rule), apps/mobile/lib/features/admin/presentation (presentation), apps/mobile/lib/rutas.dart (presentation), docs/technical/glosario-ingles.md (presentation) · tests: apps/mobile/test/admin_en_ingles_test.dart "el panel de administración vive en features/admin con nombres en inglés y no queda lib/admin @ENG-09-S1 @assumption:ENG-09-ASM-02"; apps/mobile/test/admin_en_ingles_test.dart "features/admin está partido en data, domain y presentation y cumple la regla de capas @ENG-09-S2 @assumption:ENG-09-ASM-03"; apps/mobile/test/admin_en_ingles_test.dart "los textos, rutas de la API, claves JSON y rutas de pantalla del panel son los de antes @ENG-09-S3"; apps/mobile/test/admin_en_ingles_test.dart "ningún test importa lib/admin @assumption:ENG-09-ASM-01"
  reuses: cada archivo de lib/admin se mueve y se traduce; apps/mobile/test/capas_test.dart (la regla de capas de ENG-08)
  why-layer: el pedido del usuario: «en la app no hay capas, y es complicadisimo de entender por eso, la logica esta al lado de los componentes»

## Changes to existing behavior

- none: el panel se ve y se comporta igual

## Gate

```
suite [timeout 1 h]: sh D:/Temp/w/herramientas/flutter-mobile.sh
fmt: D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test/admin_en_ingles_test.dart
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
refactor-tests: lib/admin pasa a lib/features/admin en inglés: los tests cambian sólo imports, símbolos y rutas de archivo
no-visual: el panel se ve igual; cambian nombres y carpetas
no-docs: nombres internos de la app (el glosario se actualiza en T1)
```

## Log

- L1 · no me gusta nada que todo el codigo este en español · Todo, base y API incluidas · en la app no hay capas, y es complicadisimo de entender por eso, la logica esta al lado de los componentes · terminala en paralelo · dejala en su propia branch, sin tocar main · quien te dijo que frenes, capaz llegamos, pero hacelo rapido
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base: sólo la app
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
- L4 · 2026-10-27 · parte de ENG-08 (rama ENG-08-app-base-en-ingles-con-capas), en paralelo con ENG-10 y ENG-11; termina en la rama `ingles`, nunca en main
- L5 · 2026-10-27 · T1 · flutter analyze --no-pub: No issues found; flutter test test/admin test/admin_en_ingles_test.dart test/capas_test.dart: 16 passed; shapeProblems en features/admin/presentation: 0; verify.mjs sigue rojo en suite (sin corrida limpia), attacks y required (mutación de domain, judge.md)
