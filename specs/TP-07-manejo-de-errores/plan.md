# Implementation Plan: TP-07 · Manejo de errores

**Branch**: `card/TP-07` | **Date**: 2026-09-30 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

Toda la app usa los overlays compartidos del prototipo: «Error de conexión» (REINTENTAR y Volver),
«Error del servidor» (ACEPTAR), «Tu sesión expiró», «Acceso denegado» y «Esto cambió mientras
tanto». La mayoría ya estaba en cada pantalla con red; esta card cierra lo que quedaba: «Acceso
denegado» no existía (un usuario en el panel caía en silencio en el Home y un 403 se mostraba como
error del servidor), y tres avisos sueltos («Esta sede ya no está disponible», «Esta cancha ya no
está disponible» ×2) eran un SnackBar. En la API, los errores no quedaban registrados.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Testing**: widget (texto al 200 % en 360), pytest de registro, `integration_test` (rojo pendiente de la pasada final)

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Ocho escenarios; pantallas 42:384, 42:410, 42:426, 42:442, 393:6532 |
| II · Nada se supone en silencio | `TP-07-SUP-01` a `SUP-06`; AMB-07 resuelta |
| III · Tests antes del código | Escenarios congelados en `467a731` |
| IV · El backend es la autoridad | Los 401, 403 y 409 los decide la API; la app sólo los traduce a un aviso |
| V · Rastro | Registro de la API con fecha, operación, código y usuario |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| TP-07-SUP-01 | Las validaciones de formulario son de cada CU | sin cambios; sin cobertura propia |
| TP-07-SUP-02 | Sin cola: REINTENTAR es de la persona | `mostrarErrorDeRed`; `@TP-07-H01-02` |
| TP-07-SUP-03 | «Acceso denegado» cubre `/admin` sin rol y todo 403; lleva a Mis reservas | `PantallaAccesoDenegado`, `mostrarErrorDeRed`; `@TP-07-H06-01` |
| TP-07-SUP-04 | 15 s sin respuesta es «Error de conexión» | `ClienteApi.limite` |
| TP-07-SUP-05 | Sede o cancha que ya no está: «Esto cambió mientras tanto» | `pantalla_sede`, `pantalla_horarios`, `pantalla_confirmar_reserva`; `@TP-07-H07-01` |
| TP-07-SUP-06 | La API registra excepciones, 5xx, 401, 403 y 409 | `RegistroDeErrores`; `test_registro_de_errores.py` |

## Supuestos sin cobertura

| ID | Motivo |
|---|---|
| TP-07-SUP-01 | Es una ausencia: no hay comportamiento nuevo que probar |
| TP-07-SUP-04 | Lo prueba un unitario (`errores_compartidos_test.dart`, límite inyectado); un escenario tardaría 15 s de espera real |

## Perímetro

Auth del emulador de Firebase, API de la corrida e `ApiIntermedia` para cortar la red o hacer fallar
al servidor. Afuera: el log en base de datos, la cola de operaciones sin conexión y la versión de
registro con `If-Match`.

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/mobile/lib/comun/dialogo_error.dart` | `mostrarAccesoDenegado`; un 403 en `mostrarErrorDeRed` | el 403 abre «Acceso denegado» y va a `/reservas`; no se puede descartar |
| `apps/mobile/lib/comun/acceso_denegado.dart` | destino de quien pide una sección de administrador sin serlo | muestra el aviso y al aceptarlo va a `/reservas` |
| `apps/mobile/lib/app.dart` | la ruta `/acceso-denegado` y el redirect por rol | sólo `/admin*` sin rol va al aviso; un administrador en una ruta de usuario sigue yendo a su panel |
| `apps/mobile/lib/api/cliente_api.dart` | `limite` inyectable | 15 s por defecto |
| `apps/mobile/lib/sedes/pantalla_sede.dart`, `apps/mobile/lib/reservas/pantalla_horarios.dart`, `apps/mobile/lib/reservas/pantalla_confirmar_reserva.dart` | el aviso de lo que ya no está | overlay compartido en lugar del SnackBar; nada cargando detrás del aviso |
| `apps/api/app/interfaz/registro_errores.py`, `apps/api/app/main.py` | middleware de registro y su configuración | error para excepciones y 5xx, aviso para 401, 403 y 409; logger `clubnahuelmosse.errores` |
| `apps/api/app/interfaz/sesion.py` | `usuario_actual` deja el id del usuario en el estado del pedido | sin sesión el registro dice «anónimo» |
| `apps/mobile/integration_test/errores/errores_compartidos_test.dart`, `apps/api/tests/escenarios/test_registro_de_errores.py` | escenarios congelados | |
| `apps/mobile/test/errores_compartidos_test.dart`, `apps/mobile/test/horarios_test.dart`, `apps/mobile/test/sedes_usuario_test.dart`, `apps/mobile/test/espacios_admin_test.dart`, `apps/mobile/test/sedes_admin_test.dart`, `apps/mobile/test/tarjeta_cuenta_test.dart` | unitarios del aviso y de los avisos que cambiaron | texto al 200 % en 360 |

## Brief visual

**Invención 1 · densidad 1.** Un único aviso por situación, el del prototipo, igual en todas las
pantallas.

- **Desde dónde.** Desde cualquier pantalla con red; «Acceso denegado» desde el enlace al panel.
- **Teléfono chico.** En 360 y con el texto al 200 % la acción del aviso queda a la vista o a un
  desplazamiento dentro del aviso, sin cortes.
- **Variables visuales.** Ícono en rojo apagado = no se pudo; las acciones son las del prototipo.
- **Material.** Los overlays compartidos de `dialogo_error.dart`.
