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
CU-13-AMB-01 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-13-AMB-01 · 2026-09-27 · resuelta · duración de 1 a 4 horas y hasta 7 días de anticipación (decisión 6)
CU-13-AMB-03 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-13-AMB-03 · 2026-09-27 · resuelta · duración de 1 a 4 horas y hasta 7 días de anticipación (decisión 6)
CU-13-AMB-09 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-13-AMB-09 · 2026-09-27 · resuelta · cada cancha es un espacio; deporte y tipo salen de un catálogo fijo; el nombre lleva la altura, sin tildes ni espacios; el número no se reutiliza; el nombre no cambia si se edita la sede; el alta pide techada o al aire libre e iluminación (decisión 8)
CU-13-AMB-10 · 2026-09-28 · abierta · ¿cómo se ingresa la fecha para que una fecha pasada pueda escribirse (FA2) si el calendario sólo ofrece los próximos siete días? ¿qué opciones tienen DESDE y HASTA?
CU-13-AMB-11 · 2026-09-28 · abierta · el prototipo sólo trae «La fecha tiene que ser futura» y «La duración mínima es de una hora»: ¿qué dicen los otros errores de rango?
CU-13-AMB-12 · 2026-09-28 · abierta · ¿qué dice el encabezado de los resultados y qué hacen los chips «Todas · Al aire libre · Techada»?
CU-13-AMB-13 · 2026-09-28 · abierta · el prototipo muestra el error de la consulta en una tarjeta propia con VOLVER y REINTENTAR y con texto de conexión: ¿vale también para el error del servidor, o van los overlays compartidos?
CU-13-AMB-14 · 2026-09-28 · abierta · si se cambia un filtro después de consultar, ¿los resultados siguen a la vista?
CU-13-AMB-15 · 2026-09-28 · abierta · ¿desde dónde se entra: la sección Reservas (CU) o el acceso «Buscar cancha» del inicio (prototipo)?
CU-13-AMB-02 · 2026-09-28 · vencida → CU-13-SUP-01 · sólo se consultan los espacios activos de sedes activas (decisión 4)
CU-13-AMB-04 · 2026-09-28 · vencida → CU-13-SUP-02 · las canchas disponibles van por deporte, tipo y número, como en la sede (CU-16-SUP-04)
CU-13-AMB-05 · 2026-09-28 · vencida → CU-13-SUP-03 · el resultado no se refresca solo; si la cancha se ocupa antes de confirmar, lo resuelve CU-09 (393:6553)
CU-13-AMB-06 · 2026-09-28 · vencida → CU-13-SUP-04 · VER HORARIOS / RESERVAR, como el prototipo, abre la grilla de esa cancha con la fecha, la duración y la hora de inicio consultadas ya elegidas, así el horario consultado llega a la reserva sin volver a elegirlo
CU-13-AMB-07 · 2026-09-28 · vencida → CU-13-SUP-05 · sede, deporte, fecha, desde y hasta son obligatorios; el tipo es opcional y arranca en «Todos los tipos»; CONSULTAR queda deshabilitado mientras falte alguno
CU-13-AMB-08 · 2026-09-28 · vencida → CU-13-SUP-06 · un rango que ya empezó no es futuro (CU-12-SUP-04): consultado a las 18:20, las 18:00 no se aceptan
CU-13-AMB-10 · 2026-09-28 · vencida → CU-13-SUP-07 · FECHA se escribe DD/MM/AAAA o se elige en el calendario, que ofrece los próximos siete días (decisión 6); DESDE y HASTA ofrecen horas en punto, así que un minuto distinto de 00 no se puede elegir; HASTA 00:00 es la medianoche
CU-13-AMB-11 · 2026-09-28 · vencida → CU-13-SUP-08 · los errores van en su campo: FECHA «La fecha tiene que ser futura», «Elegí un día de los próximos 7» y «La sede no abre ese día»; DESDE «La sede abre a las HH:MM» y «El horario tiene que ser futuro»; HASTA «La duración mínima es de una hora», «La duración máxima es de 4 horas» y «La sede cierra a las HH:MM»
CU-13-AMB-12 · 2026-09-28 · vencida → CU-13-SUP-09 · el encabezado dice «N CANCHAS DISPONIBLES · TIPO · DESDE – HASTA» (el deporte si no se eligió tipo) o «SIN DISPONIBILIDAD · …»; el subtítulo pasa a «Sede · Tipo · Jue 12 nov · 18:00 a 19:00»; los chips filtran el resultado por condición sin volver a consultar, con la cuenta de cada una
CU-13-AMB-13 · 2026-09-28 · vencida → CU-13-SUP-10 · la tarjeta del prototipo (decisión 12) para los dos errores: «No se pudo consultar la disponibilidad» con «Revisá tu conexión e intentá nuevamente.» o «El servidor no respondió. Intentá más tarde.», más «Los filtros que cargaste se mantienen.»; VOLVER la cierra y REINTENTAR repite la consulta; los resultados anteriores se quitan
CU-13-AMB-14 · 2026-09-28 · vencida → CU-13-SUP-11 · al cambiar un filtro los resultados se quitan hasta volver a consultar, para no mostrar canchas de otra búsqueda como si fueran de ésta (FA4)
CU-13-AMB-15 · 2026-09-28 · vencida → CU-13-SUP-12 · se entra desde el inicio por «Buscar cancha · Por sede, fecha y horario», como el prototipo (37:147); la sección Reservas es el historial de CU-08
CU-13-TESTS · 2026-09-28 · congelados en 1d5ee15 · 10 escenarios en rojo porque el inicio no tiene el acceso «Buscar cancha» ni existe la consulta de canchas
CU-13-TESTS · 2026-09-28 · recongelados en d5d1b28 · la fecha se escribe y se muestra «DD / MM / AAAA», como en el prototipo (52:824) y en el registro; los escenarios la esperaban sin espacios
