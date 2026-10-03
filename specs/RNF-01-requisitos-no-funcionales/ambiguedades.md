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
RNF-01-AMB-01 · 2026-10-03 · sin canal · ¿consultar sedes y espacios requiere sesión? → RNF-01-SUP-01 (sí; la API ya rechaza todo lo que no es alta de cuenta o recuperación)
RNF-01-AMB-02 · 2026-10-03 · sin canal · ¿el plan gratuito que duerme el servicio alcanza? → RNF-01-SUP-02 (alcanza; el README avisa que el primer pedido tras la inactividad es lento)
RNF-01-AMB-03 · 2026-10-03 · sin canal · ¿un repo único con app y API cumple? → RNF-01-SUP-03 (cumple; cada ZIP sale de apps/mobile y apps/api)
RNF-01-AMB-04 · 2026-10-03 · sin canal · ¿el ícono sigue la identidad del prototipo? → RNF-01-SUP-04 (sí: lima sobre oscuro, con los colores de tokens.dart)
RNF-01-AMB-05 · 2026-10-03 · abierta · H06-01, el deploy real: ¿qué proveedor para la API y la base en la nube? Hace falta que el usuario elija y cree las cuentas. Opciones (costos aproximados, a confirmar en la página de cada proveedor): (a) Render: web service + Postgres gestionado; el servicio gratuito duerme tras inactividad y el Postgres gratuito vence a los 30 días, el pago ronda los USD 7 al mes cada uno; (b) Railway: API y Postgres en un proyecto, sin plan gratuito permanente, crédito de prueba y después uso desde unos USD 5 al mes; (c) Fly.io: contenedor de la API más Postgres propio o gestionado, unos USD 5 a 15 al mes; (d) Neon o Supabase sólo para la base (plan gratuito) más cualquiera de los anteriores para la API. El enunciado nombra Render; recomiendo Render por ser lo que el enunciado ejemplifica y por tener Dockerfile o comando de arranque simple.
RNF-01-SUP-05 · 2026-10-03 · supuesto · los README se verifican contra el código (variables, scripts y comandos existen) y no se ejecutan desde una máquina limpia; ese recorrido queda sin cubrir
RNF-01-SUP-06 · 2026-10-03 · supuesto · «commits a lo largo del desarrollo» se verifica como al menos 50 commits en al menos 3 días distintos
RNF-01-TESTS · 2026-10-03 · congelados en d879013 · escenarios H01-01 a H08-01 en apps/api/tests/escenarios/test_requisitos_no_funcionales.py
RNF-01-TESTS · 2026-10-03 · recongelados en a81ce1c · la cota de H06-02 era 30 y la API tiene 28 operaciones protegidas
RNF-01-SUP-07 · 2026-10-03 · supuesto · el .env.example vive en apps/api, donde config.py lee el .env, y sólo lista las variables que lee; las del entorno van comentadas
RNF-01-SUP-08 · 2026-10-03 · supuesto · la cota de operaciones protegidas es 28, medida sobre las rutas registradas en la app (incluye las que no están en OpenAPI), en un test de integración sin tag
