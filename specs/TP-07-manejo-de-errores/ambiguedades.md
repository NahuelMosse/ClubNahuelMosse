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
