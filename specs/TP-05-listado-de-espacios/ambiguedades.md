# Ambigüedades — TP-05 · Listado de espacios deportivos

Una sola lectura del enunciado, declarada.

## Las diez preguntas
| Caso vacío    | la card no dice qué se ve si no hay espacios o si el filtro no deja ninguno → TP-05-AMB-01
| Duplicados    | no aplica: es una consulta
| Validación    | no aplica: el filtro se elige de una lista
| Error         | la card no lo dice; aplican los overlays de TP-07
| Estado        | la card no dice si los espacios dados de baja aparecen → TP-05-AMB-02
| Permisos      | la card no dice quién ve el listado: el usuario, el administrador, o los dos → TP-05-AMB-03
| Límites       | la card no dice si se pagina → TP-05-AMB-04
| Orden         | la card no dice el orden: por sede, por tipo, por nombre → TP-05-AMB-05
| Concurrencia  | no aplica: consulta de solo lectura
| Rastro        | no aplica: no estampa nada

## Eventos
TP-05-AMB-01 · 2026-09-27 · abierta · sin espacios o sin coincidencias, ¿qué aviso se muestra?
TP-05-AMB-02 · 2026-09-27 · abierta · ¿los espacios dados de baja quedan fuera?
TP-05-AMB-03 · 2026-09-27 · abierta · ¿el listado es una pantalla de usuario nueva (el prototipo no la tiene) o alcanza con el del panel admin y con CU-13 con «todas las sedes»?
TP-05-AMB-04 · 2026-09-27 · abierta · ¿hay paginación?
TP-05-AMB-05 · 2026-09-27 · abierta · ¿en qué orden se listan los espacios?
TP-05-AMB-06 · 2026-09-27 · abierta · ¿el «tipo» del filtro es el deporte (Fútbol) o la variante (Fútbol 5)?
TP-05-AMB-00 · 2026-09-27 · snapshot · congelado en b43ce50
TP-05-AMB-03 · 2026-09-27 · preguntada · al usuario, en la sesión
TP-05-AMB-03 · 2026-09-27 · resuelta · no hay pantalla de usuario con todas las sedes: el producto se pensó desde el principio por sede; cada sede muestra sus espacios con la sede, y el panel del administrador lista los de todas
TP-05-AMB-00 · 2026-09-27 · snapshot · congelado en 98e4e30
TP-05-AMB-01 · 2026-09-28 · vencida → TP-05-SUP-01 · la sede sin canchas dice «Todavía no hay canchas» (CU-16), el panel sin espacios «Todavía no hay espacios» (CU-21), y el filtro nunca deja la lista vacía porque sus chips salen de las canchas de la sede (CU-20-SUP-01)
TP-05-AMB-02 · 2026-09-28 · vencida → TP-05-SUP-02 · sólo se listan los espacios activos; los dados de baja quedan fuera (decisión 4)
TP-05-AMB-04 · 2026-09-28 · vencida → TP-05-SUP-03 · sin paginación: una sede tiene pocas canchas y el panel lista todas en una sola lectura
TP-05-AMB-05 · 2026-09-28 · vencida → TP-05-SUP-04 · en la sede, por deporte, tipo y número (CU-16-SUP-04); en el panel, por nombre de sede y después por deporte, tipo y número
TP-05-AMB-06 · 2026-09-28 · vencida → TP-05-SUP-05 · el «tipo» del enunciado es el deporte, y dentro del deporte se puede elegir además la variante (CU-20, decisión 8)
