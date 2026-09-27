# Ambigüedades — CU-01 · Iniciar sesión

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card dice: «Muestra un mensaje de error indicando que debe completar email y contraseña. No se envía la solicitud al backend.» (FA1)
| Duplicados    | no aplica: iniciar sesión no crea ninguna entidad
| Validación    | la card dice sólo campos vacíos (FA1); no dice si se valida el formato del correo antes de enviar → CU-01-AMB-01
| Error         | la card dice: FA4 error del servidor «solicita reintentar más tarde», FA5 sin conexión «solicita reestablecerla»
| Estado        | la card no dice cuánto dura la sesión ni si sobrevive a cerrar la app → CU-01-AMB-02
| Permisos      | la card no dice cómo inicia sesión un administrador ni quién decide el rol (el prototipo tiene selector Usuario / Administrador) → CU-01-AMB-03
| Límites       | la card no dice si hay tope de intentos fallidos ni si el correo distingue mayúsculas → CU-01-AMB-04, CU-01-AMB-05
| Orden         | no aplica: no hay listados
| Concurrencia  | la card no dice si el mismo usuario puede tener varias sesiones abiertas a la vez (CU-04 supone que sí: invalida «las demás sesiones») → CU-01-AMB-06
| Rastro        | la card no dice si se estampa el último ingreso ni los intentos fallidos → CU-01-AMB-07

## Eventos
CU-01-AMB-01 · 2026-09-27 · abierta · ¿se valida el formato del correo en la app antes de enviar, o cualquier texto llega al backend y cae en FA2?
CU-01-AMB-02 · 2026-09-27 · abierta · ¿la sesión persiste al cerrar y reabrir la app? ¿cuánto dura hasta que aparece «Tu sesión expiró»?
CU-01-AMB-03 · 2026-09-27 · abierta · ¿el rol sale de la cuenta (el backend sabe quién es admin) o lo elige el usuario en el selector del login? ¿cómo se crea la primera cuenta admin?
CU-01-AMB-04 · 2026-09-27 · abierta · ¿hay bloqueo o demora después de N intentos fallidos?
CU-01-AMB-05 · 2026-09-27 · abierta · ¿el correo se compara sin distinguir mayúsculas y sin espacios alrededor?
CU-01-AMB-06 · 2026-09-27 · abierta · ¿se permiten varias sesiones simultáneas del mismo usuario en distintos dispositivos?
CU-01-AMB-07 · 2026-09-27 · abierta · ¿se registra fecha y hora del último ingreso y de los intentos fallidos?
CU-01-AMB-08 · 2026-09-27 · abierta · ¿la autenticación la resuelve Firebase Auth (enunciado RNF 5) o el backend propio contra la base (CU-01 paso 3–4)?
CU-01-AMB-09 · 2026-09-27 · abierta · ¿qué texto manda en credenciales inválidas: el del CU o el del prototipo? ¿un mensaje único o uno por campo en FA1?
CU-01-AMB-00 · 2026-09-27 · snapshot · congelado en e8013cb
CU-01-AMB-00 · 2026-09-27 · snapshot · congelado en a1f7f83
CU-01-AMB-02 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-01-AMB-02 · 2026-09-27 · resuelta · la sesión sigue abierta al reabrir la app y se permiten varias a la vez; al cerrar sesión el dispositivo deja de recibir push (decisión 14)
CU-01-AMB-03 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-01-AMB-03 · 2026-09-27 · resuelta · el rol lo trae la cuenta y se guarda en la base; el login no tiene selector de rol; la primera cuenta de administrador se crea al inicializar la base (decisión 2)
CU-01-AMB-06 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-01-AMB-06 · 2026-09-27 · resuelta · la sesión sigue abierta al reabrir la app y se permiten varias a la vez; al cerrar sesión el dispositivo deja de recibir push (decisión 14)
CU-01-AMB-08 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-01-AMB-08 · 2026-09-27 · resuelta · Firebase Auth; la API valida el token de Firebase en cada pedido (decisión 1)
CU-01-AMB-09 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-01-AMB-09 · 2026-09-27 · resuelta · si el CU y el prototipo dicen distinto, manda el prototipo (decisión 12)
CU-01-AMB-01 · 2026-09-27 · vencida → CU-01-SUP-01 · la app no valida el formato del correo antes de enviar: el correo que Firebase rechaza por mal formado cae en el mensaje genérico de FA2
CU-01-AMB-04 · 2026-09-27 · vencida → CU-01-SUP-02 · sin bloqueo propio por intentos fallidos; cuando Firebase frena por demasiados intentos se muestra el mismo mensaje genérico de FA2
CU-01-AMB-05 · 2026-09-27 · vencida → CU-01-SUP-03 · el correo se envía sin espacios alrededor y en minúsculas, igual que lo guarda el registro
CU-01-AMB-07 · 2026-09-27 · vencida → CU-01-SUP-04 · la base no guarda el último ingreso ni los intentos fallidos
CU-01-AMB-10 · 2026-09-27 · abierta · ¿qué pasa si la cuenta existe en Firebase pero no tiene un perfil activo en la base (por ejemplo, dada de baja)?
CU-01-AMB-10 · 2026-09-27 · vencida → CU-01-SUP-05 · no inicia sesión: se cierra la sesión de Firebase y se muestra el mensaje genérico de FA2
