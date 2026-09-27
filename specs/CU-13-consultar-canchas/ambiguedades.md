# Ambigüedades — CU-13 · Consultar canchas

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card dice: «No hay canchas disponibles para este horario» y permite modificar los filtros sin perder el contexto (FA1)
| Duplicados    | no aplica: es una consulta
| Validación    | la card dice: fecha y horario futuros, horas completas, duración mínima de una hora y dentro del funcionamiento de la sede (paso 2, FA2); no dice si hay duración máxima → CU-13-AMB-01
| Error         | la card dice: FA3 error de conexión con reintento conservando filtros, FA4 error de servidor sin mostrar resultados desactualizados
| Estado        | la card dice «espacios deportivos activos»; no dice qué pasa con los inactivos o dados de baja → CU-13-AMB-02
| Permisos      | la card dice: usuario autenticado
| Límites       | la card no dice hasta cuántos días hacia adelante se puede consultar → CU-13-AMB-03
| Orden         | la card no dice en qué orden van las canchas disponibles → CU-13-AMB-04
| Concurrencia  | la card no dice qué pasa si la cancha mostrada como disponible se reserva antes de que el usuario llegue a confirmar → CU-13-AMB-05
| Rastro        | no aplica: consulta de solo lectura

## Eventos
CU-13-AMB-01 · 2026-09-27 · abierta · ¿hay duración máxima por reserva? El prototipo dice «de 1 a 4 horas»; el enunciado sólo pone el cierre de la sede como tope
CU-13-AMB-02 · 2026-09-27 · abierta · ¿las canchas dadas de baja o las de sedes dadas de baja quedan fuera de la consulta?
CU-13-AMB-03 · 2026-09-27 · abierta · ¿con cuánta anticipación máxima se puede consultar y reservar?
CU-13-AMB-04 · 2026-09-27 · abierta · ¿en qué orden se listan las canchas disponibles?
CU-13-AMB-05 · 2026-09-27 · abierta · si la cancha se ocupa entre la consulta y la confirmación, ¿se resuelve en CU-09 FA1 (horario ya reservado)?
CU-13-AMB-06 · 2026-09-27 · abierta · ¿elegir una cancha lleva directo a confirmar la reserva con el rango consultado (CU) o a la grilla de horarios (prototipo)?
CU-13-AMB-07 · 2026-09-27 · abierta · ¿el filtro por tipo es opcional («Todos los tipos» del prototipo) o obligatorio (paso 2 del CU)? ¿sede y deporte son obligatorios?
CU-13-AMB-08 · 2026-09-27 · abierta · ¿un rango que empieza en la hora en curso (por ejemplo 18:00 consultado a las 18:20) es válido?
CU-13-AMB-09 · 2026-09-27 · abierta · ¿cuáles son los deportes y tipos del club: los del prototipo (fútbol, tenis, hockey, vóley, golf) o también pádel y básquet?
CU-13-AMB-00 · 2026-09-27 · snapshot · congelado en 3a14f30
CU-13-AMB-00 · 2026-09-27 · snapshot · congelado en 4b2b10f
