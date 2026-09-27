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
