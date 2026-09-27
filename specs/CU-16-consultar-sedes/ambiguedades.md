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
