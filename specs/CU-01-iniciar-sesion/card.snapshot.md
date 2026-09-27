---
card: CU-01
extraido: 2026-09-27T10:55:32-03:00
fuentes:
  - CU/CU - 01 Login - Acosta Noemi.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 1 Registración, inicio de sesión y recuperación de contraseña · § RF 7 Manejo de errores · § RNF 5 Cloud"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 29:27 CU-01 · Login · Vacío"
  - "Figma · 30:319 CU-01 · Login · Campos incompletos"
  - "Figma · 30:365 CU-01 · Login · Credenciales inválidas"
  - "Figma · 30:429 CU-01 · Login · Rol administrador"
  - "Figma · 37:147 CU-01 · Home · Usuario"
  - "Figma · 42:384 Compartido · Error de conexión (overlay) · 42:410 Compartido · Error del servidor (overlay)"
no_leido:
  - "las imágenes de pantalla embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-01 · Iniciar sesión

## Card, tal como está escrita

**Definición** (fuente: CU-01)
- Actor principal: Usuario registrado.
- Objetivo: «Autenticarse en la plataforma ingresando email y contraseña para acceder a las
  funcionalidades de reserva de espacios deportivos.»
- Problema que resuelve: «Permite identificar de forma segura al usuario y habilitar el acceso a su
  cuenta, sus reservas y sus datos personales.»

**Precondiciones** (fuente: CU-01)
- El usuario debe tener una cuenta registrada previamente en el sistema.
- El dispositivo debe contar con conexión a internet y acceso al backend (API de autenticación).

**Poscondiciones** (fuente: CU-01)
- El usuario queda autenticado y es redirigido a la pantalla principal (Home).
- Se valida la sesión del usuario para las siguientes solicitudes a la API.

**Flujo principal** (fuente: CU-01)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El usuario ingresa su email y su contraseña. | El sistema habilita los campos de texto correspondientes. |
| 2 | El usuario presiona "Iniciar sesión". | |
| 3 | — | El sistema envía las credenciales al backend (POST /auth/login). |
| 4 | — | El sistema valida las credenciales contra la base de datos. El sistema autentica correctamente y redirige al usuario a la pantalla Home. |

**Flujos alternativos y de excepción** (fuente: CU-01)
- **FA1 · Campos incompletos.** Origen: paso 2. Condición: el usuario deja vacío el campo de email,
  el de contraseña, o ambos. Sistema: «Muestra un mensaje de error indicando que debe completar
  email y contraseña. No se envía la solicitud al backend.»
- **FA2 · Credenciales inválidas.** Origen: paso 3. Condición: el email no está registrado o la
  contraseña no coincide con la registrada. Sistema: «Muestra un mensaje de error genérico ("No se
  pudo iniciar sesión"), sin indicar cuál de los dos datos es incorrecto, por seguridad.»
- **FA3 · Olvidó su contraseña.** Origen: cualquier momento antes de confirmar el login. Condición:
  el usuario presiona el enlace "¿Olvidaste tu contraseña?". Sistema: redirecciona a la pantalla de
  Recuperar Contraseña.
- **FA4 · Error del servidor.** Origen: paso 2. Condición: el dispositivo sí tiene conexión, pero el
  backend no responde o devuelve un error interno. Sistema: «Muestra un mensaje indicando que hubo
  un error en el servidor y solicita reintentar más tarde.»
- **FA5 · Error de conectividad.** Origen: paso 2. Condición: el dispositivo no tiene conexión a
  internet (sin wifi o datos móviles). Sistema: «Muestra un mensaje indicando que no hay conexión a
  ninguna red y solicita reestablecerla.»

**Diseño declarado en el CU** (fuente: CU-01)
- P-01 Login Usuario: formulario vacío, error de campos incompletos, error de credenciales
  inválidas, error de conectividad, error del servidor.
- P-02 Recuperar Contraseña: formulario de solicitud y confirmación de envío.
- Componentes: Btn-Primary «INICIAR SESIÓN» deshabilitado mientras carga; Input-Email;
  Input-Password con mostrar/ocultar; Inline-Error para campos incompletos y credenciales
  inválidas; Modal-Error para conectividad y servidor.

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 1: «Registro de usuarios mediante correo electrónico y contraseña.» «Una vez iniciada la
  sesión, la aplicación deberá mostrar una página inicial (Home Page).»
- RF 7: manejar errores como «sin conexión a internet, servidor caído, login incorrecto».
- RNF 5: «Se podrán utilizar servicios como […] Firebase para autenticación». «Las operaciones de
  la API relacionadas con usuarios y reservas deberán identificar al usuario autenticado.»

**Pantallas del prototipo** (fuente: Figma)
- `CU-01 · Login · Vacío`, `· Campos incompletos`, `· Credenciales inválidas`,
  `· Rol administrador`, `CU-01 · Home · Usuario`, y los overlays compartidos de error de conexión
  y de error del servidor.

## Escenarios

- [ ] CU-01-H01-01 — inicia sesión con correo y contraseña correctos y llega al Home
- [ ] CU-01-H02-01 — intenta ingresar con el correo vacío y no se envía nada al backend
- [ ] CU-01-H02-02 — intenta ingresar con la contraseña vacía y no se envía nada al backend
- [ ] CU-01-H03-01 — ingresa un correo que no está registrado y ve el mensaje genérico
- [ ] CU-01-H03-02 — ingresa una contraseña incorrecta y ve el mismo mensaje genérico
- [ ] CU-01-H04-01 — toca «¿Olvidaste tu contraseña?» y llega a Recuperar contraseña
- [ ] CU-01-H05-01 — el servidor falla al iniciar sesión y se le pide reintentar más tarde
- [ ] CU-01-H06-01 — sin conexión a internet, se le pide restablecer la conexión

## Contradicciones dentro de la card

- El CU valida las credenciales «contra la base de datos» vía `POST /auth/login`; el enunciado
  propone Firebase para autenticación · CU-01 paso 3–4, enunciado RNF 5.
- El prototipo pone en el login un selector «Usuario / Administrador» y una pantalla
  `CU-01 · Login · Rol administrador`; el CU sólo declara como actor al usuario registrado y no
  dice cómo entra un administrador ni si el rol lo elige quien inicia sesión · CU-01 definición,
  Figma 29:27 y 30:429.
- El CU fija el mensaje genérico «No se pudo iniciar sesión»; el prototipo dice «No se pudo iniciar
  sesión. Revisá tus datos e intentá de nuevo.» · CU-01 FA2, Figma 30:365.
- El CU muestra un único mensaje para campos incompletos («debe completar email y contraseña»); el
  prototipo marca cada campo por separado («Completá tu correo electrónico», «Completá tu
  contraseña») · CU-01 FA1, Figma 30:319.
