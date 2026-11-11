# VIS-04 · el troquel sin muescas y el estado vacío sin aro punteado

status: proposed
cap: 90 min
sources:
  - "pedido (texto) · user, session 2026-11-10, sobre capturas del Figma `zCsUSxyy2QjwEJ7AyR6XWt` (tarjeta de reserva y estado vacío): «esa nmueca que le hiciste queda mal con el borde gris» · «lo mismo con el borde verde» · «banco los puntos sueltos, los que rodean en circulo no, saca esas rayitas y puntos» · «y a este icono tambien sacale esa decoracion de rayitas» · «a este tambien»"
  - "repo · apps/mobile/lib/common/die_cut.dart, empty_state.dart; specs/RED-02-componentes-identidad/card.md S7"
not_read:
  - "no hay Jira: no hay comentarios, adjuntos ni enlaces que leer"

## Specs

- S1 · "esa nmueca que le hiciste queda mal con el borde gris" · acceptance: el troquel de la tarjeta de reserva y del comprobante no dibuja muescas a los lados, así que el borde gris de la tarjeta queda entero; vale igual para el borde verde de la reserva activa ("lo mismo con el borde verde")
- S2 · "banco los puntos sueltos, los que rodean en circulo no" · acceptance: la línea punteada del troquel queda, en `borderControl`
- S3 · "y a este icono tambien sacale esa decoracion de rayitas" · acceptance: el ícono del estado vacío va en un círculo liso, sin aro punteado ni línea que lo cruce
- VIS-04-ASM-01 · «los que rodean en círculo» son las dos muescas del troquel (lo único circular de la tarjeta de la captura); el aro y las chispas del festejo de reserva confirmada no aparecen en las capturas y quedan como están · S1

## Tasks

- T1 · S1,S2,S3,VIS-04-ASM-01 · apps/mobile/lib/common/die_cut.dart (presentation), apps/mobile/lib/features/bookings/presentation/booking_card.dart (presentation), apps/mobile/lib/features/bookings/presentation/booking_receipt.dart (presentation), apps/mobile/test/redesign/components_test.dart, apps/mobile/test/redesign/screens_test.dart, apps/mobile/test/redesign/die_cut_without_notches_test.dart · `DieCut` y `DieCutPainter` pierden las muescas y el color de fondo que sólo las pintaba; la línea punteada va de borde a borde con el mismo margen · tests: apps/mobile/test/redesign/die_cut_without_notches_test.dart "the die-cut draws only the dotted line, with no notch on either side @VIS-04-S1 @VIS-04-S2"; apps/mobile/test/redesign/die_cut_without_notches_test.dart "the empty-state icon sits in a plain circle, with no dashed ring and no line across it @VIS-04-S3"; apps/mobile/test/redesign/die_cut_without_notches_test.dart "the confirmed-booking celebration keeps its dotted ring and its sparks @assumption:VIS-04-ASM-01"
  reuses: apps/mobile/lib/common/die_cut.dart DieCut, DieCutPainter (se recortan; nada nuevo)

## Changes to existing behavior

- tarjeta de reserva y comprobante de reserva confirmada: el troquel deja de tener las dos muescas · apps/mobile/test/redesign/components_test.dart "the die-cut draws the dotted line and the two notches and the screen reader does not read it @RED-02-S7" y apps/mobile/test/redesign/screens_test.dart "the booking card separates header and detail with the die-cut @RED-03-S2" afirman las muescas o su color: se ajustan en el lugar (refactor-tests)
- estado vacío: sin cambio en la app (ya era un círculo liso); el aro punteado y la línea estaban sólo en el Figma, que se corrigió aparte
- las capturas de `apps/mobile/test/screenshots/` que muestran una tarjeta de reserva o el comprobante cambian

## Look

- remove-only: las dos muescas del troquel

## Gate

```
suite [timeout 30 min]: sh D:/Temp/w/herramientas/vis04-affected.sh
screenshots [timeout 120 min]: sh D:/Temp/w/herramientas/eng23-screenshots.sh
fmt: D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib/common/die_cut.dart apps/mobile/lib/features/bookings/presentation/booking_card.dart apps/mobile/lib/features/bookings/presentation/booking_receipt.dart apps/mobile/test/redesign/die_cut_without_notches_test.dart apps/mobile/test/redesign/components_test.dart apps/mobile/test/redesign/screens_test.dart
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
refactor-tests: `DieCut` pierde el parámetro `background` y `DieCutPainter` sus campos `background` y `notchDiameter`; los dos tests congelados que los nombran (RED-02-S7, RED-03-S2) dejan de pasarlos y de afirmar las muescas, que esta card quita (S1); lo demás que verifican (la línea en `borderControl`, el lector que no lo lee, el troquel entre cabecera y detalle) no cambia
no-docs: la card quita un adorno; ninguna regla, contrato ni dato cambia; el módulo docs está apagado
```

## Log

- L1 · 2026-11-10 · «esa nmueca que le hiciste queda mal con el borde gris» (captura de la tarjeta de reserva con borde gris) · «lo mismo con el borde verde» (la reserva activa) · «banco los puntos sueltos, los que rodean en circulo no, saca esas rayitas y puntos» · «y a este icono tambien sacale esa decoracion de rayitas» (estado vacío, aro punteado lima con una línea horizontal) · «a este tambien» (estado vacío con la lupa)
- L2 · 2026-11-10 · las capturas son del Figma `zCsUSxyy2QjwEJ7AyR6XWt`: ahí se quitaron las muescas de las 8 variantes de `Card-Reserva` y de los 3 comprobantes, y el trazo punteado y la «Media cancha» de los dos `IconCircle` de `Empty-State`; la línea punteada del troquel queda
- L3 · 2026-11-10 · replaces: apps/mobile/test/redesign/components_test.dart "the die-cut draws the dotted line and the two notches and the screen reader does not read it @RED-02-S7" · el troquel ya no tiene muescas (S1) · by: apps/mobile/test/redesign/components_test.dart "the die-cut draws the dotted line and the screen reader does not read it @RED-02-S7"
