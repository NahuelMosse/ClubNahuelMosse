# Ambigüedades — REV-02 · operación

## The ten questions

| Empty case    | not applicable: la card no agrega listados
| Duplicates    | the card says: "Cada error no manejado se registra dos veces con el traceback completo (E12)"
| Validation    | the card says: "La API arranca «sana» sin base o sin esquema, y falla recién en el primer pedido (E7)"
| Limits        | the card says: "`GET /reservas` tardó 131 s en dar 500 … (la app se rinde a los 15 s)" y "Render tarda ~1 min en despertar"; the card does not say cuánto se espera a la base ni a la API dormida → REV-02-AMB-02
| Permissions   | the card says: "el usuario `club` corre `alembic upgrade head` en el build y es el de la app"; the card does not say qué puede hacer el usuario de la app → REV-02-AMB-03
| State         | not applicable: la card no agrega estados de negocio
| Error         | the card says: "El 500 es «Internal Server Error» sin id … se ve «Revisá tu conexión a internet»"; the card does not say qué mensaje ve la persona con la API despertando → REV-02-AMB-04
| Order         | not applicable
| Concurrency   | not applicable: el barrido ya toma con `SKIP LOCKED`
| Trail         | the card says: "Los pedidos no llevan id de correlación … Los errores no llevan la versión. No hay métricas, OpenTelemetry, SLOs ni alertas"; the card does not say adónde van métricas y trazas → REV-02-AMB-05; y "Render plan free: sin backups, vence a los 30 días" → REV-02-AMB-01

## Events

REV-02-AMB-00 · 2026-10-20 · snapshot · frozen at 773cb4a
REV-02-AMB-01 · 2026-10-20 · open · ¿Se paga un plan de Render? Las opciones son: una base paga (desde USD 6 por mes) que tiene copias de seguridad y no vence, un servicio web pago (USD 7 por mes) que no se duerme, o una tarea programada de Render (centavos por mes) que mande los recordatorios aunque la app esté dormida. Sin plan pago, la base se borra entre los días 30 y 44 y los recordatorios dependen de que alguien la despierte.
REV-02-AMB-01 · 2026-10-20 · no channel · decide una persona; mientras tanto → REV-02-ASM-01, REV-02-ASM-02
REV-02-AMB-02 · 2026-10-20 · no channel · ¿Cuánto se espera a la base antes de dar el pedido por fallido, y cuánto espera la app a que la API despierte? → REV-02-ASM-03, REV-02-ASM-06
REV-02-AMB-03 · 2026-10-20 · no channel · ¿El usuario con el que la app entra a la base puede crear o cambiar tablas? → REV-02-ASM-04
REV-02-AMB-04 · 2026-10-20 · no channel · Cuando la API tarda en responder porque está despertando, ¿qué le dice la app a la persona? → REV-02-ASM-06
REV-02-AMB-05 · 2026-10-20 · no channel · ¿Adónde van las métricas y las trazas, si el club no tiene un servicio para verlas? → REV-02-ASM-08
