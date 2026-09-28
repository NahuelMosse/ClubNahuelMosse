# Implementation Plan: CU-05 · Consultar perfil

**Branch**: `card/CU-05` | **Date**: 2026-09-27 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

La pestaña PERFIL de la barra inferior, o «Perfil completo» de la tarjeta del avatar, abre Mi
perfil. Cada vez que se abre, la app pide el perfil a la API (`GET /yo`, ahora con DNI y fecha de
nacimiento) y recién entonces muestra la cabecera, los datos personales en modo lectura con el
correo marcado como no editable, SEGURIDAD, APARIENCIA y las salidas de la cuenta. Sin conexión,
con el servidor caído o con la sesión vencida no se muestra ningún dato. El selector de modo
oscuro cambia el tema de toda la app y queda guardado en el dispositivo.

«Editar» abre el modo edición y «ELIMINAR CUENTA» abre su confirmación: guardar los cambios y
confirmar la baja son de CU-06 y CU-07, las cards siguientes.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Primary Dependencies**: shared_preferences (el tema en el dispositivo)
**Storage**: sin cambios en la base
**Testing**: `integration_test` con la API intermedia para los errores; tests de widget con la
`App` real

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Siete escenarios; pantalla del prototipo 39:356 y 71:4566 (decisión 12) |
| II · Nada se supone en silencio | `CU-05-SUP-01` a `SUP-03`; AMB-04 resuelta por decisión 11 |
| III · Tests antes del código | 7 escenarios de pantalla commiteados en rojo |
| IV · El backend es la autoridad | El perfil sale siempre de la API y del portador del token; no hay copia local |
| V · Rastro | No aplica: consultar no modifica nada |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-05-SUP-01 | Un dato vacío se muestra «—» | `_FilaDato` |
| CU-05-SUP-02 | El único estado visible es «MIEMBRO ACTIVO» | `_Cabecera` |
| CU-05-SUP-03 | El tema se guarda en el dispositivo y arranca en oscuro | `Apariencia`; `test/perfil_test.dart` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/interfaz/sesion.py`, `dominio/usuarios.py`, `infraestructura/usuarios.py` | `GET /yo` devuelve también `dni` y `fecha_nacimiento` | — |
| `apps/mobile/lib/sesion/sesion.dart` | `Perfil` con DNI y fecha; `Sesion.refrescar` | un perfil sin esos datos es un error del servidor |
| `apps/mobile/lib/comun/apariencia.dart` | el tema claro u oscuro de toda la app | `shared_preferences`; los escenarios lo borran al abrir la app |
| `apps/mobile/lib/comun/barra_inferior.dart` | `BottomNav`: INICIO, SEDES, RESERVAS, PERFIL | — |
| `apps/mobile/lib/usuarios/pantalla_mi_perfil.dart` | cabecera, datos, SEGURIDAD, APARIENCIA, salidas | se pide a la API al abrir; mientras se muestra un error la pantalla queda vacía y «Volver» o «ACEPTAR» llevan al inicio; una sesión vencida se cierra aunque la persona ya haya salido del perfil; toda la fila «Modo oscuro» alterna el tema |
| `apps/mobile/lib/usuarios/reglas_registro.dart` | `dniLegible` y `fechaLegible` | — |
| `apps/mobile/lib/tema/tokens.dart` | `bg/hero-from` para el degradé de la cabecera | valores de la colección `Color` del prototipo |
| `apps/mobile/lib/sedes/pantalla_sedes.dart` | destino de la pestaña SEDES | el listado lo suma CU-16 |

## Brief visual

**Invención 1 · densidad 4.** Una pantalla de cuenta como las de cualquier app.

- **Perfil.** En el teléfono chico se ven la cabecera y el bloque de datos personales; SEGURIDAD,
  APARIENCIA y las salidas quedan con scroll. El grande muestra además SEGURIDAD.
- **Variables visuales.** Gris apagado + candado = dato que no se puede cambiar; rojo = acción que
  no se deshace (ELIMINAR CUENTA); lima = identidad y pestaña activa.
- **Material.** Degradé `bg/hero-from` → `bg/base` en la cabecera; tarjetas `bg/surface` con borde
  fino y radio 20; filas de 52.
