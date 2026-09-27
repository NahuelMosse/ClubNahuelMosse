# Ambigüedades — RNF-01 · Requisitos no funcionales y entregables

Una sola lectura del enunciado, declarada.

## Las diez preguntas
| Caso vacío    | no aplica: no hay listados
| Duplicados    | no aplica
| Validación    | la card dice: la API identifica al usuario autenticado en las operaciones de usuarios y reservas (RNF 5)
| Error         | no aplica: los errores de la app están en TP-07
| Estado        | no aplica
| Permisos      | la card dice: operaciones de usuarios y reservas sólo con usuario autenticado; no dice si las consultas de sedes y espacios requieren sesión → RNF-01-AMB-01
| Límites       | la card no dice si el plan gratuito del proveedor en la nube, que duerme el servicio, alcanza para la demostración → RNF-01-AMB-02
| Orden         | no aplica
| Concurrencia  | no aplica
| Rastro        | la card dice: «El historial del repositorio podrá ser considerado como parte del proceso de evaluación»

## Eventos
RNF-01-AMB-01 · 2026-09-27 · abierta · ¿consultar sedes y espacios requiere estar autenticado? CU-16 dice que sí
RNF-01-AMB-02 · 2026-09-27 · abierta · ¿Render gratuito (arranque lento después de inactividad) alcanza, o hace falta otro plan para la defensa?
RNF-01-AMB-03 · 2026-09-27 · abierta · el repositorio único con app y API, ¿cumple, o el ZIP del backend y el de la app tienen que salir de repos separados?
RNF-01-AMB-04 · 2026-09-27 · abierta · ¿el ícono tiene que seguir la identidad del prototipo (lima sobre oscuro)?
RNF-01-AMB-00 · 2026-09-27 · snapshot · congelado en fceccac
