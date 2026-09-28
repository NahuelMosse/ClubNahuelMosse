# Ambigüedades — CU-16 · Consultar sedes

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card dice para la sede sin canchas: «un mensaje indicando que todavía no hay canchas disponibles. El contador de canchas queda en cero» (FA1); para el club sin sedes sólo nombra un Empty-State sin flujo → CU-16-AMB-01
| Duplicados    | no aplica: es una consulta
| Validación    | no aplica: no hay datos de entrada
| Error         | la card dice: Excepción 1 modal de conexión con reintento conservando la pantalla, Excepción 2 modal de servidor sin datos parciales
| Estado        | la card dice «sede cargada y habilitada» y «cancha no disponible» sin definir esos estados → CU-16-AMB-02
| Permisos      | la card dice: usuario registrado con sesión activa; no dice si un visitante sin sesión puede ver las sedes → CU-16-AMB-03
| Límites       | la card no dice si el listado de sedes o de canchas se pagina → CU-16-AMB-04
| Orden         | la card no dice en qué orden van las sedes ni las canchas de una sede → CU-16-AMB-05
| Concurrencia  | la card no dice qué ve el usuario si la sede o la cancha se da de baja mientras la está mirando → CU-16-AMB-06
| Rastro        | no aplica: consulta de solo lectura, no hay nada que estampar

## Eventos
CU-16-AMB-01 · 2026-09-27 · abierta · si el club no tiene ninguna sede habilitada, ¿qué muestra el listado?
CU-16-AMB-02 · 2026-09-27 · abierta · ¿qué es una sede «habilitada» y una cancha «no disponible»? ¿una sede o cancha dada de baja (CU-19, CU-23) desaparece del listado o aparece marcada?
CU-16-AMB-03 · 2026-09-27 · abierta · ¿las sedes se pueden consultar sin sesión iniciada?
CU-16-AMB-04 · 2026-09-27 · abierta · ¿hay paginación o carga incremental en el listado?
CU-16-AMB-05 · 2026-09-27 · abierta · ¿en qué orden se muestran las sedes (alfabético, fecha de alta) y las canchas (deporte, número)?
CU-16-AMB-06 · 2026-09-27 · abierta · si una cancha se da de baja mientras el usuario la mira, ¿«Esto cambió mientras tanto» al tocar Ver horarios?
CU-16-AMB-07 · 2026-09-27 · abierta · ¿el horario de funcionamiento es de la sede (enunciado, prototipo) o cada cancha tiene su propia franja (CU)? ¿varía por día de la semana («Lunes a sábado»)?
CU-16-AMB-08 · 2026-09-27 · abierta · ¿el puntaje por sede del prototipo existe? Ningún CU dice de dónde sale; ¿se quita?
CU-16-AMB-09 · 2026-09-27 · abierta · ¿la foto de la sede es un dato que carga el administrador (CU-17 no la pide) o una imagen fija de la app?
CU-16-AMB-00 · 2026-09-27 · snapshot · congelado en ae38a80
CU-16-AMB-02 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-16-AMB-02 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
CU-16-AMB-07 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-16-AMB-07 · 2026-09-27 · resuelta · la sede tiene apertura, cierre y los días de la semana en que abre; el horario es el mismo todos esos días (decisión 7)
CU-16-AMB-08 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-16-AMB-08 · 2026-09-27 · resuelta · el puntaje por sede se quita (decisión 15)
CU-16-AMB-10 · 2026-09-28 · abierta · el prototipo describe cada cancha con un texto propio («Hockey 7 · Al aire libre · césped sintético»); ningún alta lo pide: ¿de dónde sale?
CU-16-AMB-11 · 2026-09-28 · abierta · ¿cuándo una cancha está «no disponible» con el botón deshabilitado y el Badge-Estado?
CU-16-AMB-01 · 2026-09-28 · vencida → CU-16-SUP-01 · sin sedes, el listado dice «Todavía no hay sedes» y «El club todavía no cargó sus sedes.», con el mismo estado vacío que la sede sin canchas
CU-16-AMB-03 · 2026-09-28 · vencida → CU-16-SUP-02 · las sedes se consultan con la sesión iniciada, como dice el actor del CU; sin sesión la app lleva al login
CU-16-AMB-04 · 2026-09-28 · vencida → CU-16-SUP-03 · no hay paginación: se muestran todas las sedes y todas las canchas de la sede
CU-16-AMB-05 · 2026-09-28 · vencida → CU-16-SUP-04 · las sedes van por nombre (CU-17-SUP-06) y las canchas de una sede por deporte, tipo y número
CU-16-AMB-06 · 2026-09-28 · vencida → CU-16-SUP-05 · las canchas se vuelven a pedir al entrar a la sede; si la sede ya no está, «Esta sede ya no está disponible» y vuelve al listado; lo que pase al reservar una cancha dada de baja es de CU-12 y CU-09
CU-16-AMB-09 · 2026-09-28 · vencida → CU-16-SUP-06 · la foto es una imagen fija de la app: cada sede toma una de las cuatro portadas del prototipo y cada cancha la de su deporte; el administrador no carga fotos
CU-16-AMB-10 · 2026-09-28 · vencida → CU-16-SUP-07 · la descripción de la cancha se arma con lo que tiene cargado: tipo, condición e iluminación («Fútbol 5 · Al aire libre · con iluminación»)
CU-16-AMB-11 · 2026-09-28 · vencida → CU-16-SUP-08 · todas las canchas activas se muestran disponibles; una cancha dada de baja no aparece (decisión 4). El Badge-Estado queda para cuando exista un «fuera de servicio» (CU-22-AMB-01)
