# VIS-04 · el troquel sin muescas, el estado vacío sin aro punteado y el festejo sin aro

status: proposed
cap: 90 min
sources:
  - "pedido (texto) · user, session 2026-11-10, sobre capturas del Figma `zCsUSxyy2QjwEJ7AyR6XWt` (tarjeta de reserva y estado vacío): «esa nmueca que le hiciste queda mal con el borde gris» · «lo mismo con el borde verde» · «banco los puntos sueltos, los que rodean en circulo no, saca esas rayitas y puntos» · «y a este icono tambien sacale esa decoracion de rayitas» · «a este tambien»"
  - "pedido (texto) · user, session 2026-11-10, sobre una captura del festejo «¡A la cancha!» del mismo Figma: «este a la cancha de figma sigue ahi: mantene todo menos las rayitas y puntos que forman un circulo al rededor»"
  - "repo · apps/mobile/lib/common/die_cut.dart, empty_state.dart, motion/celebration.dart; specs/RED-02-componentes-identidad/card.md S7; specs/RED-04-movimiento/card.md S9"
not_read:
  - "no hay Jira: no hay comentarios, adjuntos ni enlaces que leer"

## Specs

- S1 · "esa nmueca que le hiciste queda mal con el borde gris" · acceptance: el troquel de la tarjeta de reserva y del comprobante no dibuja muescas a los lados, así que el borde gris de la tarjeta queda entero; vale igual para el borde verde de la reserva activa ("lo mismo con el borde verde")
- S2 · "banco los puntos sueltos, los que rodean en circulo no" · acceptance: la línea punteada del troquel queda, en `borderControl`
- S3 · "y a este icono tambien sacale esa decoracion de rayitas" · acceptance: el ícono del estado vacío va en un círculo liso, sin aro punteado ni línea que lo cruce
- S4 · "mantene todo menos las rayitas y puntos que forman un circulo al rededor" · acceptance: el festejo de la reserva confirmada deja de dibujar el aro punteado que giraba alrededor del ícono; las ocho chispas sueltas, el ícono, el grito y el comprobante quedan como estaban

## Tasks

- T1 · S1,S2,S3 · apps/mobile/lib/common/die_cut.dart (presentation), apps/mobile/lib/features/bookings/presentation/booking_card.dart (presentation), apps/mobile/lib/features/bookings/presentation/booking_receipt.dart (presentation), apps/mobile/test/redesign/components_test.dart, apps/mobile/test/redesign/screens_test.dart, apps/mobile/test/redesign/die_cut_without_notches_test.dart · `DieCut` y `DieCutPainter` pierden las muescas y el color de fondo que sólo las pintaba; la línea punteada va de borde a borde con el mismo margen · tests: apps/mobile/test/redesign/die_cut_without_notches_test.dart "the die-cut draws only the dotted line, with no notch on either side @VIS-04-S1 @VIS-04-S2"; apps/mobile/test/redesign/die_cut_without_notches_test.dart "the empty-state icon sits in a plain circle, with no dashed ring and no line across it @VIS-04-S3"
  reuses: apps/mobile/lib/common/die_cut.dart DieCut, DieCutPainter (se recortan; nada nuevo)
- T2 · S4 · apps/mobile/lib/common/motion/celebration.dart (presentation), apps/mobile/test/redesign/die_cut_without_notches_test.dart · `Celebration` pierde el pintor del aro y su giro; las chispas, sus tiempos y el resto del festejo no cambian · tests: apps/mobile/test/redesign/die_cut_without_notches_test.dart "the confirmed-booking celebration keeps its sparks, with no ring around them @VIS-04-S4"
  reuses: apps/mobile/lib/common/motion/celebration.dart Celebration (se recorta; nada nuevo)

## Changes to existing behavior

- tarjeta de reserva y comprobante de reserva confirmada: el troquel deja de tener las dos muescas · apps/mobile/test/redesign/components_test.dart "the die-cut draws the dotted line and the two notches and the screen reader does not read it @RED-02-S7" y apps/mobile/test/redesign/screens_test.dart "the booking card separates header and detail with the die-cut @RED-03-S2" afirman las muescas o su color: se ajustan en el lugar (refactor-tests)
- estado vacío: sin cambio en la app (ya era un círculo liso); el aro punteado y la línea estaban sólo en el Figma, que se corrigió aparte
- reserva confirmada: el festejo deja de tener los «aros que giran» de RED-04-S9; su test ("the confirmed booking celebrates once @RED-04-S9") mide el grito, el comprobante y que termina, no el aro, y no cambia
- las capturas de `apps/mobile/test/screenshots/` que muestran una tarjeta de reserva, el comprobante o el festejo cambian

## Look

- plain: la card saca las muescas del troquel y el aro del festejo y no trae look nuevo; la tarjeta, el comprobante y el festejo siguen con los estilos del repo (`Palette`, `borderControl`, `accentBase`)

## Gate

```
suite [timeout 30 min]: sh D:/Temp/w/herramientas/vis04-affected.sh
screenshots [timeout 120 min]: sh D:/Temp/w/herramientas/eng23-screenshots.sh
fmt: D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib/common/die_cut.dart apps/mobile/lib/common/motion/celebration.dart apps/mobile/lib/features/bookings/presentation/booking_card.dart apps/mobile/lib/features/bookings/presentation/booking_receipt.dart apps/mobile/test/redesign/die_cut_without_notches_test.dart apps/mobile/test/redesign/components_test.dart apps/mobile/test/redesign/screens_test.dart
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
refactor-tests: `DieCut` pierde el parámetro `background` y `DieCutPainter` sus campos `background` y `notchDiameter`; los dos tests congelados que los nombran (RED-02-S7, RED-03-S2) dejan de pasarlos y de afirmar las muescas, que esta card quita (S1); lo demás que verifican (la línea en `borderControl`, el lector que no lo lee, el troquel entre cabecera y detalle) no cambia. `Celebration` pierde su aro (S4): el test de VIS-04-ASM-01, que afirmaba el aro, pasa a afirmar que no está, con las mismas ocho chispas
no-docs: la card quita adornos; ninguna regla, contrato ni dato cambia; el módulo docs está apagado
```

## Log

- L1 · 2026-11-10 · «esa nmueca que le hiciste queda mal con el borde gris» (captura de la tarjeta de reserva con borde gris) · «lo mismo con el borde verde» (la reserva activa) · «banco los puntos sueltos, los que rodean en circulo no, saca esas rayitas y puntos» · «y a este icono tambien sacale esa decoracion de rayitas» (estado vacío, aro punteado lima con una línea horizontal) · «a este tambien» (estado vacío con la lupa)
- L2 · 2026-11-10 · las capturas son del Figma `zCsUSxyy2QjwEJ7AyR6XWt`: ahí se quitaron las muescas de las 8 variantes de `Card-Reserva` y de los 3 comprobantes, y el trazo punteado y la «Media cancha» de los dos `IconCircle` de `Empty-State`; la línea punteada del troquel queda
- L3 · 2026-11-10 · replaces: apps/mobile/test/redesign/components_test.dart "the die-cut draws the dotted line and the two notches and the screen reader does not read it @RED-02-S7" · el troquel ya no tiene muescas (S1) · by: apps/mobile/test/redesign/components_test.dart "the die-cut draws the dotted line and the screen reader does not read it @RED-02-S7"
- L4 · 2026-11-10 · «este a la cancha de figma sigue ahi: mantene todo menos las rayitas y puntos que forman un circulo al rededor» (captura del festejo «¡A la cancha!»: el check en su círculo, un aro de rayas y otro de puntos lima alrededor, y puntos sueltos) · responde lo que VIS-04-ASM-01 había supuesto al revés: el aro del festejo también se va. En el Figma se borraron los «Aro 120» y «Aro 134» de los tres `Festejo`; quedan las chispas
- L5 · 2026-11-10 · replaces: apps/mobile/test/redesign/die_cut_without_notches_test.dart "the confirmed-booking celebration keeps its dotted ring and its sparks @assumption:VIS-04-ASM-01" · el festejo ya no tiene aro (S4, L4) · by: apps/mobile/test/redesign/die_cut_without_notches_test.dart "the confirmed-booking celebration keeps its sparks, with no ring around them @VIS-04-S4"
