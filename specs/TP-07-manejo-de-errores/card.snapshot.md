---
card: TP-07
extraido: 2026-09-27T13:05:00-03:00
fuentes:
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 7 Manejo de errores (texto de la card, sin CU propio)"
  - "enunciado: Trabajo Práctico_2026.docx.pdf § Entrega 2 («Manejo de errores (sin conexión a internet, servidor caído, login incorrecto, usuario ya registrado, etc.)»)"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 42:384 Compartido · Error de conexión (overlay)"
  - "Figma · 42:410 Compartido · Error del servidor (overlay)"
  - "Figma · 42:426 Compartido · Sesión expirada (overlay)"
  - "Figma · 42:442 Compartido · Acceso denegado (overlay)"
  - "Figma · 393:6532 Compartido · Algo cambió mientras tanto (overlay)"
  - "Figma · 30:365 CU-01 · Login · Credenciales inválidas · 34:647 CU-03 · Registro · Usuario ya registrado"
no_leido: []
estado: propuesta
---

# Snapshot — TP-07 · Manejo de errores

El requerimiento no tiene CU propio: llega como texto del enunciado y se congela así. Cada CU trae
sus flujos de error; esta card fija lo que el enunciado exige para toda la app.

## Card, tal como está escrita

**Requerimiento funcional 7** (fuente: enunciado)
> «Se debe poder manejar los errores que puedan surgir durante el uso de la aplicación. Por ejemplo
> sin conexión a internet, servidor caído, login incorrecto, usuario ya registrado, etc.»

**Entrega 2** (fuente: enunciado)
> «Manejo de errores (sin conexión a internet, servidor caído, login incorrecto, usuario ya
> registrado, etc.)»

**Pantallas compartidas del prototipo** (fuente: Figma)
- Error de conexión: «No pudimos conectarnos. Revisá tu conexión a internet y volvé a intentar.» ·
  REINTENTAR · Volver.
- Error del servidor: «No pudimos procesar la operación en este momento. Intentá más tarde.» ·
  ACEPTAR.
- Sesión expirada: «Tu sesión expiró · Por seguridad cerramos tu sesión. Volvé a iniciar sesión para
  continuar.» · IR AL INICIO DE SESIÓN.
- Acceso denegado: «Tu cuenta no tiene permisos de administrador. Te llevamos a Mis reservas.» · IR A
  MIS RESERVAS.
- Algo cambió: «Esto cambió mientras tanto · Otra persona modificó estos datos mientras los estabas
  viendo. Los actualizamos para que veas el estado real.» · VER LO ACTUALIZADO.
- Login incorrecto: «No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.» (CU-01).
- Usuario ya registrado: «El usuario ya está registrado. Modificá el correo o el DNI.» (CU-03).

## Escenarios

- [ ] TP-07-H01-01 — sin conexión a internet, cualquier operación muestra el error de conexión con reintentar y no pierde lo cargado
- [ ] TP-07-H01-02 — al volver la conexión, reintentar completa la operación
- [ ] TP-07-H02-01 — con el servidor caído o respondiendo con error, se muestra el error del servidor y no se muestran datos a medias
- [ ] TP-07-H03-01 — un login incorrecto muestra el mensaje genérico
- [ ] TP-07-H04-01 — registrarse con un correo ya usado muestra «usuario ya registrado»
- [ ] TP-07-H05-01 — con la sesión vencida, cualquier pantalla lleva al aviso y al inicio de sesión
- [ ] TP-07-H06-01 — un usuario sin rol de administrador que entra al panel ve «Acceso denegado»
- [ ] TP-07-H07-01 — si los datos cambiaron en el servidor mientras el usuario los miraba, ve «Esto cambió mientras tanto» y el estado real

## Contradicciones dentro de la card

- Varios CU piden cerrar los errores con «Aceptar» (CU-05, CU-07, CU-12, CU-20) o mensajes propios
  por pantalla (CU-10 FA3, CU-15 FA4, CU-17 FA3, CU-21 FA3); el prototipo usa un único overlay de
  conexión con REINTENTAR y Volver, y uno de servidor con ACEPTAR · Figma 42:384 y 42:410.
- CU-13 y CU-14 muestran el error dentro de la pantalla, conservando filtros; el resto usa el overlay
  · Figma 201:6295, CU-14 FA2.
