---
card: CU-02
extraido: 2026-09-27T10:55:32-03:00
fuentes:
  - CU/CU - 02 Log out.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 2 Perfil de usuario («Se deberá poder cerrar la sesión.»)"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 37:147 CU-01 · Home · Usuario"
  - "Figma · 43:1422 CU-02 · Tarjeta del avatar (overlay)"
  - "Figma · 39:356 CU-05 · Mi perfil · Lectura"
  - "Figma · 29:27 CU-01 · Login · Vacío"
no_leido:
  - "las imágenes de pantalla embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-02 · Cerrar sesión

## Card, tal como está escrita

**Definición** (fuente: CU-02)
- Actor principal: Usuario.
- Objetivo: «permitir al usuario cerrar su sesion actual».
- Problema que resuelve: «Resuelve salidas de la cuenta por parte del usuario».

**Precondiciones** (fuente: CU-02) — El usuario debe haber ingresado por login en la plataforma.

**Poscondiciones** (fuente: CU-02) — El usuario se encuentra con su sesion cerrada.

**Flujo principal** (fuente: CU-02)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El usuario selecciona el icono superior derecha que indica su perfil. | El sistema carga y muestra una modal con los datos del usuario (nombre, estado, Apellido, DNI, email, y fecha de nacimiento) sus opciones (perfil, reservas y cerrar sesión). |
| 2 | El usario selecciona la opcion "Cerrar sesion". | El sistema cierra la sesion y carga nuevamente el login con la sesion del usuario cerrada. |
| 3 | Fin caso de uso. | |

**Flujos alternativos y de excepción** (fuente: CU-02)
- **FA1 · El usuario cierra la sesión desde el menú desde su perfil.** Origen: paso 0. Condición: el
  usuario se encuentra en el menu de su perfil. El usuario selecciona la opcion de cerrar sesion; el
  sistema cierra la sesion y carga nuevamente el login con la sesion del usuario cerrada.
- **FA2 · El usuario cancela el flujo del caso de uso.** Origen: antes del paso 2. Condición: el
  usuario se encuentra logeado y decide cancelar el cierre de sesion. El usuario presiona en la
  pantalla algun lugar que no sea el botón "Cerrar sesion"; el sistema carga y deshabilita la
  visibilidad del modal con las opciones.

**Diseño declarado en el CU** (fuente: CU-02)
- Pantallas: P-01 Home page MN · P-02 Avatar icon modo nocturno · P-03 Mi perfil MN.
- Botones rojos de cerrar sesión; modal con la opción «Cerrar sesión» entre otras.
- Mensaje: «Sesión cerrada exitosamente» al terminar.

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 2: «Se deberá poder cerrar la sesión.»

**Pantallas del prototipo** (fuente: Figma)
- `CU-02 · Tarjeta del avatar (overlay)`: iniciales, nombre, correo, «MIEMBRO ACTIVO», y las
  opciones «Perfil completo», «Mis reservas», «Cerrar sesión».
- `CU-05 · Mi perfil · Lectura` como origen de FA1; `CU-01 · Login · Vacío` como destino.

## Escenarios

- [ ] CU-02-H01-01 — cierra la sesión desde la tarjeta del avatar y vuelve al login
- [ ] CU-02-H01-02 — después de cerrar la sesión, volver atrás no reabre una pantalla con sesión
- [ ] CU-02-H02-01 — cierra la sesión desde Mi perfil y vuelve al login
- [ ] CU-02-H03-01 — abre la tarjeta del avatar, toca afuera y la tarjeta se cierra sin cerrar la sesión

## Contradicciones dentro de la card

- El CU dice que la tarjeta muestra nombre, estado, apellido, DNI, correo y fecha de nacimiento; el
  prototipo muestra sólo nombre, correo y estado · CU-02 paso 1, Figma 43:1422.
- El CU pide el mensaje «Sesión cerrada exitosamente» al terminar; el prototipo no tiene ese
  mensaje en ninguna pantalla · CU-02 diseño, Figma 29:27.
