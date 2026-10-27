# SIM-03 · la app se lee fácil y hace lo mismo

status: proposed
cap: 6 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «tambien quiero que limpies el codigo, porque creo que esta muy sucio, dificil de leer» · «de funcionalidad no sacaria nada» · «quedas solo toda la noche, simplifica sin sacar fucionalidad y deja todo mas organizado»"
  - "relevamiento · plan del planner sobre apps/mobile/lib (2026-10-27): 175 archivos y 21 290 líneas; los build más largos tienen 242, 216, 182 y 159 líneas (tarjeta_reserva, pantalla_filtros_reservas, pantalla_panel_admin, pantalla_reserva_confirmada); app.dart 627 líneas con el router dentro del State; comun/movimiento.dart 648 líneas con siete widgets; 41 archivos con los imports desordenados; 4 parámetros booleanos posicionales; `paginaQueSube` sin uso; ClienteApi repite post, put, delete y get"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "simplifica sin sacar fucionalidad" · acceptance: la app hace y muestra lo mismo: la suite de la app y las capturas pasan sin regenerar ninguna
- S2 · "deja todo mas organizado" · acceptance: `flutter analyze` pasa con `directives_ordering` y `avoid_positional_boolean_parameters`, el código está formateado con `dart format`, ninguna función de lib pasa de 80 líneas, y el router de la app vive fuera de app.dart
- S3 · "limpies el codigo, porque creo que esta muy sucio, dificil de leer" · acceptance: no queda código sin uso en lib (`paginaQueSube`) y el análisis ya no excluye un test que se arregló
- SIM-03-ASM-01 · las piezas que salen de un build largo van a archivos propios del mismo módulo: un `pantalla_*.dart` declara sólo su widget y su State (lo exige `limpieza_plan_test.dart` de ARQ-03) · S2
- SIM-03-ASM-02 · `comun/movimiento.dart` queda como índice que reexporta, con `show`, los widgets que pasan a `comun/movimiento/`; así los imports de la app y de los tests no cambian · S2
- SIM-03-ASM-03 · el tope de 80 líneas cuenta también los `build`: es el doble del de la API porque un árbol de widgets se lee de arriba abajo · S2

## Tasks

- T1 · S2,S3,SIM-03-ASM-03 · apps/mobile/analysis_options.yaml, apps/mobile/test/codigo_legible_test.dart, apps/mobile/lib/comun/transiciones.dart (presentation) · tests: apps/mobile/test/codigo_legible_test.dart "el análisis de la app pide imports ordenados y ningún booleano posicional, y no excluye tests arreglados @SIM-03-S2 @SIM-03-S3"; apps/mobile/test/codigo_legible_test.dart "ninguna función de lib pasa de 80 líneas, build incluido @SIM-03-S2 @assumption:SIM-03-ASM-03"; apps/mobile/test/codigo_legible_test.dart "no queda paginaQueSube ni otro código sin uso en lib @SIM-03-S3"
  reuses: apps/mobile/analysis_options.yaml, con las reglas que ya tiene
- T2 · S1,S2,SIM-03-ASM-02 · apps/mobile/lib/comun/movimiento.dart (presentation), apps/mobile/lib/comun/dialogo_error.dart (presentation) · tests: apps/mobile/test/codigo_legible_test.dart "movimiento.dart reexporta sus widgets desde comun/movimiento sin cambiar los imports @assumption:SIM-03-ASM-02"
  reuses: los widgets existentes de apps/mobile/lib/comun/movimiento.dart y apps/mobile/lib/comun/dialogo_error.dart, movidos sin cambios
- T3 · S2 · apps/mobile/lib/app.dart (presentation) · tests: apps/mobile/test/codigo_legible_test.dart "el router de la app vive fuera de app.dart @SIM-03-S2"
  reuses: las rutas y el redirect de apps/mobile/lib/app.dart, movidos a su propio archivo
- T4 · S1,S2,SIM-03-ASM-01 · apps/mobile/lib/reservas/tarjeta_reserva.dart (presentation), apps/mobile/lib/admin/pantalla_filtros_reservas.dart (presentation), apps/mobile/lib/admin/pantalla_panel_admin.dart (presentation), apps/mobile/lib/reservas/pantalla_reserva_confirmada.dart (presentation), apps/mobile/lib/sesion/tarjeta_cuenta.dart (presentation), apps/mobile/lib/admin/pantalla_alta_espacio.dart (presentation) · tests: apps/mobile/test/codigo_legible_test.dart "las piezas de un build largo viven en archivos propios del módulo @assumption:SIM-03-ASM-01"; apps/mobile/test/codigo_legible_test.dart "la app muestra lo mismo: las capturas se comparan sin regenerarlas @SIM-03-S1"
  reuses: los widgets de cada pantalla, partidos en piezas con nombre

## Changes to existing behavior

- none: ninguna pantalla cambia lo que muestra ni lo que hace

## Gate

```
suite: sh D:/Temp/w/herramientas/flutter-mobile.sh
captures: sh D:/Temp/w/herramientas/arq03-capturas.sh
fmt: D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
no-visual: la card parte widgets en archivos y piezas con nombre sin cambiar lo que muestra una pantalla; las capturas se comparan sin regenerarlas
no-docs: refactor interno de la app; el comportamiento, el contrato y el modelo de datos no cambian
refactor-tests: los diálogos de baja de sede y de espacio pasan a admin/ y el de cancelación a reservas/; los tests que los importaban de comun/dialogo_error.dart cambian sólo esa línea
```

## Log

- L1 · tambien quiero que limpies el codigo, porque creo que esta muy sucio, dificil de leer · de funcionalidad no sacaria nada · quedas solo toda la noche, simplifica sin sacar fucionalidad y deja todo mas organizado
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base: sólo la app
- L3 · 2026-10-27 · declared · attacks · la card no cambia la API; de ClienteApi cambia sólo cómo arma el pedido, y lo cuidan rutas_de_la_api_test.dart y operacion_cliente*_test.dart en la línea `suite`
- L4 · 2026-10-27 · ClienteApi sale de esta card: era la única pieza que tocaba el borde con la API (lente de contrato) y su ganancia es chica; queda para cuando haya que tocarlo
- L5 · 2026-10-27 · T1 · flutter analyze --no-pub: No issues found; codigo_legible_test pasa «análisis», «paginaQueSube» y «capturas sin regenerar»; `dart fix` reordenó imports de lib (los tests congelados quedan intactos: test/analysis_options.yaml apaga directives_ordering, avoid_positional_boolean_parameters y curly_braces_in_flow_control_structures sólo en test/)
- L6 · 2026-10-27 · T2 (movimiento) · comun/movimiento.dart es un índice con `export … show`; siete widgets en comun/movimiento/; analyze limpio y «movimiento.dart reexporta» en verde
- L7 · 2026-10-27 · OUT · T2 (dialogo_error) sin hacer: interfaz_accesible_test y movimiento_pantallas_test (congelados) llaman confirmarBajaDeSede, confirmarBajaDeEspacio y confirmarCancelacion importando comun/dialogo_error.dart; moverlos obliga a cambiar esos imports
- L8 · 2026-10-27 · card · la prueba de 80 líneas encuentra ~30 funciones largas, no las 6 de T4 (ej. dialogo_anular_reserva:59, pantalla_detalle_reserva:85, pantalla_editar_espacio:179, pantalla_formulario_sede:386, tarjeta_reserva_admin:47, ficha_socio:28, resultado:53, panel_avisos:126, pantalla_horarios:338, hero_de_inicio:31); T4 queda corta
- L9 · 2026-10-27 · decisión sobre L7 y L8: los diálogos específicos salen de comun/ hacia admin/ y reservas/ (comun no importa features), con `refactor-tests:` para la línea de import de los tests congelados; T4 abarca todas las funciones de más de 80 líneas que marca el test, y sus archivos se suman a la línea T4 cuando queden partidas
