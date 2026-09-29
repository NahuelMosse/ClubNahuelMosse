# Ambigüedades — CU-23 · Baja de espacio deportivo

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | no aplica: se da de baja un espacio que existe (precondición)
| Duplicados    | la card no dice qué pasa si el espacio ya fue dado de baja en otra sesión → CU-23-AMB-01
| Validación    | la card no dice si se impide la baja con reservas futuras, como CU-19 hace con la sede → CU-23-AMB-02
| Error         | la card no lo dice; el enunciado exige sin conexión y servidor caído → CU-23-AMB-03
| Estado        | la card dice «la acción será permanente»; no dice si es borrado físico o baja lógica → CU-23-AMB-04
| Permisos      | la card dice: el administrador con sesión iniciada; el paso 1 dice «El usuario» → CU-23-AMB-05
| Límites       | la card no dice si se puede dar de baja el último espacio de una sede (que pasaría a CU-16 FA1) → CU-23-AMB-06
| Orden         | no aplica
| Concurrencia  | la card no dice qué pasa si alguien reserva el espacio mientras se confirma la baja → CU-23-AMB-02
| Rastro        | la card no dice que se estampe cuándo y quién dio de baja el espacio → CU-23-AMB-07

## Eventos
CU-23-AMB-01 · 2026-09-27 · abierta · si el espacio ya fue dado de baja en otra sesión, ¿«Esto cambió mientras tanto»?
CU-23-AMB-02 · 2026-09-27 · abierta · con reservas futuras en el espacio, ¿se impide la baja (como CU-19) o se anulan y se avisa con CU-24.2?
CU-23-AMB-03 · 2026-09-27 · abierta · sin conexión o con el servidor caído, ¿overlays compartidos y el espacio queda como estaba?
CU-23-AMB-04 · 2026-09-27 · abierta · ¿baja lógica (el historial sigue mostrando el espacio) o borrado físico?
CU-23-AMB-05 · 2026-09-27 · abierta · ¿sólo el administrador puede dar de baja? (el paso 1 dice «el usuario»)
CU-23-AMB-06 · 2026-09-27 · abierta · ¿se puede dar de baja el último espacio de una sede?
CU-23-AMB-07 · 2026-09-27 · abierta · ¿se guarda fecha de baja y qué administrador la hizo?
CU-23-AMB-00 · 2026-09-27 · snapshot · congelado en e52f6f4
CU-23-AMB-02 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-23-AMB-02 · 2026-09-27 · resuelta · la baja de una sede o de un espacio con reservas futuras no se permite; la cancelación forzosa sale sólo de CU-15 (decisión 5)
CU-23-AMB-03 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-23-AMB-03 · 2026-09-27 · resuelta · se usan los overlays compartidos del prototipo en toda la app (decisión 11)
CU-23-AMB-04 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-23-AMB-04 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
CU-23-AMB-07 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-23-AMB-07 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
CU-23-AMB-08 · 2026-09-30 · abierta · con reservas pendientes (decisión 5), ¿qué ve el administrador?
CU-23-AMB-09 · 2026-09-30 · abierta · el CU vuelve a cargar el listado sin el espacio: ¿hay además un aviso de que salió bien?
CU-23-AMB-01 · 2026-09-30 · vencida → CU-23-SUP-01 · ya dado de baja en otra sesión: el overlay compartido «Esto cambió mientras tanto» (393:6532) y el listado releído
CU-23-AMB-05 · 2026-09-30 · vencida → CU-23-SUP-02 · sólo un administrador da de baja espacios; «el usuario» del paso 1 es el administrador de las precondiciones
CU-23-AMB-06 · 2026-09-30 · vencida → CU-23-SUP-03 · se puede dar de baja el último espacio de una sede: la sede sigue activa y se ve sin canchas (CU-16 FA1)
CU-23-AMB-08 · 2026-09-30 · vencida → CU-23-SUP-04 · un espacio con una reserva activa que todavía no terminó no se da de baja (decisión 5, como CU-19-SUP-01): «No se puede dar de baja el espacio», con el mismo overlay de la sede (42:345)
CU-23-AMB-09 · 2026-09-30 · vencida → CU-23-SUP-05 · el listado sin el espacio y un aviso abajo «El espacio fue dado de baja correctamente», como la baja de sede (CU-19-SUP-03); desde la edición (CU-22-SUP-04) termina en el listado
