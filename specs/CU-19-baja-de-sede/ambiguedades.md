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
