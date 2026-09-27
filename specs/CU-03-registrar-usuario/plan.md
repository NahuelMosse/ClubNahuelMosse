# Implementation Plan: CU-03 · Registrar usuario

**Branch**: `card/CU-03` | **Date**: 2026-09-27 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

Registro con nombre, apellido, DNI, fecha de nacimiento, correo y contraseña. La app valida en vivo
y habilita «CREAR CUENTA» sólo con todo completo y válido; la API vuelve a validar, rechaza correo o
DNI repetidos, crea la cuenta en Firebase Authentication y el perfil en PostgreSQL, y la app muestra
«¡Cuenta creada!» y vuelve al inicio de sesión. Es la primera card con pantalla: monta la app
Flutter, el tema del prototipo, la API HTTP y el emulador de Firebase para los tests.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Primary Dependencies**: FastAPI, firebase-admin, email-validator · firebase_core, firebase_auth,
http, go_router
**Storage**: PostgreSQL (tabla `usuario` de MOD-01); cuentas en Firebase Authentication
**Testing**: pytest contra PostgreSQL y el emulador de Firebase Auth · `integration_test` en un
emulador de Android contra la API y el emulador de Firebase
**Target Platform**: Android (API 23+)
**Project Type**: app móvil + API REST
**Constraints**: correo y DNI únicos entre cuentas activas los garantiza la base (MOD-01)

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Cinco escenarios del snapshot; textos de pantalla del prototipo (decisión 12) |
| II · Nada se supone en silencio | Cuatro supuestos `CU-03-SUP-01` a `SUP-04` y cinco ambigüedades resueltas por decisión |
| III · Tests antes del código | 4 escenarios de pantalla y 1 de API commiteados en rojo |
| IV · El backend es la autoridad | La API valida todo otra vez; la unicidad la garantiza la base |
| V · Rastro | `creado_en` lo estampa la base al insertar |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `package.json`, `package-lock.json`, `firebase.json` | `firebase-tools` como dependencia del repo y configuración del emulador | proyecto `demo-clubnahuelmosse`: el emulador no necesita credenciales |
| `.gitignore` | ignora `node_modules` | — |
| `scripts/e2e.sh` | base propia, emulador de Auth, API y emulador de Android; corre `integration_test` y baja lo que levantó | reusa un emulador de Auth que ya escuche; el AVD corre `-read-only` |
| `scripts/test.sh` | suma los unitarios de la app | ya contemplado |
| `apps/api/pyproject.toml`, `uv.lock` | agrega `firebase-admin`, `email-validator`, `httpx2` | — |
| `apps/api/app/config.py` | agrega `firebase_project_id` | el emulador se activa con `FIREBASE_AUTH_EMULATOR_HOST`, que lee firebase-admin |
| `apps/api/app/main.py` | `crear_app()` con los routers | — |
| `apps/api/app/dominio/usuarios.py` | reglas del registro: obligatorios, largo, formato de DNI, fecha pasada, correo, contraseña; normaliza correo y DNI | función pura `validar_registro(datos, hoy) -> dict[campo, mensaje]`; los mensajes son los del prototipo |
| `apps/api/app/aplicacion/registro.py` | caso de uso `registrar` | valida, busca duplicados, crea la cuenta en el proveedor de identidad, inserta el perfil; si el insert falla borra la cuenta creada. Recibe el proveedor y la conexión por parámetro |
| `apps/api/app/aplicacion/errores.py` | `DatosInvalidos(errores)`, `Duplicado(campos)` | — |
| `apps/api/app/infraestructura/db.py` | motor y dependencia de conexión transaccional | un motor por proceso |
| `apps/api/app/infraestructura/identidad.py` | `ProveedorIdentidad` sobre firebase-admin: crear y borrar cuentas | el correo ya usado en Firebase se traduce a `Duplicado(["correo"])` |
| `apps/api/app/infraestructura/usuarios.py` | consultas de `usuario`: duplicados activos e inserción | SQL con `text()` |
| `apps/api/app/interfaz/registro.py` | `POST /registro` | 201 `{id}` · 422 `{errores: {campo: mensaje}}` · 409 `{campos: [...], mensaje}` |
| `apps/api/tests/conftest.py` | fixtures `api`, `iniciar_sesion`, `unico` | la API bajo test usa la base de pruebas y el emulador |
| `apps/api/tests/escenarios/test_registro.py` | `CU-03-H01-02` | congelado |
| `apps/api/tests/unit/test_usuarios.py` | reglas de `validar_registro` con valores escritos a mano | del implementador |
| `apps/api/tests/integracion/test_registro_api.py` | 422, 409 por correo y por DNI, carrera y normalización contra la API real | del implementador |
| `apps/mobile/pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml` | dependencias, fuentes del prototipo empaquetadas, análisis estricto | sin descarga de fuentes en tiempo de ejecución |
| `apps/mobile/assets/fuentes/*.ttf` | Inter, Archivo, Archivo Black, JetBrains Mono | licencia OFL |
| `apps/mobile/android/app/build.gradle.kts`, `src/debug/AndroidManifest.xml` | `minSdk 23` que pide firebase_auth; HTTP plano sólo en debug | — |
| `apps/mobile/lib/main.dart` | arranque: configuración, Firebase y `App` | idempotente, porque los tests lo llaman una vez por escenario |
| `apps/mobile/lib/configuracion.dart` | `API_URL` y `AUTH_EMULADOR` desde `--dart-define` | sin valores por defecto que apunten a producción |
| `apps/mobile/lib/app.dart` | `MaterialApp.router`, tema claro y oscuro, rutas | rutas `/` (inicio de sesión) y `/registro` |
| `apps/mobile/lib/tema/tokens.dart` | los 32 colores del prototipo por modo, escala de espacio y radios | se leen del archivo de Figma, no se inventan |
| `apps/mobile/lib/tema/tema.dart` | `ThemeData` claro y oscuro y los diez estilos de texto | — |
| `apps/mobile/lib/comun/campo_texto.dart` | campo con etiqueta, error e ícono, como el componente `Input` del prototipo | `Semantics(label:)` en lenguaje natural; la etiqueta visual queda fuera de la semántica |
| `apps/mobile/lib/comun/boton.dart` | botón primario y de texto del componente `Btn` | 52 de alto, pill |
| `apps/mobile/lib/comun/barra_superior.dart` | `AppBar` del prototipo con volver | — |
| `apps/mobile/lib/api/cliente_api.dart` | POST a la API con errores tipados | sin conexión y error del servidor como excepciones distintas |
| `apps/mobile/lib/usuarios/reglas_registro.dart` | las mismas reglas que la API, para validar en vivo | los mensajes son los mismos que devuelve la API |
| `apps/mobile/lib/usuarios/pantalla_registro.dart` | formulario, validación al salir de cada campo, envío, errores de duplicado | el botón se habilita sólo con todo válido |
| `apps/mobile/lib/usuarios/pantalla_registro_exitoso.dart` | «¡Cuenta creada!» y volver al inicio de sesión | — |
| `apps/mobile/lib/sesion/pantalla_inicio_sesion.dart` | inicio de sesión con el acceso «COMENZAR» al registro | los campos y el ingreso los completa CU-01 |
| `apps/mobile/integration_test/soporte/acciones.dart` | abrir la app, escribir, tocar y esperar por texto | no está tagueado |
| `apps/mobile/integration_test/registro/registro_test.dart` | `CU-03-H01-01`, `H02-01`, `H03-01`, `H03-02` | congelado |
| `apps/mobile/test/reglas_registro_test.dart` | unitarios de las reglas | del implementador |
| `specs/CU-03-registrar-usuario/*` | plan y tareas | — |

## Supuestos

| ID | Supuesto | Dónde vive |
|---|---|---|
| CU-03-SUP-01 | Correo sin distinguir mayúsculas; DNI sólo dígitos, se aceptan puntos al escribir | `tests/integracion/test_registro_api.py` |
| CU-03-SUP-02 | La cuenta queda activa al crearse, sin verificar el correo | `CU-03-H01-02` (inicia sesión apenas creada) |
| CU-03-SUP-03 | Sin edad mínima; nombre y apellido de hasta 60 caracteres | `tests/unit/test_usuarios.py` |
| CU-03-SUP-04 | Con dos registros simultáneos del mismo correo o DNI, el segundo recibe 409 | `tests/integracion/test_registro_api.py` |

## Supuestos sin cobertura

Ninguno.

## Perímetro

- **Auth**: Firebase Authentication. En los tests, el emulador con el proyecto
  `demo-clubnahuelmosse`; producción necesita credenciales de servicio, que se configuran en el
  despliegue (RNF-01), no acá.
- **Mocks**: ninguno en los escenarios. Los unitarios de la regla no tocan red.
- **Afuera**: iniciar sesión (CU-01), sin conexión y servidor caído con los overlays compartidos
  (TP-07), recuperar contraseña (CU-04b).

## Brief visual

Referencia: `CU-03 · Registro · Formulario vacío` (32:124), `Campos vacíos` (34:546), `Datos
ingresados` (34:443), `Usuario ya registrado` (34:647) y `Exitoso` (35:312).

- **Formulario**: la persona tiene que ver los seis campos en orden y saber que son obligatorios
  («Todos los campos son obligatorios.»). En el teléfono chico el botón puede quedar debajo del
  pliegue; el título y el primer campo no.
- **Errores**: cada error va debajo de su campo, en `state/danger-ink`, con el borde del campo en
  `border/error`. El duplicado agrega un aviso arriba del título.
- **Éxito**: pantalla completa centrada con el título, la explicación y un solo botón.
- **Material**: fondo `bg/base`; campos pill de 52 en `bg/surface` con borde `border/control`;
  etiquetas en Overline; título en Archivo ExtraBold 24; botón primario lima con texto oscuro.
  Deshabilitado, el botón baja de opacidad como `Btn/State=Disabled`.
- **Modo claro**: los mismos tokens en su modo Light; el lima como superficie, nunca como texto.
