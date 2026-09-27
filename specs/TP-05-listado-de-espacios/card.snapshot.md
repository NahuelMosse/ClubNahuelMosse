---
card: TP-05
extraido: 2026-09-27T14:10:00-03:00
fuentes:
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 5 Módulo de Espacios deportivos — texto de la card, sin CU propio"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 63:1895 CU-21 · Gestionar espacios (listado del administrador con la sede en el nombre)"
  - "Figma · 52:824 CU-13 · Consultar canchas · Resultados (tarjetas con la sede)"
no_leido:
  - "una pantalla de usuario con el listado de espacios de todas las sedes: no existe en el prototipo"
estado: propuesta
---

# Snapshot — TP-05 · Listado de espacios deportivos

El requisito no tiene CU propio. CU-20 filtra dentro de una sede y CU-13 consulta por sede; ninguno
lista los espacios de todas las sedes, que es lo que pide el enunciado.

## Card, tal como está escrita

**Requerimiento funcional 5** (fuente: enunciado)
> «Mostrar el listado de espacios deportivos indicando la sede donde se ubica cada uno.»
> «Cada espacio deportivo deberá estar asociado a una sede y contar, como mínimo, con un tipo y un
> nombre compuesto por la sede, dirección, tipo de espacio deportivo y un número. Por ejemplo:
> Moron_Rivadavia_19850_Paddle_1.»
> «Permitir filtrar los espacios deportivos por tipo (Fútbol, Paddle, Básquet, etc.).»

**Lo más cercano en el prototipo** (fuente: Figma)
- Panel admin «Espacios»: «17 ESPACIOS ACTIVOS · 4 SEDES», cada tarjeta con deporte, tipo,
  condición, precio y el nombre compuesto, que lleva la sede (63:1895).
- Resultados de CU-13: cada tarjeta con la sede y su dirección (52:824).

## Escenarios

- [ ] TP-05-H01-01 — el usuario ve el listado de los espacios de todas las sedes, cada uno con su sede
- [ ] TP-05-H01-02 — cada espacio muestra su nombre compuesto por sede, dirección, tipo y número
- [ ] TP-05-H01-03 — un espacio recién dado de alta aparece en el listado con su sede
- [ ] TP-05-H02-01 — filtra por tipo y sólo ve los espacios de ese tipo, de todas las sedes
- [ ] TP-05-H02-02 — quita el filtro y vuelve a ver todos los espacios

## Contradicciones dentro de la card

- El enunciado pide el listado de espacios de todas las sedes; el prototipo sólo lo tiene en el
  panel del administrador · enunciado RF 5, Figma 63:1895.
- El enunciado filtra «por tipo»; CU-20 filtra por deporte y variante dentro de una sede · enunciado
  RF 5, CU-20 pasos 2–3.
