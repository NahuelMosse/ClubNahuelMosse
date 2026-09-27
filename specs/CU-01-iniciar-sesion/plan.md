# Implementation Plan: CU-01 · Iniciar sesión

**Branch**: `card/CU-01` | **Date**: 2026-09-27 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

Inicio de sesión con correo y contraseña contra Firebase Authentication. Con la contraseña
aceptada, la app pide a la API `GET /yo` con el ID token: la API valida el token, busca el perfil
activo y devuelve nombre y rol. Un usuario entra al Home y un administrador al panel de
administración; el rol sale de la cuenta, no de un selector (decisión 2). Campos vacíos se marcan
por campo sin llamar a nadie; credenciales inválidas muestran el aviso genérico del prototipo; sin
red o con el servidor caído aparecen los overlays compartidos. La sesión queda guardada en el
dispositivo y se retoma al abrir la app (decisión 14). La primera cuenta de administrador se
siembra con un comando.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Primary Dependencies**: FastAPI, firebase-admin (`verify_id_token`) · firebase_core 4,
firebase_auth 6, go_router
**Storage**: PostgreSQL, tabla `usuario` (columna `rol` de MOD-01); cuentas en Firebase Auth
**Testing**: pytest contra PostgreSQL y el emulador de Firebase Auth · `integration_test` en un
emulador de Android contra la API, el emulador de Auth y un admin sembrado por `scripts/e2e.sh`
**Target Platform**: Android (API 23+)
**Constraints**: firebase-auth 24.2 trae metadatos de Kotlin 2.3: el plugin de Kotlin de Android
pasa a 2.3.21 y `jvmTarget` al DSL de `compilerOptions`

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Nueve escenarios del snapshot; textos del prototipo (decisión 12) |
| II · Nada se supone en silencio | `CU-01-SUP-01` a `SUP-05`; AMB-02, 03, 06, 08 y 09 resueltas por decisión |
| III · Tests antes del código | 9 escenarios de pantalla commiteados en rojo |
| IV · El backend es la autoridad | La API no confía en la app: valida el token y exige perfil activo en cada pedido |
| V · Rastro | Sin campos nuevos: el último ingreso lo lleva Firebase (`CU-01-SUP-04`) |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-01-SUP-01 | La app no valida el formato del correo; el que Firebase rechaza cae en el aviso genérico | `CredencialesFirebase._rechazos` (`invalid-email`) |
| CU-01-SUP-02 | Sin bloqueo propio; el freno de Firebase (`too-many-requests`) muestra el aviso genérico | `CredencialesFirebase._rechazos` |
| CU-01-SUP-03 | El correo viaja sin espacios alrededor y en minúsculas | `Sesion.iniciar`; `@CU-01-H01-01` |
| CU-01-SUP-04 | No se guarda último ingreso ni intentos fallidos en la base | — |
| CU-01-SUP-05 | Cuenta de Firebase sin perfil activo: no entra, se cierra la sesión de Firebase y se ve el aviso genérico | `perfil_autenticado`; `test_una_cuenta_dada_de_baja…` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/dominio/usuarios.py` | `Perfil` y `Rol` | — |
| `apps/api/app/aplicacion/sesion.py` | `perfil_autenticado(token, identidad, usuarios)` | sin token no se consulta al proveedor; sin perfil activo es `NoAutenticado` |
| `apps/api/app/aplicacion/administradores.py` | `sembrar_admin`: crea la cuenta con `registrar`, o asciende la existente | una cuenta que ya existe sólo se asciende con `--promover` y conserva su contraseña: el registro es público |
| `apps/api/app/infraestructura/identidad.py` | `uid_del_token` sobre `verify_id_token(check_revoked=True)` | token inválido, vencido o revocado, o cuenta deshabilitada o borrada → `None`; una falla de red del proveedor es 500 |
| `apps/api/app/infraestructura/usuarios.py` | `perfil_activo`, `id_activo_por_correo`, `hacer_admin` | SQL con `text()` |
| `apps/api/app/interfaz/sesion.py` | dependencia `usuario_actual` y `GET /yo` | 200 `{nombre, apellido, correo, rol}` · 401 con `WWW-Authenticate: Bearer`. Los CU siguientes usan `usuario_actual` para identificar al usuario (RNF 5) |
| `apps/api/app/interfaz/sembrar_admin.py` | comando `python -m app.interfaz.sembrar_admin` | la contraseña llega por `ADMIN_CONTRASENA`, nunca por argumento |
| `apps/mobile/lib/configuracion.dart` | `AUTH_EMULADOR` o las cuatro claves `FIREBASE_*` por `--dart-define` | el emulador usa el proyecto `demo-clubnahuelmosse` |
| `apps/mobile/lib/sesion/firebase.dart` | `iniciarFirebase(configuracion)` | una instancia con nombre por emulador; en Android el último `useAuthEmulator` vale para todas, así que se vuelve a fijar en cada arranque |
| `apps/mobile/lib/sesion/sesion.dart` | `Credenciales` (Firebase y dobles), `Sesion`: iniciar, retomar, cerrar | los códigos de rechazo de Firebase son `CredencialesInvalidas`; `network-request-failed` es `SinConexion`; si `/yo` falla se cierra la sesión de Firebase; al retomar espera a la API 3 s como mucho y sólo cierra la sesión si la cuenta ya no vale |
| `apps/mobile/lib/api/cliente_api.dart` | `get` con `Authorization: Bearer` | mismo manejo de errores que `post` |
| `apps/mobile/lib/sesion/pantalla_inicio_sesion.dart` | login sobre la foto del club | siempre en oscuro; botón siempre habilitado (Figma 30:319); errores por campo al tocar; aviso genérico abajo con X |
| `apps/mobile/lib/comun/snackbar.dart` | `SnackbarError` del prototipo | — |
| `apps/mobile/lib/comun/campo_texto.dart` | etiqueta opcional y `VerContrasena` compartido con el registro | — |
| `apps/mobile/lib/inicio/`, `admin/`, `sesion/pantalla_recuperar_contrasena.dart` | destino de cada flujo: cabecera y título del prototipo | el contenido lo completan TP-01, CU-14 y CU-04b |
| `apps/mobile/lib/app.dart`, `main.dart` | rutas y arranque con la sesión retomada | `/inicio` es del usuario y `/admin` del administrador: sin perfil van al login y con otro rol a su inicio; las rutas escuchan a `Sesion` |
| `apps/mobile/assets/imagenes/login.png` | la foto del login, bajada del nodo 29:27 | — |
| `scripts/e2e.sh` | siembra el admin de la corrida y lo pasa a los tests | credenciales sólo del emulador |

## Brief visual

**Invención 2 · densidad 2.** Es la puerta de entrada: se usa como se usan todos los logins.

- **Login.** Se lee la marca y se completan dos campos. En el teléfono chico tienen que quedar a
  la vista sin scroll los dos campos, «INICIAR SESIÓN» y «COMENZAR»; el grande gana aire bajo el
  pie. El error por campo aparece debajo de cada campo; el aviso genérico, abajo y sin tapar el
  botón.
- **Home, panel, recuperar.** Sólo prueban que se llegó: la cabecera y el título del prototipo.
- **Variables visuales.** El lima dice «acción o marca»; el rojo dice «error». Nada más tiene
  color.
- **Material.** Inter para interfaz y Archivo Black para la marca, como el prototipo. Lienzo: la
  foto oscurecida con el degradé de Figma. Separación por espacio. Radio pill en campos y botones,
  12 en el aviso. Densidad de 12 entre campos y 24 entre bloques.

## Riesgos

- El emulador de Android no simula «sin red» por test: `@CU-01-H06-01` apunta Firebase y la API a
  un puerto donde no escucha nadie, que el SDK reporta como `network-request-failed`, lo mismo que
  sin red.
- `@CU-01-H05-01` levanta en el dispositivo una API que responde 500: Firebase acepta la
  contraseña y la falla llega en `/yo`.
