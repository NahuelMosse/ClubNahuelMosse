# El stack de este repo, y qué comando corre cada chequeo

El método nombra los chequeos; este archivo dice con qué se corren acá. Si un comando de
`METODOLOGIA.md`, `/escenarios`, `/validar` o `/cerrar` no coincide con esta tabla, manda esta
tabla.

| | |
|---|---|
| App móvil | Flutter, en `apps/mobile/` |
| API REST | Python con FastAPI, documentada con OpenAPI, en `apps/api/` |
| Base de datos | PostgreSQL |
| Auth y push | Firebase Authentication y Firebase Cloud Messaging |
| Despliegue | API y base en la nube (Render u otro equivalente) |

## Dónde viven los tests

```
E2E="apps/mobile/integration_test apps/api/tests/escenarios"
```

| Carpeta | Qué va | Archivo |
|---|---|---|
| `apps/mobile/integration_test/` | los escenarios que se recorren por pantalla | `<área>/<pantalla>_test.dart` |
| `apps/api/tests/escenarios/` | los escenarios que son una regla del backend y no tienen pantalla: superposición, permisos por API, validaciones del enunciado | `test_<recurso>.py` |
| `apps/mobile/test/` y `apps/api/tests/unit/` | unitarios, del implementador, sin tag de card | — |

**El tag va en el nombre del test, al final**, igual que en el resto del método:

```dart
testWidgets('la reserva superpuesta no se confirma @CU-09-H02-02', (tester) async { … });
```

```python
def test_la_reserva_superpuesta_se_rechaza():
    """la reserva superpuesta se rechaza @CU-09-H02-02"""
```

Los IDs de card pueden llevar letra o punto (`CU-04b`, `CU-24.1`), así que el patrón de tags es:

```
@[A-Z]+-[0-9]+[a-z]?(\.[0-9]+)?-H[0-9]+-[0-9]+
```

## Comandos

| Chequeo | Comando |
|---|---|
| Todo lo que cuenta, el comando por defecto | `sh scripts/test.sh` en la raíz: corre los cuatro de abajo en orden y sale distinto de cero si falla cualquiera. Lo crea la primera card |
| Unitarios de la app | `cd apps/mobile && flutter test` |
| Tipos y lint de la app | `cd apps/mobile && flutter analyze && dart format --output=none --set-exit-if-changed lib test` (los escenarios congelados no se reformatean) |
| Unitarios y escenarios de la API | `cd apps/api && pytest` |
| Tipos y lint de la API | `cd apps/api && ruff check . && mypy --strict app` |
| Escenarios de una card, app | `cd apps/mobile && flutter test integration_test --name "@<ID>-"` |
| Escenarios de una card, API | `cd apps/api && pytest tests/escenarios --card <ID>`: un hook de `conftest.py` filtra por el tag del docstring. Lo crea la primera card |
| Suite entera de escenarios (el gate) | `cd apps/mobile && flutter test integration_test` y `cd apps/api && pytest tests/escenarios` |
| Capturas del paso 9 | `cd apps/mobile && flutter test test/capturas --tags capturas --update-goldens`; el tag `capturas` queda excluido de la corrida por defecto en `dart_test.yaml` |

Los escenarios de la app corren contra un emulador de Android con la API levantada localmente y
una base propia de la corrida. Sin emulador, esos escenarios son **no se pudo correr**.

## Equivalencias de lo que el método nombra en web

| El método dice | Acá es |
|---|---|
| `getByRole("button", { name })` | `find.bySemanticsLabel('…')` o `find.widgetWithText(FilledButton, '…')`. `find.byKey` sólo cuando no hay texto ni semántica, con un comentario |
| `TimeoutError`, `resolved to 0 elements`, `strict mode violation` | `The finder "…" (used in a call to "tap()") could not find any matching widgets` y `Too many elements` |
| `waitForTimeout` prohibido | `tester.pump(Duration(...))` como espera prohibida; se usa `pumpAndSettle` o un `expect` que espera |
| `axe` por vista | `expectLater(tester, meetsGuideline(androidTapTargetGuideline))`, `labeledTapTargetGuideline` y `textContrastGuideline` en cada pantalla |
| `required` / `aria-required` | la etiqueta del campo dice que es obligatorio y el `Semantics` lo anuncia |
| Build de producción | `flutter build apk --release` |
| 1280 y 390 px | dos teléfonos: 360×800 y 430×932 |
| `as any`, `@ts-ignore`, `!` | en Dart `!`, `as dynamic`, `// ignore:`, `catch (_) {}`; en Python `# type: ignore`, `# noqa`, `except: pass`, `cast(` |
| `strict` y `noUncheckedIndexedAccess` | `analysis_options.yaml` con `strict-casts`, `strict-inference` y `strict-raw-types`; `mypy --strict` |
