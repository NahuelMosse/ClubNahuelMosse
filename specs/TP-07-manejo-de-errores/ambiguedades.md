# Ambigüedades — TP-07 · Manejo de errores

Una sola lectura del enunciado, declarada.

## Las diez preguntas
| Caso vacío    | no aplica: los estados vacíos son de cada CU
| Duplicados    | la card dice: «usuario ya registrado» es un error a manejar
| Validación    | la card no dice si los errores de validación de formulario cuentan como «errores» de este requerimiento → TP-07-AMB-01
| Error         | la card dice: «sin conexión a internet, servidor caído, login incorrecto, usuario ya registrado, etc.»
| Estado        | la card no dice si la app guarda la operación para reintentarla sola cuando vuelve la conexión → TP-07-AMB-02
| Permisos      | la card no lo dice; el prototipo tiene «Acceso denegado» para el rol → TP-07-AMB-03
| Límites       | la card no dice después de cuánto tiempo sin respuesta el servidor se considera caído → TP-07-AMB-04
| Orden         | no aplica
| Concurrencia  | la card no lo dice; el prototipo tiene «Esto cambió mientras tanto» para cambios concurrentes → TP-07-AMB-05
| Rastro        | la card no dice si los errores del servidor se registran en un log → TP-07-AMB-06

## Eventos
TP-07-AMB-01 · 2026-09-27 · abierta · ¿las validaciones de formulario entran en «manejo de errores» o sólo los errores de red, servidor y negocio?
TP-07-AMB-02 · 2026-09-27 · abierta · sin conexión, ¿la app sólo avisa y el usuario reintenta, o encola la operación?
TP-07-AMB-03 · 2026-09-27 · abierta · ¿«Acceso denegado» cubre también a un administrador que intenta reservar, si no puede (CU-09-AMB-04)?
TP-07-AMB-04 · 2026-09-27 · abierta · ¿cuántos segundos de espera antes de mostrar el error del servidor?
TP-07-AMB-05 · 2026-09-27 · abierta · ¿qué operaciones detectan el cambio concurrente (versión del registro) y cuáles aceptan que gane el último?
TP-07-AMB-06 · 2026-09-27 · abierta · ¿el backend registra los errores con fecha, usuario y operación?
TP-07-AMB-07 · 2026-09-27 · abierta · ¿un único overlay de conexión y uno de servidor para toda la app (prototipo) o mensajes propios por CU?
TP-07-AMB-00 · 2026-09-27 · snapshot · congelado en b1d835f
TP-07-AMB-07 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
TP-07-AMB-07 · 2026-09-27 · resuelta · se usan los overlays compartidos del prototipo en toda la app (decisión 11)
TP-07-AMB-01 · 2026-09-30 · vencida → TP-07-SUP-01 · las validaciones de formulario siguen siendo de cada CU, con el mensaje junto al campo; esta card no agrega ni cambia reglas de formulario
TP-07-AMB-02 · 2026-09-30 · vencida → TP-07-SUP-02 · sin conexión la app avisa con REINTENTAR y Volver; no guarda la operación para reintentarla sola
TP-07-AMB-03 · 2026-09-30 · vencida → TP-07-SUP-03 · «Acceso denegado» cubre a quien entra al panel sin ser administrador y cualquier 403 de la API (también el administrador que intenta reservar, CU-09-SUP-02); lleva a Mis reservas
TP-07-AMB-04 · 2026-09-30 · vencida → TP-07-SUP-04 · 15 segundos sin respuesta (el límite del cliente de la API); se muestra «Error de conexión» con REINTENTAR, porque la API no se alcanzó
TP-07-AMB-05 · 2026-09-30 · vencida → TP-07-SUP-05 · detectan el cambio concurrente las operaciones que ya lo resuelven por estado del servidor (409 o 404: reservas, bajas, ediciones de sede y espacio); no hay versión de registro ni If-Match y en el resto gana el último; una sede o cancha que ya no está muestra «Esto cambió mientras tanto» en lugar de un aviso suelto
TP-07-AMB-06 · 2026-09-30 · vencida → TP-07-SUP-06 · el backend registra en el log estándar, con fecha, método y ruta, código y usuario, las excepciones no atrapadas, los 5xx y los 401, 403 y 409; no hay tabla de errores
TP-07-TESTS · 2026-09-30 · congelados en 467a731 · rojo pendiente de la pasada final (emulador); los de la API fallan por la aserción: no hay registro de errores
TP-07-SUP-07 · 2026-10-03 · supuesto · «Acceso denegado» vuelve a leer el perfil antes de llevar a Mis reservas, ofrece «Cerrar sesión» y un 403 no navega a otra pantalla encima; si la lectura falla, sigue con el perfil guardado
TP-07-SUP-08 · 2026-10-03 · supuesto · después de un corte de red, un 409 al reintentar registro, cancelar o anular se lee como que el pedido cortado sí llegó: registro dice que la cuenta ya existe y ofrece iniciar sesión; cancelar y anular cuentan como éxito
TP-07-SUP-09 · 2026-10-03 · supuesto · el registro no lleva los parámetros de las consultas (hide_parameters); el texto de error de PostgreSQL (por ejemplo el DETAIL de una violación de unicidad) sí puede traer valores y no se filtra: queda sin cubrir
