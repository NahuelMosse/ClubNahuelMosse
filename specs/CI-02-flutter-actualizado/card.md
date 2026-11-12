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

## Tasks

- T1 · S1,CI-02-ASM-01,CI-02-ASM-02 · .github/workflows/ci.yml (presentation), apps/mobile/pubspec.yaml, apps/mobile/pubspec.lock, tests/flutter-sdk.test.mjs · tests: tests/flutter-sdk.test.mjs "the app job installs a Flutter whose Dart is 3.11 or more @CI-02-S1"; tests/flutter-sdk.test.mjs "the app job installs the latest 3.41 Flutter @CI-02-ASM-01"; tests/flutter-sdk.test.mjs "the SDK floor of the app is Dart 3.11.0 and the lock agrees @CI-02-ASM-02"
  new: no test reads the Flutter version of the workflow or the SDK floor (Grep flutter-version, sdk: in tests/)
- T2 · S1,CI-02-ASM-03 · apps/mobile/README.md (presentation), docs/technical/architecture.md (presentation), docs/technical/system-design.md (presentation), tests/flutter-sdk.test.mjs · tests: tests/flutter-sdk.test.mjs "the current docs name the Dart of the app SDK floor @CI-02-ASM-03"
  new: no doc test names the Dart version (Grep Dart in tests/)

## Changes to existing behavior

- .github/workflows/ci.yml · el job de la app instala Flutter 3.41.9 · "the app job runs flutter analyze, the format check and flutter test judged by the replaced tests rule @CI-01-S1" stays valid

## Gate

```
node: node --test tests/flutter-sdk.test.mjs tests/ci.test.mjs
lint: cd apps/mobile && flutter analyze
fmt: cd apps/mobile && dart format --output=none --set-exit-if-changed lib
suite [timeout 30 min]: cd apps/mobile && flutter test
no-visual: la card no toca ninguna pantalla de la app
no-docs: la card sube la versión de la herramienta; no cambia comportamiento ni contrato
```

## Log

- L1 · Pregunta: «¿Actualizar Flutter en el proyecto a una versión con Dart 3.11 o más (opción 1) o cerrar el PR?» · Respuesta de la persona: «1»
- L2 · 2026-11-11 · declared · restart · la card no guarda nada: sube la versión de Flutter del CI y del pubspec; la app y su base quedan como en main
- L3 · 2026-11-12 · declared · S1 · «o más» es un piso de versión, no una rama: un solo comportamiento, que el CI instale un Flutter con Dart 3.11 o más
- L4 · 2026-11-12 · declared · ASM-01 · Flutter 3.50.0 se descartó: analyze da 397 problemas no mecánicos; se fija 3.41.9 (Dart 3.11.5); el test de ASM-01 se corrigió antes del primer push, cuando todavía no estaba en main
