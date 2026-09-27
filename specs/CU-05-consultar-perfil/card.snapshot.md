---
card: CU-05
extraido: 2026-09-27T11:20:00-03:00
fuentes:
  - CU/CU-05 - Consultar perfil - Berazategui.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 2 Perfil de usuario · § RNF 5 («Las operaciones de la API relacionadas con usuarios […] deberán identificar al usuario autenticado.»)"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 39:356 CU-05 · Mi perfil · Lectura"
  - "Figma · 71:4566 CU-05 · Mi perfil · Modo claro"
  - "Figma · 43:1422 CU-02 · Tarjeta del avatar (overlay) · 37:147 CU-01 · Home · Usuario"
  - "Figma · 42:384 Error de conexión · 42:410 Error del servidor · 42:426 Sesión expirada (overlays compartidos)"
no_leido:
  - "las imágenes de pantalla embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-05 · Consultar perfil

## Card, tal como está escrita

**Definición** (fuente: CU-05)
- Actor principal: Usuario registrado.
- Objetivo: «Permitir que el usuario autenticado visualice la totalidad de los datos asociados a su
  cuenta y acceda desde una única pantalla a las acciones vinculadas a la misma.»
- Problema que resuelve: verificar qué datos tiene registrados el sistema; sin esta pantalla no
  puede confirmar con qué correo está registrado —«el dato indispensable para recuperar la
  contraseña»— ni detectar errores en sus datos para corregirlos. Concentra los accesos a las
  operaciones sobre la cuenta.

**Precondiciones** (fuente: CU-05)
- El usuario debe estar autenticado en la aplicación.
- La sesión debe contar con un token válido; «el perfil devuelto es siempre el del portador del
  token».
- El dispositivo debe contar con conectividad a Internet, «dado que los datos se obtienen del
  backend y no se persisten localmente».

**Poscondiciones** (fuente: CU-05)
- «El sistema no modifica su estado: el caso de uso no genera altas, bajas ni modificaciones en la
  base de datos.»
- El usuario permanece en la pantalla de perfil con sus datos a la vista.
- «Si el usuario modificó el selector de tema, la preferencia visual queda aplicada en la
  aplicación.»

**Flujo principal** (fuente: CU-05)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El usuario, con sesión iniciada, presiona la pestaña "Perfil" de la barra de navegación inferior. | El sistema solicita al backend los datos del usuario autenticado y navega a la pantalla "Mi perfil". |
| 2 | El usuario aguarda la carga de la pantalla. | El sistema valida el token, recupera el registro correspondiente y muestra el avatar de iniciales, el nombre completo, el correo electrónico y el estado de la membresía. |
| 3 | El usuario consulta el bloque "Datos personales". | El sistema muestra nombre, apellido, DNI, fecha de nacimiento y correo electrónico en modo de solo lectura, señalando el correo como campo no editable, y debajo la fila "Seguridad: Cambiar contraseña". |
| 4 | El usuario, opcionalmente, alterna el selector de modo claro / modo oscuro. | El sistema aplica el tema seleccionado a la totalidad de la aplicación y mantiene al usuario en la misma pantalla. |
| 5 | El usuario finaliza la consulta y navega hacia otra sección o hacia alguna de las acciones vinculadas a la cuenta. | El sistema deriva al caso de uso correspondiente: CU-06 (Editar perfil), CU-04 (Cambiar contraseña, desde la fila "Seguridad"), CU-02 (Logout) o CU-07 (Dar cuenta de baja). |

**Flujos alternativos y de excepción** (fuente: CU-05)
- **FA1 · Acceso desde la tarjeta del avatar.** Origen: paso 1. Condición: accede desde la pantalla
  de inicio en lugar de la barra inferior. Sistema: al presionar el avatar despliega una tarjeta con
  un resumen de los datos y tres accesos: «Perfil completo», «Mis reservas» y «Cerrar sesión». Al
  seleccionar «Perfil completo» navega al perfil y el flujo continúa desde el paso 2.
- **FA2 · Error de conexión a Internet.** Origen: paso 1. Sistema: no ejecuta la solicitud y muestra
  una alerta sobre la falta de conectividad pidiendo reintentar. «No se muestran datos parciales ni
  almacenados en caché.»
- **FA3 · Error en el servidor o falla en la API.** Origen: paso 2. Sistema: informa el error del
  servidor y solicita reintentar más tarde. «La pantalla de perfil no llega a mostrarse con datos.»
- **FA4 · Sesión expirada o token inválido.** Origen: paso 2. Condición: el backend rechaza por
  token vencido o inválido, «o bien la cuenta fue eliminada desde otro dispositivo mediante el
  CU-07». Sistema: considera finalizada la sesión, no expone ningún dato y redirige al Login.

**Diseño declarado en el CU** (fuente: CU-05)
- Pantallas: Home (pestaña «Perfil») · tarjeta del avatar · perfil modo diurno · perfil modo
  nocturno · error de conectividad · error del servidor.
- Botones «Editar», «Cerrar sesión», «Eliminar cuenta», «Aceptar» en los errores. Mensajes: error
  de conexión, error del servidor, confirmación «Contraseña actualizada», indicador «Miembro
  activo».

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 2: «Se deben mostrar todos los datos del perfil de usuario y permitir su edición, salvo la
  dirección de correo electrónico.» «El perfil deberá incluir, como mínimo, nombre, apellido y fecha
  de nacimiento.»

**Pantallas del prototipo** (fuente: Figma)
- Cabecera: iniciales, nombre completo, correo, «MIEMBRO ACTIVO». Bloques DATOS PERSONALES (Nombre,
  Apellido, DNI, Nacimiento, Correo; botón Editar), SEGURIDAD (Cambiar contraseña), APARIENCIA (Modo
  oscuro), y los botones CERRAR SESIÓN y ELIMINAR CUENTA. Barra inferior INICIO · SEDES · RESERVAS ·
  PERFIL.

## Escenarios

- [ ] CU-05-H01-01 — abre Perfil desde la barra inferior y ve sus datos personales y el correo como no editable
- [ ] CU-05-H01-02 — cambia a modo claro y la app entera cambia de tema sin salir del perfil
- [ ] CU-05-H01-03 — desde el perfil llega a Editar perfil, Cambiar contraseña, Cerrar sesión y Eliminar cuenta
- [ ] CU-05-H02-01 — abre el perfil desde «Perfil completo» en la tarjeta del avatar
- [ ] CU-05-H03-01 — sin conexión, ve la alerta de conexión y ningún dato del perfil
- [ ] CU-05-H04-01 — el servidor falla y la pantalla no muestra datos
- [ ] CU-05-H05-01 — con la sesión vencida, no ve datos y la app lo lleva al login

## Contradicciones dentro de la card

- La poscondición dice que el CU «no genera […] modificaciones en la base de datos», y a la vez
  que la preferencia de tema «queda aplicada»; CU-06 declara el cambio de tema como parte de editar
  el perfil · CU-05 poscondiciones, CU-06 paso 5.
- El CU pide «Aceptar» para cerrar los errores; el overlay compartido de error de conexión tiene
  «REINTENTAR» y «Volver» · CU-05 diseño, Figma 42:384.
