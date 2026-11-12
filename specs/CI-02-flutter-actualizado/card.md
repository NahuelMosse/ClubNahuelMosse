# CI-02 · Flutter actualizado a Dart 3.11 o más

status: proposed
cap: 60 min
sources: pedido de la persona en la sesión (texto); PR #63 de Dependabot (shared_preferences 2.5.5 → 2.5.6) con el CI en rojo en `flutter pub get`: 2.5.6 pide Dart ^3.11.0 y `ci.yml` fija Flutter 3.35.3 (Dart 3.9.2); feed oficial de releases de 
not_read: ninguno: no hay Jira ni adjuntos

## Specs

- S1 · "Actualizar Flutter en el proyecto a una versión con Dart 3.11 o más"
- CI-02-ASM-01 · la versión es la última parche de la serie con Dart 3.11 del feed oficial, Flutter 3.41.9 con Dart 3.11.5, la última 3.41: con Flutter 3.50.0 (Dart 3.14.0) `flutter analyze` falla con 397 problemas (Material deprecado a favor de `material_ui`, `Tristate` en tests congelados) y migrarlo no es mecánico · S1
- CI-02-ASM-02 · el piso del SDK de la app sube sólo hasta lo que pide el paquete: `sdk: ^3.11.0` en `pubspec.yaml`, sin tocar los demás límites de dependencias; `pubspec.lock` se regenera con `flutter pub get` · S1
- CI-02-ASM-03 · el texto vigente que nombra la versión (README de la app, arquitectura, diseño del sistema) pasa a la nueva; las cards y planes ya cerrados quedan como se escribieron · S1
- CI-02-ASM-04 · con Flutter 3.41 las banderas enabled, selected, toggled, expanded, required y focused de la semántica son `Tristate`, no `bool`: los tests que las leen las comparan con `Tristate.isTrue` (`isEnabled == Tristate.isTrue`), que da lo mismo que el `bool` de antes (falso si la bandera no aplica o está apagada), y importan `Tristate` de `dart:ui`; ningún test cambia lo que verifica · S1

## Tasks

- T1 · S1,CI-02-ASM-01,CI-02-ASM-02 · .github/workflows/ci.yml (presentation), apps/mobile/pubspec.yaml, apps/mobile/pubspec.lock, tests/ci.test.mjs, tests/flutter-sdk.test.mjs · tests: tests/flutter-sdk.test.mjs "the app job installs a Flutter whose Dart is 3.11 or more @CI-02-S1"; tests/flutter-sdk.test.mjs "the app job installs the latest 3.41 Flutter @CI-02-ASM-01"; tests/flutter-sdk.test.mjs "the SDK floor of the app is Dart 3.11.0 and the lock agrees @CI-02-ASM-02"
  new: no test reads the Flutter version of the workflow or the SDK floor (Grep flutter-version, sdk: in tests/)
- T2 · S1,CI-02-ASM-03 · apps/mobile/README.md (presentation), docs/technical/architecture.md (presentation), docs/technical/system-design.md (presentation), tests/flutter-sdk.test.mjs · tests: tests/flutter-sdk.test.mjs "the current docs name the Dart of the app SDK floor @CI-02-ASM-03"
  new: no doc test names the Dart version (Grep Dart in tests/)
- T3 · S1,CI-02-ASM-04 · apps/mobile/integration_test/bookings/book_test.dart, apps/mobile/integration_test/bookings/browse_availability_test.dart, apps/mobile/integration_test/bookings/browse_courts_test.dart, apps/mobile/integration_test/bookings/cancel_booking_test.dart, apps/mobile/integration_test/bookings/global_history_test.dart, apps/mobile/integration_test/bookings/modify_booking_test.dart, apps/mobile/integration_test/notifications/cancellation_confirmation_test.dart, apps/mobile/integration_test/notifications/forced_cancellation_test.dart, apps/mobile/integration_test/notifications/notifications_test.dart, apps/mobile/integration_test/spaces/edit_space_test.dart, apps/mobile/integration_test/venues/browse_venues_test.dart, apps/mobile/integration_test/venues/edit_venue_test.dart, apps/mobile/integration_test/venues/filter_spaces_test.dart, apps/mobile/test/availability_test.dart, apps/mobile/test/court_search_spanish_test.dart, apps/mobile/test/edit_space_test.dart, apps/mobile/test/edit_venue_test.dart, apps/mobile/test/modify_booking_test.dart, apps/mobile/test/notifications_spanish_test.dart, apps/mobile/test/notifications_test.dart, apps/mobile/test/search_court_test.dart, apps/mobile/test/venues_user_test.dart, tests/semantics-tristate.test.mjs · tests: tests/semantics-tristate.test.mjs "the semantics tests compare the Tristate flags with Tristate.isTrue @CI-02-ASM-04"; tests/semantics-tristate.test.mjs "the tests that read a Tristate flag import it from dart:ui @CI-02-ASM-04"
  new: no test checks how the semantics flags are read (Grep flagsCollection in tests/)

## Changes to existing behavior

- .github/workflows/ci.yml · el job de la app instala Flutter 3.41.9 · "the app job runs flutter analyze, the format check and flutter test judged by the replaced tests rule @CI-01-S1" stays valid
- apps/mobile/test y apps/mobile/integration_test · las lecturas de `flagsCollection.isEnabled` e `isSelected` (y `flags(...)` en integration_test) comparan con `Tristate.isTrue` · cada test conserva su tag y su aserción

## Gate

```
node: node --test tests/flutter-sdk.test.mjs tests/ci.test.mjs tests/semantics-tristate.test.mjs
lint: npx -y eslint@9 --no-config-lookup --rule {"no-unused-vars":"error"} tests/ci.test.mjs tests/flutter-sdk.test.mjs tests/semantics-tristate.test.mjs
refactor-tests: tests/ci.test.mjs fija la versión de Flutter del job de la app; sigue la versión nueva (3.35.3 → 3.41.9) sin cambiar lo que verifica; los tests de apps/mobile que leen banderas de semántica pasan de `bool` a `Tristate` (`== Tristate.isTrue`) sin cambiar lo que verifican
no-visual: la card no toca ninguna pantalla de la app
no-docs: la card sube la versión de la herramienta; no cambia comportamiento ni contrato
```

## Log

- L1 · Pregunta: «¿Actualizar Flutter en el proyecto a una versión con Dart 3.11 o más (opción 1) o cerrar el PR?» · Respuesta de la persona: «1»
- L2 · 2026-11-11 · declared · restart · la card no guarda nada: sube la versión de Flutter del CI y del pubspec; la app y su base quedan como en main
- L3 · 2026-11-12 · declared · S1 · «o más» es un piso de versión, no una rama: un solo comportamiento, que el CI instale un Flutter con Dart 3.11 o más
- L4 · 2026-11-12 · declared · ASM-01 · Flutter 3.50.0 se descartó: analyze da 397 problemas no mecánicos; se fija 3.41.9 (Dart 3.11.5); el test de ASM-01 se corrigió antes del primer push, cuando todavía no estaba en main
- L5 · 2026-11-12 · declared · gate · flutter analyze, dart format y flutter test con Flutter 3.41.9 no corren en esta máquina (no hay ese SDK instalado): los corre el job de la app del CI del PR, que es el chequeo requerido
- L6 · 2026-11-12 · declared · ASM-04 · Flutter 3.41 pasó las banderas de semántica a Tristate: 22 tests de apps/mobile las leen con == Tristate.isTrue, bajo refactor-tests; el CI del PR con 3.41.9 lo valida
- L7 · 2026-11-12 · declared · K4 · apps/mobile/test/court_search_spanish_test.dart · test congelado que ya repetía los imports y el helper de su par; la card sólo le cambia la lectura de la bandera a Tristate y los congelados no se refactorizan
- L8 · 2026-11-12 · declared · K4 · apps/mobile/test/search_court_test.dart · test congelado que ya repetía los imports y el helper de su par; la card sólo le cambia la lectura de la bandera a Tristate y los congelados no se refactorizan
- L9 · 2026-11-12 · declared · K4 · apps/mobile/integration_test/notifications/cancellation_confirmation_test.dart · test congelado que ya repetía los imports y el helper de su par; la card sólo le cambia la lectura de la bandera a Tristate y los congelados no se refactorizan
- L10 · 2026-11-12 · declared · K4 · apps/mobile/integration_test/notifications/forced_cancellation_test.dart · test congelado que ya repetía los imports y el helper de su par; la card sólo le cambia la lectura de la bandera a Tristate y los congelados no se refactorizan
- L11 · 2026-11-12 · declared · K4 · apps/mobile/integration_test/bookings/book_test.dart · test congelado que ya repetía los imports y el helper de su par; la card sólo le cambia la lectura de la bandera a Tristate y los congelados no se refactorizan
- L12 · 2026-11-12 · declared · K4 · apps/mobile/integration_test/bookings/modify_booking_test.dart · test congelado que ya repetía los imports y el helper de su par; la card sólo le cambia la lectura de la bandera a Tristate y los congelados no se refactorizan
- L13 · 2026-11-12 · declared · K4 · apps/mobile/integration_test/bookings/cancel_booking_test.dart · test congelado que ya repetía los imports y el helper de su par; la card sólo le cambia la lectura de la bandera a Tristate y los congelados no se refactorizan
- L14 · 2026-11-12 · declared · K4 · apps/mobile/integration_test/spaces/edit_space_test.dart · test congelado que ya repetía los imports y el helper de su par; la card sólo le cambia la lectura de la bandera a Tristate y los congelados no se refactorizan
- L15 · 2026-11-12 · declared · K4 · apps/mobile/integration_test/venues/edit_venue_test.dart · test congelado que ya repetía los imports y el helper de su par; la card sólo le cambia la lectura de la bandera a Tristate y los congelados no se refactorizan
