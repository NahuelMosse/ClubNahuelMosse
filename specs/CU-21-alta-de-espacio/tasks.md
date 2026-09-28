# Tasks: CU-21 · Alta de espacio deportivo

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/espacios/alta_espacio_test.dart`
y `apps/api/tests/escenarios/test_alta_espacio.py`.

## Phase 1: Setup

- [x] T001 Soporte de escenarios: elegir cualquier opción, cargar sedes y espacios como otro administrador, ver los espacios de un usuario

## Phase 2: API

- [x] T002 Catálogo y `validar_espacio` con sus unitarios
- [x] T003 `nombre_sugerido` y `dar_de_alta_espacio` con sus unitarios
- [x] T004 `EspaciosSql` y los cuatro endpoints, con sus tests contra la base y el emulador (H01-03)

## Phase 3: App (CU-21-H01-01 a H04-01)

- [x] T005 Listado del panel (H01-01, H01-04)
- [x] T006 Formulario con tipo dependiente del deporte y vista previa del nombre (H01-02, H03-01)
- [x] T007 Número tomado por otro alta: aviso y número siguiente (H02-01)
- [x] T008 Errores de conexión, servidor y sesión vencida (H04-01)

## Phase 4: Polish

- [x] T009 Tests de widget, accesibilidad y capturas del paso 9
- [x] T010 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T003 → T004 → T005 → T006–T008 → T009–T010.
