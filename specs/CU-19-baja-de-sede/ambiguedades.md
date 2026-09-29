# Ambigüedades — CU-19 · Dar de baja sede

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | no aplica: se da de baja una sede que existe (precondición)
| Duplicados    | la card dice: si la sede ya fue eliminada, «La sede ya no se encuentra disponible.» (FA2)
| Validación    | la card dice: se impide la baja con reservas futuras (FA3)
| Error         | la card dice: FA4 «No se pudo dar de baja la sede. Intente nuevamente.» y permanece en la edición
| Estado        | la card dice «queda eliminada del sistema»; no dice si es borrado físico o baja lógica → CU-19-AMB-01
| Permisos      | la card dice: administrador con permisos para gestionar sedes
| Límites       | la card no dice si una reserva en curso cuenta como «futura» para FA3 → CU-19-AMB-02
| Orden         | no aplica
| Concurrencia  | la card dice: FA2 cubre la sede eliminada en otra sesión; no dice qué pasa si alguien reserva en esa sede mientras se confirma la baja → CU-19-AMB-03
| Rastro        | la card no dice que se estampe cuándo y qué administrador dio de baja la sede → CU-19-AMB-04

## Eventos
CU-19-AMB-01 · 2026-09-27 · abierta · ¿baja lógica (la sede y sus espacios quedan inactivos y el historial los sigue mostrando) o borrado físico?
CU-19-AMB-02 · 2026-09-27 · abierta · una reserva en curso al momento de la baja, ¿bloquea la baja como si fuera futura?
CU-19-AMB-03 · 2026-09-27 · abierta · si alguien reserva en esa sede mientras el administrador confirma, ¿la baja se rechaza por FA3?
CU-19-AMB-04 · 2026-09-27 · abierta · ¿se guarda fecha de baja y qué administrador la hizo?
CU-19-AMB-05 · 2026-09-27 · abierta · con reservas futuras, ¿se impide la baja (CU) o se anulan las reservas y se avisa con CU-24.2?
CU-19-AMB-06 · 2026-09-27 · abierta · ¿la baja se inicia desde la edición (CU) o también desde el listado (prototipo)? ¿hay mensaje de éxito?
CU-19-AMB-07 · 2026-09-27 · abierta · ¿una sede dada de baja puede volver a darse de alta, y su nombre queda libre?
CU-19-AMB-00 · 2026-09-27 · snapshot · congelado en 2e15ff6
CU-19-AMB-00 · 2026-09-27 · snapshot · congelado en 4f88881
CU-19-AMB-01 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-19-AMB-01 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
CU-19-AMB-04 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-19-AMB-04 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
CU-19-AMB-05 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-19-AMB-05 · 2026-09-27 · resuelta · la baja de una sede o de un espacio con reservas futuras no se permite; la cancelación forzosa sale sólo de CU-15 (decisión 5)
CU-19-AMB-08 · 2026-09-30 · abierta · ¿los espacios de la sede se dan de baja con ella, o sólo dejan de verse porque su sede no está?
CU-19-AMB-09 · 2026-09-30 · abierta · FA2 y FA4: ¿el texto propio del CU o los overlays compartidos del prototipo?
CU-19-AMB-02 · 2026-09-30 · vencida → CU-19-SUP-01 · una reserva activa que todavía no terminó, aunque ya haya empezado, también impide la baja: la sede no se cierra con gente jugando
CU-19-AMB-03 · 2026-09-30 · vencida → CU-19-SUP-02 · la baja toma la sede exclusiva: una reserva que se está haciendo termina antes y la baja la ve (FA3), o espera y encuentra la sede dada de baja
CU-19-AMB-06 · 2026-09-30 · vencida → CU-19-SUP-03 · la baja se inicia desde la edición (CU) y también desde «Dar de baja» en la tarjeta del listado (prototipo 62:1648); al terminar, el listado con el aviso «La sede fue dada de baja correctamente» abajo
CU-19-AMB-07 · 2026-09-30 · vencida → CU-19-SUP-04 · una sede dada de baja no se reactiva; su nombre queda libre para una sede nueva, porque el nombre es único sólo entre las activas
CU-19-AMB-08 · 2026-09-30 · vencida → CU-19-SUP-05 · sus espacios activos se dan de baja con ella, con la misma fecha y el mismo autor; las reservas pasadas los siguen mostrando en el historial
CU-19-AMB-09 · 2026-09-30 · vencida → CU-19-SUP-06 · FA2 con el overlay compartido «Esto cambió mientras tanto» (393:6532) y vuelta al listado; FA4 con los overlays compartidos de conexión y servidor (42:384, 42:410), sin salir de donde estaba; FA3 con el overlay del prototipo 42:345
