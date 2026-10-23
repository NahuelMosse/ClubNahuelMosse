# Accesibilidad — REV-03 · Mis reservas, historial por tandas

Pantalla tocada: `apps/mobile/lib/reservas/pantalla_mis_reservas.dart`. Lo que cambia es sólo el
final de la lista del historial; la estructura, las pestañas y las tarjetas quedan como estaban.

- I23 · mientras llega la tanda siguiente se ve un `CircularProgressIndicator` al pie de la
  lista, y la lista que ya estaba sigue visible y desplazable.
- I10 · si la tanda siguiente falla (sin conexión o servidor caído) queda un botón de texto
  `REINTENTAR` al pie, con el mismo componente que el resto de la pantalla; las reservas ya
  cargadas no se quitan. Si la sesión venció, se muestra el aviso de sesión vencida de siempre.
- Lector de pantalla · las tarjetas de todas las tandas ya llegadas se construyen (no hay lista
  perezosa), así que se recorren por orden sin tener que deslizar; la tanda nueva se suma al
  final, sin mover el foco.
- La pantalla pide la tanda siguiente al acercarse al final del desplazamiento (a menos de 300
  px), sin botón: quien no desplaza no necesita pedirla, y con el lector de pantalla el
  desplazamiento hasta el final la trae.
- La tarjeta de una reserva cancelada con motivo lo muestra junto al texto fijo, igual que la
  anulada.
