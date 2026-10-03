# Tasks: CU-14 · Historial global de reservas (admin)

**Input**: `plan.md`
**Tests**: los escenarios de app están congelados en
`apps/mobile/integration_test/reservas/historial_global_test.dart`; el de permisos de API en
`apps/api/tests/escenarios/test_historial_reservas.py`.

## Phase 1: API

- [x] T001 `GET /reservas/todas` y `GET /reservas/todas/{id}` con sus tests de integración
      (paginación, filtros, rango inválido, permisos)

## Phase 2: App (CU-14-H01-01 a H09-01, sin H01-07 ni H08-01)

- [x] T002 Listado con pestañas de estado, contador y scroll perezoso (H01-01, H01-02, H01-03,
      H01-09)
- [x] T003 Panel de Filtros (sede, deporte, estado, rango) y búsqueda combinada (H01-04, H01-05,
      H04-01)
- [x] T004 Detalle de sólo lectura con trazabilidad, y volver conservando filtros (H01-06, H01-08)
- [x] T005 Estados vacío y sin resultados, error de red, sesión vencida, acceso denegado (H02-01,
      H03-01, H05-01, H06-01, H07-01)
- [x] T006 Reserva de un espacio dado de baja marcada en el historial (H09-01)

## Phase 3: Polish

- [x] T007 Tests de widget, accesibilidad y capturas del paso 9: scroll infinito sin trabarse ni
      repetir, detalle que relee lo vigente, nombres accesibles de «Volver» y «Cerrar», fecha
      inválida en Filtros
- [x] T009 Tests de integración de API: corte de días en la hora del club (21:00 y 23:00) y
      comodines de la búsqueda como texto
- [ ] T008 `scripts/test.sh` y el e2e del archivo en verde

## Dependencies

T001 → T002 → T003 → T004 → T005 → T006 → T007–T008.
