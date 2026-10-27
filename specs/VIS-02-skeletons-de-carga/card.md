# VIS-02 · las pantallas cargan con skeletons con la forma del contenido

status: proposed
cap: 2 h
sources:
  - "pedido (texto) · mensaje del usuario en la sesión (2026-10-27): «y otra cosa, a las pantallas de carga le podes poner skeletons?»"
  - "repo · apps/mobile/lib/comun/carga_de_lista.dart (`EsperaDeLista`: un spinner centrado), usado en inicio/pantalla_inicio.dart, reservas/pantalla_mis_reservas.dart, sedes/pantalla_sedes.dart, admin/listado_admin.dart; spinners sueltos de carga de pantalla en notificaciones/pantalla_notificaciones.dart, sedes/pantalla_sede.dart, reservas/pantalla_horarios.dart, reservas/pantalla_buscar_cancha.dart, admin/cuerpo_del_panel_admin.dart; los spinners dentro de botones y la espera de arranque no son carga de contenido"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "a las pantallas de carga le podes poner skeletons?" · acceptance: mientras una pantalla carga su contenido, en lugar del spinner centrado muestra skeletons con la forma del contenido que va a aparecer: tarjetas de sede en Sedes, tarjetas de cancha en la sede, la grilla de horarios en Horarios, tarjetas de reserva en Mis reservas, en el inicio y en el panel de administración, y avisos en Notificaciones; bloques grises con la forma (tamaño, radio, separación) de la tarjeta real, con los colores de superficie de la paleta en modo claro y oscuro
- S2 · "skeletons" · acceptance: los skeletons tienen un brillo suave que recorre los bloques; con «reducir movimiento» activo el brillo no se mueve; para un lector de pantalla la zona dice «Cargando» una sola vez, no lee los bloques
- VIS-02-ASM-01 · los spinners dentro de botones (enviando), el del nombre generado y la espera de arranque verde quedan como están: no son carga de una lista ni de una pantalla · S1
- VIS-02-ASM-02 · el skeleton es un componente de `comun/` reutilizable (un bloque y su brillo) que cada pantalla compone con la forma de su tarjeta; sin paquete nuevo · S1

## Tasks

- T1 · S1,S2,VIS-02-ASM-01,VIS-02-ASM-02 · apps/mobile/lib/comun/esqueleto.dart (presentation), apps/mobile/lib/comun/carga_de_lista.dart (presentation), apps/mobile/lib/inicio/pantalla_inicio.dart (presentation), apps/mobile/lib/reservas/pantalla_mis_reservas.dart (presentation), apps/mobile/lib/sedes/pantalla_sedes.dart (presentation), apps/mobile/lib/sedes/pantalla_sede.dart (presentation), apps/mobile/lib/reservas/pantalla_horarios.dart (presentation), apps/mobile/lib/reservas/pantalla_buscar_cancha.dart (presentation), apps/mobile/lib/notificaciones/pantalla_notificaciones.dart (presentation), apps/mobile/lib/admin/listado_admin.dart (presentation), apps/mobile/lib/admin/cuerpo_del_panel_admin.dart (presentation) · tests: apps/mobile/test/esqueletos_de_carga_test.dart "cada pantalla que carga muestra skeletons con la forma de su contenido y no un spinner @VIS-02-S1 @assumption:VIS-02-ASM-02"; apps/mobile/test/esqueletos_de_carga_test.dart "el brillo se detiene con reducir movimiento y el lector anuncia Cargando una vez @VIS-02-S2"; apps/mobile/test/esqueletos_de_carga_test.dart "los spinners de botones y la espera de arranque siguen igual @assumption:VIS-02-ASM-01"
  new: apps/mobile/lib/comun/esqueleto.dart: no había un componente de skeleton

## Changes to existing behavior

- las pantallas que cargan contenido muestran skeletons en vez de un spinner centrado

## Gate

```
suite [timeout 1 h]: sh D:/Temp/w/herramientas/flutter-mobile.sh
fmt: D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test/esqueletos_de_carga_test.dart
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
refactor-tests: la espera de lista deja de ser un spinner y pasa a ser bloques `Esqueleto`; los tests que buscaban `CircularProgressIndicator` buscan `Esqueleto`
```

## Log

- L1 · y otra cosa, a las pantallas de carga le podes poner skeletons?
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
