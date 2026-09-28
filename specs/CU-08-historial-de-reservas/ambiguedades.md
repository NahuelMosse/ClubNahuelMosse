# Ambigüedades — CU-08 · Consultar historial de reservas

Doble lectura (épica de reservas): dos lecturas independientes que no se vieron entre sí, más la
propia. Coincidieron en los dos flujos, en la falta de flujos de error, en el choque de canceladas
contra el badge y en el orden sin sentido declarado. Divergencias:
- Una marcó Duplicados como pregunta (dos reservas idénticas en el historial); la otra, como no
  aplica.
- Una preguntó por auditoría de la consulta; la otra lo dio por no aplica.
La lectura propia agregó ANULADA del prototipo y las acciones de las tarjetas.

## Las diez preguntas
| Caso vacío    | la card dice: «No se encontraron reservas asociadas a su cuenta» (FA1); el diseño separa próximas y pasadas
| Duplicados    | no aplica: es una consulta; dos reservas iguales no pueden existir por la regla de no superposición
| Validación    | la card dice: «El sistema valida la sesión»; no dice qué pasa con la sesión vencida → CU-08-AMB-01
| Error         | la card no lo dice; el enunciado exige sin conexión y servidor caído → CU-08-AMB-02
| Estado        | la card dice Activa y Completada; el objetivo nombra canceladas y el prototipo, anuladas → CU-08-AMB-03
| Permisos      | la card dice: «El sistema consulta las reservas asociadas al usuario»
| Límites       | la card no dice si el historial se pagina ni hasta qué antigüedad llega → CU-08-AMB-04
| Orden         | la card dice «ordenadas por fecha» sin decir el sentido → CU-08-AMB-05
| Concurrencia  | no aplica: consulta de solo lectura
| Rastro        | no aplica: la consulta no estampa nada; lo que el historial necesita mostrar se estampa en CU-09, CU-10 y CU-15

## Eventos
CU-08-AMB-01 · 2026-09-27 · abierta · con la sesión vencida al abrir Mis reservas, ¿«Tu sesión expiró» y al login?
CU-08-AMB-02 · 2026-09-27 · abierta · sin conexión o con el servidor caído, ¿overlays compartidos y ningún dato parcial?
CU-08-AMB-03 · 2026-09-27 · abierta · ¿qué estados aparecen en el historial (completada, cancelada por el usuario, anulada por el administrador) y con qué etiqueta?
CU-08-AMB-04 · 2026-09-27 · abierta · ¿el historial tiene paginación o un límite de antigüedad?
CU-08-AMB-05 · 2026-09-27 · abierta · ¿Próximas va de la más cercana a la más lejana y el historial de la más reciente a la más vieja?
CU-08-AMB-06 · 2026-09-27 · abierta · una reserva en curso (empezó y no terminó), ¿va en Próximas o en Historial?
CU-08-AMB-07 · 2026-09-27 · abierta · ¿una cancelada con fecha futura va al historial (CU-10) o queda en Próximas marcada?
CU-08-AMB-00 · 2026-09-27 · snapshot · congelado en 6f7c5d8
CU-08-AMB-02 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-08-AMB-02 · 2026-09-27 · resuelta · se usan los overlays compartidos del prototipo en toda la app (decisión 11)
CU-08-AMB-03 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-08-AMB-03 · 2026-09-27 · resuelta · estados Activa, Completada, Cancelada (por el usuario) y Anulada (por el club, con motivo) (decisión 3)
CU-08-AMB-08 · 2026-09-28 · abierta · el prototipo pone MODIFICAR y CANCELAR en cada próxima: ¿van en esta card?
CU-08-AMB-09 · 2026-09-28 · abierta · ¿qué dice una cancelada o una anulada debajo de la fecha?
CU-08-AMB-10 · 2026-09-28 · abierta · ¿el precio de la tarjeta es el total de la reserva, el del momento en que se hizo, o el precio actual del espacio?
CU-08-AMB-01 · 2026-09-28 · vencida → CU-08-SUP-01 · con la sesión vencida, el overlay «Tu sesión expiró» y al inicio de sesión, como en el resto de la app
CU-08-AMB-04 · 2026-09-28 · vencida → CU-08-SUP-02 · sin paginación ni límite de antigüedad: el historial de una persona es corto y se lee entero
CU-08-AMB-05 · 2026-09-28 · vencida → CU-08-SUP-03 · Próximas de la más cercana a la más lejana; Historial de la más reciente a la más vieja
CU-08-AMB-06 · 2026-09-28 · vencida → CU-08-SUP-04 · una reserva en curso sigue en Próximas como ACTIVA hasta que termina; ahí pasa a COMPLETADA en el Historial
CU-08-AMB-07 · 2026-09-28 · vencida → CU-08-SUP-05 · una cancelada o anulada va al Historial aunque su horario sea futuro: ya no es una próxima reserva
CU-08-AMB-08 · 2026-09-28 · vencida → CU-08-SUP-06 · MODIFICAR y CANCELAR llegan con CU-11 y CU-10; esta card muestra las tarjetas sin acciones
CU-08-AMB-09 · 2026-09-28 · vencida → CU-08-SUP-07 · como el prototipo (decisión 12): «Cancelada por vos · el horario quedó liberado» y «Anulada por el administrador · <motivo>»
CU-08-AMB-10 · 2026-09-28 · vencida → CU-08-SUP-08 · el total que se guardó al reservar (decisión 4), aunque después cambie el precio del espacio
CU-08-TESTS · 2026-09-28 · congelados en f17d8d3 · 9 escenarios en rojo porque Mis reservas es una pantalla vacía: no pide las reservas ni tiene Próximas e Historial
CU-08-AMB-11 · 2026-09-28 · abierta · el inicio del prototipo tiene «TU PRÓXIMA RESERVA · VER TODAS →» (37:147): ¿va en esta card?
CU-08-AMB-11 · 2026-09-28 · vencida → CU-08-SUP-09 · la tarjeta del inicio es de TP-01, que arma el inicio completo; esta card entrega la sección Mis reservas y la lectura de la próxima reserva que esa tarjeta va a usar
