# Tasks: TP-01 · Página inicial (Home)

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/inicio/home_test.dart`.

## Phase 1: API

- [x] T001 Sin cambios: el Home reusa `GET /reservas?cuando=proximas`, `GET /espacios/catalogo`
  y `GET /sedes`, ya existentes y ya probados por otras cards.

## Phase 2: App (TP-01-H01-01 a H03-01)

- [x] T002 Cabecera con saludo y nombre, hero con sedes/canchas de los datos cargados (H01-01,
  H01-05)
- [x] T003 Bloque «Tu próxima reserva» con `TarjetaReserva` reusada, «Ver todas» a Mis reservas,
  y sin bloque si no hay ninguna (H01-02, H01-04, H02-01)
- [x] T004 Modificar y cancelar desde el Home, recargando al volver (H01-03)
- [x] T005 Chips de DEPORTES y accesos rápidos existentes (H01-06)
- [x] T006 Barra inferior y tarjeta del avatar (H01-07, H01-08) — ya existían, sólo escenario
  nuevo
- [x] T007 Redirección del administrador al panel (H03-01) — ya existía (`Perfil.inicio`), sólo
  escenario nuevo

## Phase 3: Polish

- [x] T008 `inicioFalso` en `test/soporte/montar.dart` y su uso en accesibilidad y capturas
- [x] T009 Capturas del paso 9 (360/430 × claro/oscuro) del Home y la tarjeta de cuenta
- [x] T010 `scripts/test.sh` y `scripts/e2e.sh integration_test/inicio/home_test.dart` en verde

## Dependencies

T001 → T002 → T003 → T004 → T005–T007 → T008–T010.
