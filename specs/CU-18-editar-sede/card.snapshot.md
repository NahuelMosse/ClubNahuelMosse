---
card: CU-18
extraido: 2026-09-27T12:30:00-03:00
fuentes:
  - CU-nuevos/CU-18 - Editar sede.md
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 4 Módulo de Sedes · § RF 3 («La hora de finalización de una reserva no podrá superar el horario de cierre de la sede.») · § RF 5 (nombre del espacio compuesto por sede y dirección)"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 62:1648 CU-17 · Gestionar sedes (origen: «Editar sede»)"
  - "Figma · 62:1968 CU-18 · Editar sede"
  - "Figma · 62:2035 CU-18 · Editar sede · Campo vacío"
  - "Figma · 393:6496 CU-18 · Editar sede · Reservas fuera del horario (overlay)"
  - "Figma · 393:6532 Compartido · Algo cambió mientras tanto · 42:384 Error de conexión · 42:410 Error del servidor (overlays)"
no_leido: []
estado: propuesta
---

# Snapshot — CU-18 · Editar sede

## Card, tal como está escrita

**Definición** (fuente: CU-18)
- Módulo: Sedes y espacios deportivos. Actor principal: Administrador. Alumno asignado: Matías
  Navarro.
- Estaba diseñado en el Figma grupal pero sin especificación escrita; CU-19 depende de él («el
  administrador debe haber ingresado a la pantalla de edición de la sede»).
- Objetivo: «Permitir que el administrador corrija el nombre, la dirección o los horarios de
  funcionamiento de una sede ya cargada.»
- Problema que resuelve: sin edición habría que dar de baja y volver a crear, «lo que arrastraría
  las reservas asociadas».

**Precondiciones** (fuente: CU-18)
- El administrador tiene la sesión iniciada con rol de administrador.
- La sede existe y está activa.

**Poscondiciones** (fuente: CU-18)
- Los datos de la sede quedan actualizados.
- El listado de sedes y las pantallas de usuario reflejan los datos nuevos.
- «Las reservas existentes no se alteran»: siguen apuntando a la misma sede.

**Regla de negocio sobre los horarios** (fuente: CU-18) — Si el horario se achica y quedan reservas
futuras fuera del rango nuevo, el sistema avisa cuántas son y pide confirmación antes de guardar.
Las reservas ya confirmadas se respetan: la validación del cierre «corre al momento de reservar, no
en forma retroactiva».

**Flujo principal** (fuente: CU-18)
| # | Administrador | Sistema |
|---|---|---|
| 1 | Desde el panel admin, entra a la pestaña "Sedes". | Muestra el listado de sedes con sus acciones. |
| 2 | Presiona "Editar sede" en una de ellas. | Abre el formulario con los datos actuales cargados. |
| 3 | Modifica uno o más campos. | Valida en vivo y mantiene habilitado "Guardar cambios" mientras los obligatorios estén completos. |
| 4 | Presiona "Guardar cambios". | Guarda, muestra la confirmación y vuelve al listado con los datos nuevos. |

**Flujos alternativos y de excepción** (fuente: CU-18)
- **FA1 · El administrador desiste** (origen pasos 3 y 4). Vuelve atrás sin guardar; los cambios se
  descartan.
- **FA2 · Vacía un campo obligatorio** (origen paso 3). El campo queda en rojo con el mensaje de
  obligatorio y «Guardar cambios» se deshabilita.
- **FA3 · Achica el horario y hay reservas afuera** (origen paso 4). Informa cuántas reservas futuras
  quedan fuera del rango nuevo y pide confirmación explícita.
- **FA4 · La sede fue dada de baja desde otra sesión** (origen paso 4). Informa que la sede ya no
  está disponible y vuelve al listado.
- **FA5 · Error de conexión o del servidor** (origen paso 4). Overlay compartido; los datos se
  conservan para reintentar.
- **FA6 · El administrador da de baja la sede** (origen paso 3). Presiona «Dar de baja la sede» y el
  control pasa a CU-19.

**Mensajes** (fuente: CU-18) — «La dirección es obligatoria» · «Los cambios se guardaron
correctamente».

**Pantallas del prototipo** (fuente: Figma)
- Formulario: NOMBRE DE LA SEDE, DIRECCIÓN, HORARIO DE APERTURA, HORARIO DE CIERRE; GUARDAR CAMBIOS ·
  DAR DE BAJA LA SEDE.
- Reservas fuera del horario: «¿Guardar el horario nuevo?» · «3 reservas futuras de Sede Morón
  empiezan antes de las 09:00. Si guardás, se mantienen en su horario original: el cambio rige para
  las reservas nuevas.» · GUARDAR IGUAL · REVISAR EL HORARIO.

## Escenarios

- [ ] CU-18-H01-01 — cambia la dirección de una sede y el listado de usuarios muestra la nueva
- [ ] CU-18-H01-02 — después de editar, las reservas existentes siguen asociadas a la sede
- [ ] CU-18-H02-01 — vuelve atrás sin guardar y nada cambia
- [ ] CU-18-H03-01 — vacía la dirección, ve el aviso de obligatorio y no puede guardar
- [ ] CU-18-H04-01 — achica el horario con reservas afuera, ve cuántas son, confirma, y esas reservas se mantienen
- [ ] CU-18-H04-02 — después de achicar el horario, ya no se puede reservar fuera del rango nuevo
- [ ] CU-18-H04-03 — elige revisar el horario y no se guarda nada
- [ ] CU-18-H05-01 — la sede fue dada de baja en otra sesión y se le avisa al guardar
- [ ] CU-18-H06-01 — sin conexión al guardar, ve el error y conserva lo escrito
- [ ] CU-18-H07-01 — desde la edición pasa a dar de baja la sede

## Contradicciones dentro de la card

- El CU permite cambiar el nombre y la dirección de la sede; el enunciado arma el nombre de cada
  espacio con la sede y la dirección, y CU-22 dice que ese nombre no se edita · CU-18 objetivo,
  enunciado RF 5, CU-22 regla de negocio.
- El CU mantiene reservas que quedan fuera del horario nuevo; el enunciado dice que la finalización
  no puede superar el cierre de la sede · CU-18 regla de negocio, enunciado RF 3.
- El prototipo muestra días de funcionamiento en el listado; el formulario de edición sólo tiene
  apertura y cierre · Figma 62:1648, Figma 62:1968.
