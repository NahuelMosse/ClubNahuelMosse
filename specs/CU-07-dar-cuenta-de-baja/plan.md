# Implementation Plan: CU-07 · Dar cuenta de baja

**Branch**: `card/CU-07` | **Date**: 2026-09-27 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

En Mi perfil, «ELIMINAR CUENTA» abre la confirmación del prototipo (42:274). Al confirmar, el
botón del perfil pasa a «ELIMINANDO TU CUENTA…» y la app pide `DELETE /yo`. La API hace una baja
lógica (decisión 4): la cuenta deja de estar activa, sus reservas que todavía no empezaron pasan a
canceladas por la misma persona y el historial se conserva; la cuenta de Firebase se borra, así
que el correo y el DNI quedan libres. La app cierra la sesión y vuelve al login. Cancelar, quedarse
sin conexión o una falla del servidor dejan la cuenta como estaba.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: `usuario.activo` y `dado_de_baja_en`; `reserva.estado`, `cancelada_en`,
`cancelada_por` (MOD-01)
**Testing**: escenario de API para la reserva que se libera (no hay todavía reservas por la app);
`integration_test` con la API intermedia lenta, cortada o que falla

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Seis escenarios; pantallas 42:274 y 43:488 (decisión 12) |
| II · Nada se supone en silencio | `CU-07-SUP-01` a `SUP-05`; AMB-03 y AMB-06 resueltas por decisiones 3 y 4 |
| III · Tests antes del código | 4 escenarios de pantalla y 1 de API en rojo; H02-01 nació en verde porque cancelar lo trajo CU-05 |
| IV · El backend es la autoridad | La baja y la cancelación de reservas son una transacción de la API |
| V · Rastro | `dado_de_baja_en`; cada reserva cancelada guarda cuándo y quién |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-07-SUP-01 | Correo y DNI quedan libres para una cuenta nueva | índices únicos sólo entre activas (MOD-01); `test_la_baja_es_logica_…` |
| CU-07-SUP-02 | Alcanza con confirmar el diálogo | `_ConfirmarBaja` |
| CU-07-SUP-03 | El administrador no se da de baja: 403 | `dar_de_baja`; `test_un_administrador_no_se_da_de_baja` |
| CU-07-SUP-04 | Se cancelan las reservas que no empezaron; la que está en curso termina | `UsuariosSql.dar_de_baja`; `test_la_baja_es_logica_…` |
| CU-07-SUP-05 | Sin notificaciones por esas cancelaciones | — |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/aplicacion/baja.py` | `dar_de_baja` | sólo el rol usuario; una segunda baja no toca Firebase; si borrar la cuenta de Firebase falla, la baja queda hecha y se registra en el log |
| `apps/api/app/infraestructura/usuarios.py` | `UsuariosSql.dar_de_baja` | una transacción que primero desactiva la cuenta (si ya estaba de baja no hace nada más) y después cancela sus reservas futuras: ese orden de bloqueo impide que una reserva nueva quede activa para la cuenta. Crear reservas (CU-09) tiene que tomar la fila del usuario activo con `FOR SHARE` |
| `apps/api/app/interfaz/sesion.py` | `DELETE /yo` | 204 · 401 · 403 |
| `apps/mobile/lib/api/cliente_api.dart` | `ClienteApi.delete` | — |
| `apps/mobile/lib/sesion/sesion.dart` | `Sesion.darDeBaja` | después del 204 cierra la sesión de Firebase del teléfono, sólo si sigue siendo la misma que pidió la baja |
| `apps/mobile/lib/usuarios/pantalla_mi_perfil.dart` | confirmación y «ELIMINANDO TU CUENTA…» | mientras espera, ELIMINAR CUENTA y CERRAR SESIÓN quedan deshabilitados; un 401 al reintentar después de un corte es la baja que ya se hizo y lleva al login |
| `apps/mobile/lib/comun/boton.dart` | `BotonPeligro` | el rojo del modo claro en los dos modos: con el del oscuro el texto blanco no llega a 4,5:1 |
| `apps/mobile/integration_test/soporte/red.dart` | modo «lenta» de la API intermedia | — |

## Brief visual

**Invención 1 · densidad 1.** Una confirmación destructiva como las de cualquier app.

- **Confirmación.** Ícono de advertencia, título, qué se pierde, ELIMINAR CUENTA en rojo arriba y
  CANCELAR de contorno debajo; entra igual en los dos teléfonos.
- **Procesando.** El botón del perfil cambia el texto y queda deshabilitado.
- **Variables visuales.** Rojo = no se deshace.
