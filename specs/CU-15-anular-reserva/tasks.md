# Tareas — CU-15 · Anular reserva (admin)

- [x] Supuestos CU-15-SUP-01 a SUP-08 en `ambiguedades.md`.
- [x] Soporte e2e: `cancelarProximasDe`, `reservaQueVeElAdmin`, `historialDe`.
- [x] Escenarios: 8 de app (10 casos) y 1 de API, congelados.
- [x] API: `ReservaHistorial.anulable`, `Reservas.anular`, `anular_reserva`, `ReservasSql.anular`.
- [x] API: `POST /reservas/{id}/anular` con 403, 404, 409 y 422.
- [x] API: tests de integración (rastro, horario libre, repetición, rechazos, concurrencia).
- [x] App: `HistorialDeReservas.anular` y `ReservaHistorial.anulable`.
- [x] App: confirmación con motivo y flujo de anulación con reintento.
- [x] App: ANULAR RESERVA en la tarjeta del listado y en el detalle.
- [x] App: widget tests, incluido texto al 200 % en 360 de ancho.
- [x] App: capturas del paso 9 (goldens de 360 y 430, claro y oscuro).
- [ ] Pasada final: rojo de los escenarios en el emulador, e2e verdes y capturas contra Figma.
- [ ] Pasada final: revisión con oracle.
