---
card: CU-10
extraido: 2026-09-27T14:22:05-03:00
fuentes:
  - CU/CU-10 - Cancelar Reserva.pdf
  - enunciado: Trabajo Práctico_2026.docx.pdf § 3 Gestión de reservas
no_leido:
  - prototipo de Figma (no se puede leer desde el repo)
estado: propuesta
---

# Snapshot — CU-10 · cancelar reserva

Lo escribe `/card`. **No se edita nunca.** Si el CU cambió, se renombra a
`card.snapshot.2026-09-27.md` y se escribe uno nuevo.
`fuentes:` no puede ir vacía. `no_leido:` puede ir vacía pero no puede faltar.
`estado: propuesta` significa: lo redactó un modelo y ninguna persona lo aprobó.

## Card, tal como está escrita

Transcripción sin interpretar, diciendo de qué fuente salió cada bloque.

**Flujo principal** (fuente: CU-10) — …
**Flujos alternativos y de excepción** (fuente: CU-10) — cada uno con su código: FA1, FA2…
**Reglas que sólo están en el enunciado** (fuente: enunciado) — …

## Escenarios

Formato exacto: `- [ ] <CARD>-H<NN>-<NN> — <título en el idioma del negocio>`, dos dígitos siempre.
Un ID de otra card, o dos escenarios con el mismo ID, es un error duro.

- [ ] CU-10-H01-01 — cancela una reserva futura y el horario vuelve a quedar libre
- [ ] CU-10-H01-02 — desiste en la confirmación y la reserva sigue activa
- [ ] CU-10-H02-01 — intenta cancelar una reserva que ya empezó
- [ ] CU-10-H02-02 — pierde la conexión al confirmar

## Contradicciones dentro de la card

Sin resolver: qué dice cada lado y dónde está cada uno. La resolución va al plan.

- El CU rechaza cancelar una reserva vencida o en curso; el enunciado no fija ningún plazo para
  cancelar · CU-10 FA4, enunciado § 3.

Las ambigüedades **no van acá**: viven en `ambiguedades.md`, que es append-only porque tienen
ciclo de vida. Este archivo es inmutable.
