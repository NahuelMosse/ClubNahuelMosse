---
card: CU-04
extraido: 2026-09-27T10:55:32-03:00
fuentes:
  - CU-nuevos/CU-04 - Cambiar contraseña.md
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 1 (mecanismo seguro de contraseña) · § RF 7 Manejo de errores"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 35:444 CU-04 · Cambiar contraseña · Formulario vacío"
  - "Figma · 36:436 CU-04 · Cambiar contraseña · Validación en vivo"
  - "Figma · 36:378 CU-04 · Cambiar contraseña · Error contraseña actual"
  - "Figma · 390:6379 CU-04 · Cambiar contraseña · No coinciden"
  - "Figma · 35:350 CU-04 · Cambiar contraseña · Actualizada"
  - "Figma · 42:384 Error de conexión · 42:410 Error del servidor · 42:426 Sesión expirada (overlays compartidos)"
no_leido: []
estado: propuesta
---

# Snapshot — CU-04 · Cambiar contraseña

## Card, tal como está escrita

**Definición** (fuente: CU-04)
- Módulo: Autenticación. Actor principal: Usuario registrado.
- Objetivo: «Permitir que un usuario con la sesión iniciada reemplace su contraseña actual por una
  nueva, verificando antes que es él quien la está cambiando.»
- Problema que resuelve: sin este flujo, quien sospecha que su contraseña quedó expuesta sólo
  puede salir por «olvidé mi contraseña» (CU-04b), más lento; pedir la contraseña actual evita que
  alguien con el teléfono desbloqueado cambie la clave.

**Precondiciones** (fuente: CU-04)
- El usuario tiene la sesión iniciada y el token es válido.
- El usuario está en la pantalla «Mi perfil» (CU-05).
- Hay conexión con el backend.

**Poscondiciones** (fuente: CU-04)
- La contraseña queda reemplazada en el backend.
- Las demás sesiones del usuario se invalidan.
- La sesión actual se mantiene abierta: el usuario vuelve a su perfil, no al login.

**Flujo principal** (fuente: CU-04)
| # | Usuario | Sistema |
|---|---|---|
| 1 | Presiona la fila "Cambiar contraseña" del bloque Seguridad. | Navega a la pantalla Cambiar contraseña con los tres campos vacíos y el botón deshabilitado. |
| 2 | Escribe su contraseña actual. | Habilita el campo de contraseña nueva. |
| 3 | Escribe la contraseña nueva. | Valida en vivo las tres reglas (8 caracteres, una mayúscula, un número) y marca cada una en verde o rojo. |
| 4 | Repite la contraseña nueva. | Compara ambas; si coinciden y las reglas se cumplen, habilita "Guardar contraseña". |
| 5 | Presiona "Guardar contraseña". | Envía la solicitud, invalida las demás sesiones y muestra la pantalla "Contraseña actualizada". |
| 6 | Presiona "Volver al perfil". | Regresa a Mi perfil con la sesión intacta. |

**Flujos alternativos y de excepción** (fuente: CU-04)
- **FA1 · La contraseña actual no coincide** (origen paso 5). El backend rechaza la operación. El
  sistema marca en rojo el campo de contraseña actual con el mensaje «La contraseña actual no
  coincide», conserva lo escrito en los otros dos campos y no cambia nada.
- **FA2 · La contraseña nueva no cumple las reglas** (origen pasos 3 y 4). El botón permanece
  deshabilitado y las reglas que faltan quedan marcadas en rojo. No se envía nada al backend.
- **FA3 · Las contraseñas no coinciden** (origen paso 4). El sistema marca el campo de repetición y
  mantiene el botón deshabilitado.
- **FA4 · Error de conexión** (origen paso 5). Se abre el overlay compartido de error de conexión
  con la opción de reintentar. Los datos del formulario se conservan.
- **FA5 · Error del servidor** (origen paso 5). Se abre el overlay compartido de error del
  servidor. La contraseña no cambia.
- **FA6 · Sesión expirada** (cualquier paso). El sistema cierra la sesión y lleva al login.

**Mensajes** (fuente: CU-04) — «La contraseña actual no coincide» · «Al menos 8 caracteres» /
«Una letra mayúscula» / «Al menos un número» · «Contraseña actualizada».

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 1 pide un mecanismo seguro para recuperar o establecer una nueva contraseña; no menciona el
  cambio con sesión iniciada.

**Pantallas del prototipo** (fuente: Figma)
- Título «Cambiá tu contraseña», subtítulo «Necesitamos tu contraseña actual para confirmar que sos
  vos.», campos CONTRASEÑA ACTUAL, CONTRASEÑA NUEVA, REPETIR CONTRASEÑA, botón GUARDAR CONTRASEÑA.
- Error por no coincidir: «Las contraseñas no coinciden». Éxito: «Tu contraseña se cambió
  correctamente. Usala la próxima vez que inicies sesión.» · VOLVER AL PERFIL.

## Escenarios

- [ ] CU-04-H01-01 — cambia la contraseña, vuelve al perfil con la sesión abierta y la nueva sirve para entrar
- [ ] CU-04-H01-02 — después del cambio, la contraseña anterior ya no sirve para iniciar sesión
- [ ] CU-04-H02-01 — escribe mal la contraseña actual y ve el error sin que cambie nada
- [ ] CU-04-H03-01 — la contraseña nueva no cumple una regla y el botón sigue deshabilitado
- [ ] CU-04-H04-01 — la repetición no coincide y el botón sigue deshabilitado
- [ ] CU-04-H05-01 — sin conexión al guardar, ve el error de conexión y conserva lo escrito
- [ ] CU-04-H06-01 — el servidor falla al guardar y la contraseña no cambia
- [ ] CU-04-H07-01 — con la sesión vencida, la app lo lleva al login

## Contradicciones dentro de la card

- El paso 2 dice que el campo de contraseña nueva se habilita recién al escribir la actual; el
  prototipo muestra los tres campos habilitados desde el formulario vacío · CU-04 paso 2,
  Figma 35:444.
