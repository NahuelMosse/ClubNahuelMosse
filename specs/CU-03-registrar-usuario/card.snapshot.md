---
card: CU-03
extraido: 2026-09-27T10:55:32-03:00
fuentes:
  - CU/CU-03 Registrar usuario.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 1 Registración · § RF 2 Perfil de usuario · § RF 7 Manejo de errores"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 32:124 CU-03 · Registro · Formulario vacío"
  - "Figma · 34:546 CU-03 · Registro · Campos vacíos"
  - "Figma · 34:443 CU-03 · Registro · Datos ingresados"
  - "Figma · 34:647 CU-03 · Registro · Usuario ya registrado"
  - "Figma · 35:312 CU-03 · Registro · Exitoso"
  - "Figma · 29:27 CU-01 · Login · Vacío (origen: «¿No tenés cuenta? COMENZAR →»)"
no_leido:
  - "las imágenes de pantalla embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-03 · Registrar usuario

## Card, tal como está escrita

**Definición** (fuente: CU-03)
- Actor principal: Usuario.
- Objetivo: «Permitir que un nuevo usuario cree una cuenta dentro de la aplicación móvil ingresando
  su nombre, apellido, dni, fecha de nacimiento, correo electrónico y contraseña, para así poder
  acceder a la plataforma y realizar reservas deportivas.»
- Problema que resuelve: «Resuelve la necesidad de autenticar e identificar de manera única a los
  usuarios en el sistema, permitiéndoles acceder a funcionalidades personalizadas como la consulta
  de disponibilidad, gestión de reservas y edición del perfil de usuario.»

**Precondiciones** (fuente: CU-03)
- La aplicación móvil debe estar instalada y ejecutándose en el dispositivo.
- El dispositivo debe contar con conexión activa a internet.

**Poscondiciones** (fuente: CU-03)
- Se crea con éxito la cuenta del usuario en la base de datos y backend del sistema.
- El sistema devuelve al usuario a la pantalla de login.

**Flujo principal** (fuente: CU-03)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El usuario selecciona la opción para registrarse. | El sistema muestra el formulario de registro solicitando nombre, apellido, dni, fecha de nacimiento, correo electrónico y contraseña. |
| 2 | El usuario ingresa los datos y presiona el botón de "crear cuenta". | El sistema valida el formato de los datos ingresados y envía la solicitud al servidor/backend. |
| 3 | El backend procesa la solicitud, crea el nuevo perfil de usuario y autentica la sesión. | El sistema notifica al usuario que su cuenta fue registrada con exito. |
| 4 | El usuario presiona el boton de "Volver al login". | El sistema carga la pantalla de inicio de sesion de la aplicacion. |

**Flujos alternativos y de excepción** (fuente: CU-03)
- **FA1 · Datos incompletos.** Origen: paso 2. Condición: falta completar algún campo obligatorio.
  Sistema: «Se muestra un mensaje/tooltip en pantalla indicando los campos faltantes».
- **FA2 · Usuario ya registrado.** Origen: paso 3. Condición: «El correo electrónico y/o el dni
  ingresado ya se encuentra registrado previamente en la base de datos del sistema». Sistema: «El
  sistema retorna un mensaje de error indicando que el usuario ya está registrado, permaneciendo en
  la pantalla de registro para permitir modificar los datos.»

**Diseño declarado en el CU** (fuente: CU-03)
- Pantallas: login · inicio de registro · datos parciales · error campos vacíos · datos ingresados ·
  usuario ya registrado · usuario cambia email y dni · exitoso.
- Botones «Crear cuenta», «Volver» (al login) y «Volver al login». Campos nombre, apellido, dni,
  email y contraseña. Mensaje de error al no completar todos los campos o al registrar un usuario
  existente.

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 1: «Registro de usuarios mediante correo electrónico y contraseña.»
- RF 2: «El perfil deberá incluir, como mínimo, nombre, apellido y fecha de nacimiento.»
- RF 7: manejar errores como «sin conexión a internet, servidor caído, […] usuario ya registrado».

**Pantallas del prototipo** (fuente: Figma)
- Formulario con NOMBRE, APELLIDO, DNI, FECHA DE NACIMIENTO (DD / MM / AAAA), CORREO ELECTRÓNICO y
  CONTRASEÑA («Mínimo 8 caracteres»); leyenda «Todos los campos son obligatorios.»
- Error por campo: «El DNI es obligatorio», «La fecha de nacimiento es obligatoria», «La
  contraseña es obligatoria».
- Ya registrado: banner «El usuario ya está registrado. Modificá el correo o el DNI.» y marca por
  campo «Este DNI ya está registrado», «Este correo ya está registrado».
- Éxito: «¡Cuenta creada!» · «Tu cuenta se registró con éxito. Ya podés iniciar sesión con tu
  correo y contraseña.» · «VOLVER AL INICIO DE SESIÓN».

## Escenarios

- [ ] CU-03-H01-01 — completa todos los datos, crea la cuenta y vuelve al login
- [ ] CU-03-H01-02 — con la cuenta recién creada puede iniciar sesión
- [ ] CU-03-H02-01 — deja campos obligatorios vacíos y ve cuáles faltan, sin que se cree la cuenta
- [ ] CU-03-H03-01 — se registra con un correo que ya tiene cuenta y queda en el formulario con el error
- [ ] CU-03-H03-02 — se registra con un DNI que ya tiene cuenta y queda en el formulario con el error

## Contradicciones dentro de la card

- El paso 3 dice que el backend «autentica la sesión»; la poscondición y el paso 4 devuelven al
  usuario al login · CU-03 paso 3, poscondiciones.
- El CU pide validar «el formato de los datos» sin decir qué formato; el prototipo sugiere
  «Mínimo 8 caracteres» para la contraseña y CU-04 fija tres reglas (8 caracteres, una mayúscula,
  un número) · CU-03 paso 2, Figma 32:124, CU-04 paso 3.
- El CU lista la pantalla «usuario cambia email y dni»; el prototipo no la tiene · CU-03 diseño,
  Figma sección Autenticación.
