---
card: CU-06
extraido: 2026-09-27T11:20:00-03:00
fuentes:
  - CU/CU-06 - Editar perfil.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 2 Perfil de usuario · § RF 7 Manejo de errores"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 39:356 CU-05 · Mi perfil · Lectura"
  - "Figma · 43:314 CU-06 · Editar perfil · Edición"
  - "Figma · 43:421 CU-06 · Editar perfil · Formato inválido"
  - "Figma · 71:4566 CU-05 · Mi perfil · Modo claro"
  - "Figma · 42:384 Compartido · Error de conexión (overlay)"
no_leido:
  - "las imágenes de pantalla embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-06 · Editar perfil

## Card, tal como está escrita

**Definición** (fuente: CU-06)
- Actor principal: Usuario Registrado.
- Objetivo: «El usuario registrado modifique los datos de su perfil.»
- Problema que resuelve: «permitir editar datos al usuario ya sea por algún error en la carga o
  cambio de preferencia en tema.»

**Precondiciones** (fuente: CU-06) — El usuario debe haber iniciado sesión en la plataforma.

**Poscondiciones** (fuente: CU-06) — Los datos modificados del cliente quedan guardados en su perfil.

**Flujo principal** (fuente: CU-06)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El usuario selecciona la opción "Perfil" del menu inferior. | El sistema carga y muestra los datos del usuario con la opción modo oscuro y eliminar cuenta. |
| 2 | Seleccionar botón "editar" en box "datos personales". | El sistema cambia la interfaz para que los datos personales sean editables y coloca el botón "Guardar". |
| 3 | Rellenar campos con datos nuevos. | El sistema muestra en pantalla los nuevos datos modificados por el usuario. |
| 4 | Seleccionar botón "guardar". | El sistema valida que el formato de los datos sean correctos y guarda los datos modificados. |
| 5 | Selección botón "modo oscuro". | El sistema cambia el modo al opuesto que se encuentra en ese instante. |

**Flujos alternativos y de excepción** (fuente: CU-06)
- **FA1 · Formato de datos invalido.** Origen: paso 4. Sistema: «Muestra un mensaje de error "El
  formato de los datos no es valido", muestra en rojo aquellos datos que no pueden ser guardados por
  formato invalido y en verde aquellos que estén correctos y vuelve al paso 3 del flujo principal.»
- **FA2 · Error de conexión.** Origen: paso 4. Condición: «Error de conexión con la aplicación.»
  Sistema: «Muestra un mensaje de error "Error de conectividad", informa que no tiene conexión con la
  aplicación y vuelve al paso 3 del flujo principal.»

**Diseño declarado en el CU** (fuente: CU-06) — Mi perfil · Mi perfil modo edición · Mi perfil modo
claro · Error formato de datos · Error de conexión.

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 2: «Se deben mostrar todos los datos del perfil de usuario y permitir su edición, salvo la
  dirección de correo electrónico.» Mínimo nombre, apellido y fecha de nacimiento.

**Pantallas del prototipo** (fuente: Figma)
- Edición: campos NOMBRE, APELLIDO, DNI, FECHA DE NACIMIENTO (DD / MM / AAAA), CORREO ELECTRÓNICO,
  botón GUARDAR.
- Formato inválido: DNI «42118» con «El formato de los datos no es válido» y fecha «32 / 13 / 2000».

## Escenarios

- [ ] CU-06-H01-01 — edita su nombre, guarda, y el perfil muestra el dato nuevo al volver a abrirlo
- [ ] CU-06-H01-02 — el correo no se puede editar
- [ ] CU-06-H01-03 — alterna el modo oscuro y el tema cambia al opuesto
- [ ] CU-06-H02-01 — guarda un DNI o una fecha con formato inválido, ve el error y no se guarda nada
- [ ] CU-06-H03-01 — sin conexión al guardar, ve el error de conectividad y conserva lo escrito

## Contradicciones dentro de la card

- FA1 pide marcar «en verde aquellos que estén correctos»; el prototipo sólo marca el campo
  inválido · CU-06 FA1, Figma 43:421.
- El prototipo en edición muestra el campo CORREO ELECTRÓNICO dentro del formulario; el enunciado
  prohíbe editarlo y CU-05 lo señala como no editable · Figma 43:314, enunciado RF 2.
- El CU incluye el cambio de tema como parte de editar el perfil; CU-05 lo ubica en la consulta ·
  CU-06 paso 5, CU-05 paso 4.
