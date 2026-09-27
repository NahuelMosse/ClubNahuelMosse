---
card: MOD-01
extraido: 2026-09-27T13:05:00-03:00
fuentes:
  - "enunciado: Trabajo Práctico_2026.docx.pdf § Entrega 2 («Modelo de datos de la aplicación, incluyendo entidades, atributos y relaciones.») — texto de la card, sin CU propio"
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 1, RF 2, RF 3, RF 4, RF 5, RF 6 (atributos mínimos de cada entidad) · § RNF 4 BBDD · § RNF 5 Cloud"
no_leido: []
estado: propuesta
---

# Snapshot — MOD-01 · Modelo de datos

El requerimiento no tiene CU propio: es un entregable de la Entrega 2 y se congela como texto del
enunciado. Las decisiones que cada CU dejó abiertas sobre datos (estados, bajas, rastro) están en
sus `ambiguedades.md`; esta card sólo transcribe lo que el enunciado fija.

## Card, tal como está escrita

**Entrega 2** (fuente: enunciado)
> «Modelo de datos de la aplicación, incluyendo entidades, atributos y relaciones.»

**Lo que el enunciado fija sobre los datos** (fuente: enunciado)
- **Usuario** (RF 1, RF 2): registro «mediante correo electrónico y contraseña»; «El perfil deberá
  incluir, como mínimo, nombre, apellido y fecha de nacimiento»; todos los datos editables «salvo la
  dirección de correo electrónico».
- **Sede** (RF 4): «como mínimo, con un nombre, una dirección y horarios de funcionamiento».
- **Espacio deportivo** (RF 5): «asociado a una sede y contar, como mínimo, con un tipo y un nombre
  compuesto por la sede, dirección, tipo de espacio deportivo y un número. Por ejemplo:
  Moron_Rivadavia_19850_Paddle_1.»
- **Reserva** (RF 3): «corresponde a un espacio deportivo, una fecha, una hora de inicio y una hora de
  finalización»; realizada por un usuario («Listar las reservas realizadas por el usuario»); se puede
  cancelar y el espacio vuelve a estar disponible.
- **Historial** (RF 6): incluye «las reservas cuyo horario ya haya finalizado».
- **Base de datos** (RNF 4): «cualquier base de datos relacional. (Preferentemente PostgreSQL)».
- **Cloud** (RNF 5): API y base en la nube; Firebase posible para autenticación y push; «Las
  operaciones de la API relacionadas con usuarios y reservas deberán identificar al usuario
  autenticado.»

## Escenarios

- [ ] MOD-01-H01-01 — un usuario se guarda con correo, nombre, apellido y fecha de nacimiento, y el correo no se puede cambiar
- [ ] MOD-01-H01-02 — una sede se guarda con nombre, dirección y horario de funcionamiento
- [ ] MOD-01-H01-03 — un espacio se guarda asociado a una sede, con tipo y un nombre compuesto por sede, dirección, tipo y número
- [ ] MOD-01-H01-04 — una reserva se guarda con usuario, espacio, fecha, hora de inicio y hora de fin
- [ ] MOD-01-H01-05 — la base rechaza dos reservas superpuestas del mismo espacio en la misma fecha
- [ ] MOD-01-H01-06 — una reserva finalizada sigue existiendo y aparece en el historial

## Contradicciones dentro de la card

- El enunciado define el horario de funcionamiento como atributo de la sede; CU-16 lo pone también
  en cada cancha («franja horaria») · enunciado RF 4, CU-16 precondiciones.
- El enunciado nombra un solo «tipo» por espacio; CU-20 y CU-21 usan deporte y tipo como dos datos ·
  enunciado RF 5, CU-21 paso 3.
- El enunciado no nombra el DNI ni el precio; CU-03 exige DNI único y CU-09, CU-21 y CU-22 manejan
  precio por hora · CU-03 FA2, CU-21 paso 3.
