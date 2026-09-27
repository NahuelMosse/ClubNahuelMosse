---
card: CU-04b
extraido: 2026-09-27T10:55:32-03:00
fuentes:
  - CU-nuevos/CU-04b - Recuperar contraseña.md
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 1 («Los usuarios que olviden su contraseña deberán disponer de un mecanismo seguro para recuperarla o establecer una nueva contraseña.»)"
  - "CU/CU - 01 Login - Acosta Noemi.pdf FA3 (origen del flujo)"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 35:361 CU-04b · Recuperar contraseña · Solicitar"
  - "Figma · 390:6450 CU-04b · Recuperar contraseña · Correo inválido"
  - "Figma · 35:323 CU-04b · Recuperar contraseña · Email enviado"
  - "Figma · 35:403 CU-04b · Recuperar contraseña · Nueva contraseña"
  - "Figma · 390:6480 CU-04b · Recuperar contraseña · No coinciden"
  - "Figma · 35:336 CU-04b · Recuperar contraseña · Enlace inválido"
no_leido: []
estado: propuesta
---

# Snapshot — CU-04b · Recuperar contraseña

## Card, tal como está escrita

**Definición** (fuente: CU-04b)
- Módulo: Autenticación. Actor principal: Usuario registrado sin sesión iniciada.
- No figura en el reparto de CU del grupo; lo exige el enunciado (RF 1) y CU-01 FA3 lo referencia
  como destino.
- Objetivo: «Permitir que un usuario que no recuerda su contraseña establezca una nueva sin
  necesidad de conocer la anterior, verificando su identidad mediante un enlace enviado a su
  correo.»
- Problema que resuelve: es la única vía de reingreso para alguien que quedó afuera de su cuenta.

**Precondiciones** (fuente: CU-04b)
- El usuario está en la pantalla de Login, sin sesión iniciada.
- Hay conexión con el backend.

**Poscondiciones** (fuente: CU-04b)
- Si el correo estaba registrado, se emitió un enlace de un solo uso con vencimiento a 30 minutos.
- Al completarse, la contraseña queda reemplazada y todas las sesiones previas se invalidan.
- El usuario queda en el login para entrar con la contraseña nueva.

**Flujo principal** (fuente: CU-04b)
| # | Usuario | Sistema |
|---|---|---|
| 1 | Presiona "¿Olvidaste tu contraseña?" en el login. | Navega a la pantalla Recuperar contraseña. |
| 2 | Escribe su correo electrónico. | Valida el formato y habilita "Enviar enlace". |
| 3 | Presiona "Enviar enlace". | Solicita el envío al backend y muestra la pantalla de correo enviado. |
| 4 | Abre el enlace desde su correo. | Valida el token y muestra la pantalla de contraseña nueva. |
| 5 | Escribe y repite la contraseña nueva. | Valida las reglas y habilita "Guardar contraseña". |
| 6 | Presiona "Guardar contraseña". | Reemplaza la contraseña, invalida el enlace y las sesiones previas, y muestra la confirmación. |
| 7 | Presiona "Volver al login". | Regresa al login. |

**Regla de seguridad** (fuente: CU-04b) — El sistema responde siempre lo mismo exista o no el
correo: «Si el correo está registrado, te enviamos un enlace». Decir «ese correo no existe»
permitiría enumerar qué direcciones tienen cuenta; mismo criterio que CU-01 FA2.

**Flujos alternativos y de excepción** (fuente: CU-04b)
- **FA1 · El correo no está registrado** (origen paso 3). Muestra la misma pantalla de correo
  enviado y no envía ningún mail.
- **FA2 · Formato de correo inválido** (origen paso 2). El botón permanece deshabilitado y el campo
  queda marcado.
- **FA3 · El enlace venció o ya se usó** (origen paso 4). Pantalla «El enlace no es válido», con la
  opción de pedir uno nuevo.
- **FA4 · Las contraseñas no coinciden** (origen paso 5). El botón permanece deshabilitado.
- **FA5 · El usuario reenvía el correo** (origen paso 3). Desde la pantalla de correo enviado puede
  pedir un reenvío, que invalida el enlace anterior.
- **FA6 · Error de conexión o del servidor** (origen pasos 3 y 6). Se abre el overlay compartido
  correspondiente. No se cambia nada.

**Mensajes** (fuente: CU-04b)
- «Si el correo está registrado, te enviamos un enlace para crear una contraseña nueva. El enlace
  vence en 30 minutos.»
- «El enlace no es válido. Este enlace ya se usó o venció.»

**Pantallas del prototipo** (fuente: Figma)
- Nueva contraseña: «Tiene que tener al menos 8 caracteres, una mayúscula y un número.»
- Correo inválido: «Revisá el formato del correo». Enlace inválido: «Pedí uno nuevo desde la
  pantalla de inicio de sesión.» · PEDIR UN ENLACE NUEVO · Volver al inicio de sesión.
- Correo enviado: VOLVER AL INICIO DE SESIÓN · Reenviar el correo.

## Escenarios

- [ ] CU-04b-H01-01 — pide el enlace, crea una contraseña nueva y entra con ella
- [ ] CU-04b-H01-02 — después de recuperar, la contraseña anterior ya no sirve
- [ ] CU-04b-H02-01 — pide el enlace con un correo sin cuenta y ve el mismo mensaje, sin que se envíe mail
- [ ] CU-04b-H03-01 — escribe un correo con formato inválido y el botón sigue deshabilitado
- [ ] CU-04b-H04-01 — abre un enlace vencido y ve «El enlace no es válido»
- [ ] CU-04b-H04-02 — abre un enlace ya usado y ve «El enlace no es válido»
- [ ] CU-04b-H05-01 — la repetición no coincide y el botón sigue deshabilitado
- [ ] CU-04b-H06-01 — reenvía el correo y el enlace anterior deja de servir
- [ ] CU-04b-H07-01 — sin conexión o con el servidor caído al pedir el enlace, ve el overlay y no cambia nada

## Contradicciones dentro de la card

- El paso 4 dice que el usuario «abre el enlace desde su correo» y la app muestra la pantalla de
  contraseña nueva; ni el CU ni el enunciado dicen cómo un enlace de correo abre una pantalla de la
  app móvil · CU-04b paso 4.
- FA3 ofrece «la opción de pedir uno nuevo»; el prototipo manda a pedirlo «desde la pantalla de
  inicio de sesión» y además tiene el botón PEDIR UN ENLACE NUEVO · CU-04b FA3, Figma 35:336.
