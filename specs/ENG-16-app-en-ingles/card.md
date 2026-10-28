# ENG-16 · la app en inglés y en capas, sobre la API en inglés

status: proposed
cap: 2 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «no me gusta nada que todo el codigo este en español» · «en la app no hay capas, y es complicadisimo de entender por eso, la logica esta al lado de los componentes» · «lo de ingles ya lo podemos mergear si esta terminado»"
  - "trabajo previo · rama `ingles` (ENG-08..ENG-11, ENG-15): la app en lib/features/<x>/{data,domain,presentation} en inglés, con SAL-01 y VIS-02 de main ya portados (ae94d52)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "no me gusta nada que todo el codigo este en español" · acceptance: el código de la app (apps/mobile/lib) está en inglés, en lib/features/<x>/{data,domain,presentation}, y se ve y se comporta como main: mismos textos de interfaz (castellano por ahora; traducir la interfaz es otra card)
- S2 · "la logica esta al lado de los componentes" · acceptance: cada funcionalidad de `lib/features` cumple la regla de capas (data, domain, presentation; sin archivos sueltos)
- ENG-16-ASM-01 · un test que falla por un comportamiento distinto de main (no por un nombre) se arregla en el código para que la app se comporte como main · S1

## Tasks

- T1 · S1,S2,ENG-16-ASM-01 · apps/mobile/lib (presentation), apps/mobile/lib/features/*/domain (rule), apps/mobile/lib/features/*/data (data), apps/mobile/test/app_en_ingles_verde_test.dart · tests: apps/mobile/test/app_en_ingles_verde_test.dart "ningún archivo de lib queda en una carpeta en castellano @ENG-16-S1 @assumption:ENG-16-ASM-01"; apps/mobile/test/app_en_ingles_verde_test.dart "cada funcionalidad de lib/features tiene sus capas data, domain y presentation @ENG-16-S2"
  reuses: el código de ENG-08..ENG-11 y ENG-15 de la rama `ingles`; la regla de capas de test/capas_test.dart
- T2 · S1 · apps/mobile/test/** · los tests de la app siguen a las carpetas y nombres en inglés (traídos de la rama `ingles`); mismos títulos y tags
  new: no escribe lógica: sólo cambian imports, símbolos y rutas de los tests ya congelados

## Changes to existing behavior

- none: la app se ve y se comporta como main; cambian nombres y carpetas

## Gate

```
suite [timeout 1 h]: sh D:/Temp/w/herramientas/flutter-mobile.sh
fmt: D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test/app_en_ingles_verde_test.dart
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
refactor-tests: los tests de la app siguen a las carpetas y nombres en inglés: cambian sólo imports, símbolos y rutas de archivo
no-docs: nombres internos de la app
no-visual: las pantallas se ven igual
```

## Log

- L1 · no me gusta nada que todo el codigo este en español · en la app no hay capas, y es complicadisimo de entender por eso, la logica esta al lado de los componentes · lo de ingles ya lo podemos mergear si esta terminado
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
