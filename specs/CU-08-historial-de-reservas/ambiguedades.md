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
