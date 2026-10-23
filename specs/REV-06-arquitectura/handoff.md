# Handoff · REV-06 S5 · duplicación de la app

Alcance (corrección del coordinador): NO tocar `apps/api/app` (lo extrae REV-01). Sólo `apps/mobile/lib` bajo 3 % y las líneas `declared · K4` del Log.

## Hecho
- Nada de código queda: la prueba en `apps/api/app` se revirtió (árbol limpio).
- Medición previa: app 5,64 % (993 de 17605 líneas, 78 clones); hay que llegar a menos de 528 líneas duplicadas (apuntar a ~480).
- Mediciones: `npx -y jscpd@4 --silent --reporters json --output /tmp/rev06-jm apps/mobile/lib` y listar con `node D:/Temp/rev06-list.cjs D:/Temp/rev06-jm/jscpd-report.json` (script fuera del repo; el reporte sale en `D:\Temp\rev06-jm`).

## Pendiente (mayores clones, por ahorro estimado)
1. `comun/campo_texto.dart:112-149` = `comun/selector.dart:99-136` (38): extraer widget `MensajeDeCampo(mensaje)` (Semantics liveRegion + Row con ícono warning + texto).
2. `admin/pantalla_espacios_admin.dart` vs `pantalla_sedes_admin.dart` (32, 34, 16, 13), más `pantalla_panel_admin.dart` (20, 9).
3. `inicio/pantalla_inicio.dart` vs `reservas/pantalla_mis_reservas.dart` (26, 21, 15, 13, 11, 10, 11).
4. `reservas/pantalla_confirmar_cambio.dart` vs `pantalla_confirmar_reserva.dart` (9, 13, 16, 18, 11) y vs `sedes/pantalla_sede.dart` (25).
5. `admin/pantalla_alta_espacio.dart`, `pantalla_editar_espacio.dart`, `pantalla_formulario_sede.dart`, `pantalla_detalle_reserva.dart`, `comun/dialogo_error.dart`, `sesion/pantalla_nueva_contrasena.dart` vs `usuarios/pantalla_cambiar_contrasena.dart` (20, 15), `admin/historial_reservas.dart` vs `reservas/reservas.dart` (15, 16, 15).
6. Cada archivo de producción tocado va a la línea T4 de card.md con su capa `(presentation)`.
7. Clones de tests: los de apps/api/tests y apps/mobile/test con un lado congelado (con tags) se declaran al final de `## Log`: `- L<n> · declared · K4 · <archivo>:<líneas> · test congelado con tags, no se puede editar`; lista en `/tmp/gate-final-rev06.log` (líneas `required: failed: K4`, las de `tests/`). Si ningún lado está congelado, extraer a un módulo de soporte.

## Verificación
`flutter test` completo (PATH="/d/projects/flutter/bin:$PATH", en background, log único) incluyendo `test/capturas`; no correr verify; una línea de Log con porcentajes antes/después.
