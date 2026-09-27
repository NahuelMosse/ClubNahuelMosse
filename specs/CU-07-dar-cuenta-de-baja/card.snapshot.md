---
card: CU-07
extraido: 2026-09-27T14:20:00-03:00
fuentes:
  - CU/CU-07 - Dar cuenta de Baja.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 3 («Al cancelar una reserva, el espacio deportivo deberá volver a estar disponible») · § RF 6 Historial · § RNF 5 Cloud"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 39:356 CU-05 · Mi perfil · Lectura"
  - "Figma · 42:274 CU-07 · Eliminar cuenta · Confirmar (overlay)"
  - "Figma · 43:488 CU-07 · Eliminar cuenta · Procesando"
  - "Figma · 42:384 Error de conexión · 42:410 Error del servidor (overlays compartidos)"
no_leido:
  - "las imágenes de pantalla embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-07 · Dar cuenta de baja

## Card, tal como está escrita

**Definición** (fuente: CU-07)
- Actor principal: Usuario registrado.
- Objetivo: «Eliminar una cuenta, su perfil y credenciales de la BDD de autenticación de Firebase
  junto a sus demás datos asociados.»
- Problema que resuelve: «La posible necesidad de un usuario de borrar su cuenta en caso de que ya
  no esté interesado en los servicios de la aplicación.»

**Precondiciones** (fuente: CU-07) — El usuario debe estar autenticado en la aplicación.

**Poscondiciones** (fuente: CU-07)
- La cuenta del usuario queda eliminada del sistema/base de datos.
- La sesión activa finaliza inmediatamente y la aplicación redirige a la pantalla de inicio de
  sesión.
- «Se liberan o anulan los compromisos futuros si los hubiera, de acuerdo con la lógica de negocio
  de cancelación de reservas.»

**Flujo principal** (fuente: CU-07)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El usuario selecciona desde la Home Page la opción para visualizar su perfil completo. | El sistema carga y muestra los datos del perfil junto con la opción "Eliminar cuenta". |
| 2 | El usuario presiona el botón "Eliminar cuenta". | El sistema muestra un diálogo de advertencia sobre la permanencia de la acción, solicitando confirmación. |
| 3 | El usuario confirma la eliminación de la cuenta. | El sistema elimina la cuenta y los datos asociados del usuario (reservas vigentes inclusive), revoca la sesión activa y redirige a la pantalla de Inicio de Sesión (Login). |

**Flujos alternativos y de excepción** (fuente: CU-07)
- **FA1 · Cancelación de eliminación de cuenta.** Origen: paso 3. Sistema: cierra la ventana de
  precaución y vuelve a la pantalla principal del perfil. «La cuenta permanece en la BDD con sus
  datos intactos sin ser eliminada.»
- **FA2 · Error de conexión a Internet.** Origen: paso 3. Condición: al seleccionar «Eliminar» en la
  confirmación, no hay conectividad. Sistema: alerta de falta de conectividad, pide reintentar. «La
  cuenta no se elimina.»
- **FA3 · Error en el servidor/falla en la API.** Origen: paso 3. Sistema: informa el error del
  servidor y solicita reintentar más tarde. «La cuenta no se elimina.»

**Diseño declarado en el CU** (fuente: CU-07) — Perfil · popup de confirmación · error de
conectividad · error del backend. Botones «Eliminar Cuenta», «Eliminar», «Cancelar», «Aceptar» en
los errores. Mensaje de confirmación de operación.

**Pantallas del prototipo** (fuente: Figma)
- Confirmación: «¿Eliminar tu cuenta?» · «Esta acción es permanente. Se eliminarán tus datos y tus
  reservas vigentes.» · ELIMINAR CUENTA · CANCELAR.
- Procesando: el botón pasa a «ELIMINANDO TU CUENTA…».

## Escenarios

- [ ] CU-07-H01-01 — elimina su cuenta, vuelve al login y ya no puede iniciar sesión con ella
- [ ] CU-07-H01-02 — al eliminar la cuenta, el horario de su reserva vigente vuelve a estar disponible
- [ ] CU-07-H01-03 — mientras se elimina la cuenta, el botón muestra «Eliminando tu cuenta…» y no se puede volver a tocar
- [ ] CU-07-H02-01 — cancela en la confirmación y la cuenta sigue intacta
- [ ] CU-07-H03-01 — sin conexión al confirmar, ve la alerta y la cuenta no se elimina
- [ ] CU-07-H04-01 — el servidor falla al confirmar y la cuenta no se elimina

## Contradicciones dentro de la card

- El CU elimina la cuenta «y los datos asociados del usuario (reservas vigentes inclusive)»; el
  enunciado exige historial de reservas y CU-14 muestra al administrador el historial de todas las
  reservas del sistema, que dejaría de incluir las del usuario borrado · CU-07 paso 3, enunciado
  RF 6, CU-14.
- La poscondición dice que los compromisos futuros «se liberan o anulan»: no elige entre borrar la
  reserva o anularla dejando registro · CU-07 poscondiciones.
- El CU nombra la BDD de autenticación de Firebase; CU-01 valida credenciales «contra la base de
  datos» con `POST /auth/login` · CU-07 objetivo, CU-01 paso 3–4.
