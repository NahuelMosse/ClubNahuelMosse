# Implementation Plan: CU-04 · Cambiar contraseña

**Branch**: `card/CU-04` | **Date**: 2026-09-27 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

Desde Mi perfil, «Cambiar contraseña» abre el formulario del prototipo: contraseña actual, nueva
con sus tres reglas en vivo y repetición. La API es la que cambia la contraseña: valida las reglas,
comprueba la actual contra Firebase, la reemplaza, invalida todas las sesiones de la cuenta y deja
el rastro del cambio. La app vuelve a entrar con la nueva, así la sesión del teléfono sigue abierta,
y muestra «Contraseña actualizada». Cualquier otra sesión ve «Tu sesión expiró» en su próximo
pedido.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Primary Dependencies**: firebase-admin (`update_user`, `revoke_refresh_tokens`); la API REST de
Identity Toolkit para comprobar la contraseña actual (`urllib`, sin dependencias nuevas)
**Storage**: `usuario.contrasena_cambiada_en` (migración 0002)
**Testing**: pytest contra el emulador de Auth · `integration_test` con una API intermedia en el
dispositivo que se corta o falla después de iniciar sesión
**Constraints**: en producción la API necesita `FIREBASE_API_KEY` (la clave web del proyecto) para
comprobar contraseñas; no se guarda en el repo. Firebase cuenta la revocación por segundos

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Ocho escenarios; textos del prototipo (decisión 12) |
| II · Nada se supone en silencio | `CU-04-SUP-01` a `SUP-04`; AMB-05 y AMB-06 resueltas por decisión |
| III · Tests antes del código | 8 escenarios de pantalla commiteados en rojo |
| IV · El backend es la autoridad | La API valida las reglas y la contraseña actual; la app no toca Firebase para cambiarla |
| V · Rastro | `contrasena_cambiada_en` en la base |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-04-SUP-01 | Se acepta una nueva igual a la actual | `test_una_nueva_igual_a_la_actual_se_acepta` |
| CU-04-SUP-02 | El administrador cambia su contraseña por Recuperar contraseña | la tarjeta del admin no lleva a Mi perfil (CU-02-SUP-02) |
| CU-04-SUP-03 | Sin tope propio de intentos: el freno de Firebase es 429 y se ve el error del servidor | `Demorado`; `test/pantalla_cambiar_contrasena_test.dart` |
| CU-04-SUP-04 | La otra sesión ve «Tu sesión expiró» en su próximo pedido | `@CU-04-H07-01` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/migraciones/versions/0002_cambio_de_contrasena.py` | columna `contrasena_cambiada_en` | — |
| `apps/api/app/aplicacion/contrasena.py` | `cambiar_contrasena(perfil, actual, nueva, …)` | primero las reglas y después la actual: una nueva débil no gasta un intento contra Firebase; si el rastro falla se registra en el log y el cambio se informa hecho |
| `apps/api/app/infraestructura/identidad.py` | `contrasena_correcta` (REST `signInWithPassword`) y `cambiar_contrasena` (`update_user` + `revoke_refresh_tokens`) | `TOO_MANY_ATTEMPTS` es `Demorado`; cualquier otra falla del proveedor antes del cambio es 500. Hecho el `update_user`, la revocación y el rastro no pueden convertir la respuesta en error. Las llamadas a Firebase esperan 4 s como mucho, menos que los 15 s de la app |
| `apps/api/app/interfaz/sesion.py` | `PUT /yo/contrasena` | 204 · 401 · 422 `{errores: {actual|nueva: mensaje}}` · 429 |
| `apps/mobile/lib/sesion/sesion.dart` | `Sesion.cambiarContrasena` | después del 204 vuelve a entrar con la nueva; si eso falla, la contraseña ya cambió y el próximo pedido avisa que la sesión venció |
| `apps/mobile/lib/usuarios/pantalla_cambiar_contrasena.dart` | formulario, reglas en vivo, éxito | los tres campos habilitados desde el principio; el error del servidor de un campo se va al editarlo; la repetición se marca al salir del campo o cuando ya es tan larga como la nueva |
| `apps/mobile/lib/usuarios/pantalla_mi_perfil.dart` | bloque SEGURIDAD con «Cambiar contraseña» | se apila sobre el perfil |
| `apps/mobile/lib/comun/dialogo_error.dart` | el `Modal` del prototipo para conexión, servidor y sesión expirada | un solo modal: ícono en círculo, título y texto centrados, hasta dos acciones |
| `apps/mobile/integration_test/soporte/red.dart` | API intermedia y consultas a Firebase para los escenarios | — |

## Brief visual

**Invención 1 · densidad 3.** Un formulario de contraseña como los de cualquier app.

- **Formulario.** En el teléfono chico entran los tres campos y el botón queda fijo abajo, en la
  barra de acción; las reglas aparecen entre la nueva y la repetición sólo mientras falta alguna.
- **Éxito.** Ícono verde en círculo, título, texto y «VOLVER AL PERFIL», centrados.
- **Variables visuales.** Verde = regla cumplida o cambio hecho; rojo = lo que falta o está mal;
  lima = la acción. El botón deshabilitado al 40 % dice que todavía falta algo.
- **Material.** El de las cards anteriores: Inter, superficie `bg/surface` para las reglas con
  radio 12, campos pill, barra de acción en `bg/surface-raised` con línea fina arriba.
