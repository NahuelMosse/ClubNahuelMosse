# Ambigüedades — TP-01 · Página inicial (Home)

Una sola lectura del enunciado y del prototipo, declarada.

## Las diez preguntas
| Caso vacío    | la card no dice qué ocupa el lugar de «Tu próxima reserva» si no hay ninguna → TP-01-AMB-01
| Duplicados    | no aplica: es una pantalla de lectura
| Validación    | no aplica: no hay datos de entrada
| Error         | la card no lo dice; aplican los overlays de TP-07 → TP-01-AMB-02
| Estado        | la card muestra sólo una reserva «ACTIVA»; no dice si una reserva en curso cuenta como próxima → TP-01-AMB-03
| Permisos      | la card no dice que el administrador vea otro inicio; el prototipo lo manda al panel → TP-01-AMB-04
| Límites       | la card muestra una sola próxima reserva
| Orden         | la card no dice cuál es «la próxima»: se asume la de inicio más cercano → TP-01-AMB-05
| Concurrencia  | no aplica: pantalla de lectura
| Rastro        | no aplica: no estampa nada

## Eventos
TP-01-AMB-01 · 2026-09-27 · abierta · sin reservas próximas, ¿se oculta el bloque o se muestra un aviso con acceso a reservar?
TP-01-AMB-02 · 2026-09-27 · abierta · si falla la carga del Home, ¿overlay compartido o el Home se muestra sin el bloque de reserva?
TP-01-AMB-03 · 2026-09-27 · abierta · una reserva que ya empezó y no terminó, ¿sigue como «próxima»?
TP-01-AMB-04 · 2026-09-27 · abierta · ¿el administrador tiene también el Home de usuario, o sólo el panel?
TP-01-AMB-05 · 2026-09-27 · abierta · ¿«tu próxima reserva» es la activa de inicio más cercano?
TP-01-AMB-06 · 2026-09-27 · abierta · ¿a dónde lleva cada chip de deporte: al listado de sedes filtrado por ese deporte?
TP-01-AMB-07 · 2026-09-27 · abierta · ¿el saludo cambia según la hora (buenos días, buenas tardes, buenas noches)?
TP-01-AMB-00 · 2026-09-27 · snapshot · congelado en 1bc904c
TP-01-AMB-04 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
TP-01-AMB-04 · 2026-09-27 · resuelta · el rol lo trae la cuenta y se guarda en la base; el login no tiene selector de rol; la primera cuenta de administrador se crea al inicializar la base (decisión 2)
