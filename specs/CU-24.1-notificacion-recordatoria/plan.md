# Implementation Plan: CU-24.1 · Recibir notificación recordatoria

**Branch**: `card/CU-24.1` | **Date**: 2026-09-30 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

Una hora antes del inicio de una reserva activa, la API registra un aviso «Tu reserva es en 1 hora»
en el centro de notificaciones del usuario y lo manda por push a sus dispositivos con permiso. El
aviso no se agenda como tarea: un barrido periódico lo deriva de las reservas vigentes, así que una
reserva cancelada, anulada o movida deja de recibirlo o lo recibe para su horario nuevo sin que
esos flujos cambien. En la app, una campana con contador abre el centro (agrupado por día, no
leídas marcadas, estado «Notificaciones desactivadas» con la acción para activar), y con la app
abierta aparece un panel superior con las no leídas y «Marcar todas». Tocar un aviso abre Mis
reservas con esa reserva resaltada.

El modelo (`notificacion`, `dispositivo`, el centro y el panel) sirve también a CU-24.2 y CU-24.3:
el tipo de notificación admite los tres y la app ya dibuja las tres variantes; sólo se implementa
el disparo de 24.1.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: tablas nuevas `dispositivo` y `notificacion` (migración 0005)
**Push**: puerto `CanalPush` en la aplicación; `CanalNulo` por defecto, `CanalFcm`
(`firebase_admin.messaging`, ya dependencia) sólo con `GOOGLE_APPLICATION_CREDENTIALS` en el
entorno. En la app, puerto `SistemaDeNotificaciones` con `SistemaSimulado` (emulador de Auth) y
`SistemaFcm` (`firebase_messaging`)
**Testing**: pytest (escenarios con un canal de prueba y reloj propio; unitarios; integración de la
API), widget tests a 360 con texto al 200 %, capturas, `integration_test` con
`/_pruebas/recordatorios`

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Diez escenarios; pantallas 65:401, 65:470, 43:1462 |
| II · Nada se supone en silencio | `CU-24.1-SUP-01` a `SUP-15`; AMB-04, 07 y 08 resueltas por decisiones 10 y 14 |
| III · Tests antes del código | Diez escenarios congelados en rojo (evento `CU-24.1-TESTS` de `ambiguedades.md`) |
| IV · El backend es la autoridad | La API decide cuándo vence el aviso, a quién llega y qué queda leído; la app no usa su reloj |
| V · Rastro | `creada_en`, `enviada_en`, `leida_en`, `envio`; `dispositivo` con alta, baja y permiso |

**Arquitectura.** Los dos puertos tienen dos implementaciones cada uno y un eje de variación real
(credenciales que hoy no existen), así que la interfaz no es indirección vacía. El barrido no lleva
cola ni caché: consulta la fuente de verdad. El dominio no importa nada de afuera.

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-24.1-SUP-01 | El centro vacío dice «Todavía no tenés notificaciones» | `PantallaNotificaciones`; `notificaciones_test.dart` |
| CU-24.1-SUP-02 | Sin reintento propio; un envío fallido queda `fallida` y un token inválido se da de baja | `enviar_recordatorios`; `tests/unit/test_recordatorios.py` |
| CU-24.1-SUP-03 | Leída al tocarla o con «Marcar todas»; abrir el centro no marca | `@CU-24.1-H01-02`, `@CU-24.1-H04-01` |
| CU-24.1-SUP-04 | Más nueva a más vieja, agrupado HOY / AYER / dd/mm, sin purga | `agruparPorDia`; `notificaciones_test.dart` |
| CU-24.1-SUP-05 | Se estampan creada, enviada y leída | migración 0005; `tests/integracion/test_notificaciones_api.py` |
| CU-24.1-SUP-06 | Push detrás de un puerto; FCM sólo con credenciales | `canal_push`; `tests/unit/test_recordatorios.py` |
| CU-24.1-SUP-07 | El aviso se deriva de las reservas y el barrido corre cada 30 s; si el servidor estuvo caído sale tarde | `NotificacionesSql.vencidos`; `tests/unit/test_recordatorios.py` |
| CU-24.1-SUP-08 | El permiso lo informa la app por dispositivo; sin permiso queda sólo en el centro | `@CU-24.1-H03-01`; cierre de sesión en `notificaciones_test.dart` |
| CU-24.1-SUP-09 | Panel con no leídas y «Marcar todas»; se detecta consultando la API cada 20 s | `@CU-24.1-H02-01` |
| CU-24.1-SUP-10 | Campana con contador en el Home; el administrador no tiene centro | `PantallaInicio`; widget test |
| CU-24.1-SUP-11 | Tocar el aviso abre Mis reservas con la reserva resaltada | `@CU-24.1-H01-02` |
| CU-24.1-SUP-12 | Una reserva modificada recibe un aviso nuevo; el anterior no se retira | `tests/unit/test_recordatorios.py` |
| CU-24.1-SUP-13 | Sistema simulado con el emulador de Auth; bandeja y pantalla bloqueada no se ejecutan | `SistemaSimulado`; supuestos sin cobertura |
| CU-24.1-SUP-14 | Tipo corto del catálogo y hora del club | `mensaje_recordatorio`; `@CU-24.1-H01-01` |
| CU-24.1-SUP-15 | El panel no se reabre mientras queden sin leer que ya avisó; en la primera lectura avisa lo de los últimos cinco minutos | `CentroDeNotificaciones`; `@CU-24.1-H01-03`; `notificaciones_test.dart` |

## Supuestos sin cobertura

| ID | Motivo |
|---|---|
| CU-24.1-SUP-02, 05, 06, 07, 12, 14, 15 | Los prueban tests de `tests/unit`, `tests/integracion` y de widget con su tag `@supuesto`, que caen fuera de `$E2E`; ningún escenario de `$E2E` los ejercita |
| CU-24.1-SUP-10 | Lo prueban los tests de widget de `apps/mobile/test/notificaciones_test.dart`, fuera de `$E2E` |
| CU-24.1-SUP-13 (parte) | La entrega por el servicio real (FCM), el aviso en la bandeja o la pantalla bloqueada y el toque sobre ellos necesitan un proyecto de Firebase y un teléfono con permiso del sistema: no se pueden ejecutar acá. Queda verificado hasta el puerto y hasta el centro de la app |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/migraciones/versions/0005_notificaciones.py` | `dispositivo` y `notificacion` | `dispositivo`: token único entre activos, baja lógica, `permiso`; `notificacion`: los tres tipos, envío `pendiente/enviada/sin_permiso/fallida`, índice único (reserva, inicio) para el recordatorio |
| `apps/api/app/dominio/notificaciones.py` | `Aviso`, `Notificacion`, `Recordatorio`, `mensaje_recordatorio` | texto del CU con tipo corto y hora del club; sin imports de afuera |
| `apps/api/app/aplicacion/notificaciones.py` | puertos `Notificaciones` y `CanalPush`; casos de uso | `enviar_recordatorios` registra antes de enviar (el índice único evita el doble envío entre barridos) y marca el resultado |
| `apps/api/app/infraestructura/notificaciones.py` | `NotificacionesSql` | `vencidos` deriva de reservas activas, creadas o modificadas con una hora o más de anticipación y sin aviso para su horario; `registrar_dispositivo` toma la cuenta `FOR SHARE` |
| `apps/api/app/infraestructura/push.py` | `CanalNulo`, `CanalFcm`, `canal_push` | FCM sólo con `GOOGLE_APPLICATION_CREDENTIALS`; el token inválido vuelve en el resultado |
| `apps/api/app/interfaz/notificaciones.py` | `PUT /dispositivos`, `POST /dispositivos/baja`, `GET /notificaciones`, `POST /notificaciones/{id}/leer`, `POST /notificaciones/leer-todas` | sólo el usuario; la ajena es 404 |
| `apps/api/app/interfaz/barrido.py` | el barrido en segundo plano | una tarea de asyncio que llama al caso de uso cada `RECORDATORIOS_CADA` segundos |
| `apps/api/app/interfaz/pruebas.py` | `/_pruebas/recordatorios` y `/_pruebas/dispositivos` | el barrido con reloj propio, acotado a una cuenta |
| `apps/api/app/main.py`, `apps/api/app/config.py` | el ciclo de vida y `recordatorios_cada` | 0 lo apaga |
| `apps/api/tests/conftest.py` | apaga el barrido en los tests | `RECORDATORIOS_CADA=0` |
| `apps/api/tests/escenarios/test_recordatorio.py` | escenarios (congelado) | canal de prueba y reloj propio |
| `apps/api/tests/unit/test_recordatorios.py` | mensaje, caso de uso con fakes, supuestos 02, 06, 07, 12 | sin base |
| `apps/api/tests/integracion/test_notificaciones_api.py` | endpoints, permisos, menos de una hora (decisión 10), varios dispositivos y baja al cerrar sesión (decisión 14) | contra la base y el emulador |
| `apps/mobile/pubspec.yaml`, `apps/mobile/pubspec.lock` | `firebase_messaging` | sólo lo usa `SistemaFcm` |
| `apps/mobile/lib/configuracion.dart` | `push` y `avisosCada` | emulador de Auth → simulado y 2 s; si no, FCM y 20 s |
| `apps/mobile/lib/notificaciones/notificacion.dart` | `Notificacion`, `TipoDeNotificacion`, agrupado por día | modelo de los tres tipos |
| `apps/mobile/lib/notificaciones/notificaciones.dart` | repositorio de la API | igual que `Reservas`: api + sesión |
| `apps/mobile/lib/notificaciones/centro.dart` | estado de la app: lista, no leídas, permiso, panel, sondeo, registro del dispositivo | se engancha a la sesión y sólo actúa para el rol usuario; baja el dispositivo antes de cerrar la sesión |
| `apps/mobile/lib/notificaciones/sistema.dart` | puerto y `SistemaSimulado` | permiso guardado en el dispositivo, arranca concedido |
| `apps/mobile/lib/notificaciones/sistema_fcm.dart` | `SistemaFcm` | permiso, token, primer plano y toque |
| `apps/mobile/lib/notificaciones/tarjeta_aviso.dart` | `TarjetaAviso` | una pieza para el centro y el panel; el tipo decide ícono y acento |
| `apps/mobile/lib/notificaciones/pantalla_notificaciones.dart` | centro, estado vacío y desactivadas | las desactivadas: pantalla entera si no hay avisos, franja arriba de la lista si los hay |
| `apps/mobile/lib/notificaciones/panel_avisos.dart` | panel superior con barrera | sólo con permiso; se cierra tocando afuera |
| `apps/mobile/lib/notificaciones/campana.dart` | `BotonNotificaciones` | etiqueta «Notificaciones» o «Notificaciones, N sin leer» |
| `apps/mobile/lib/app.dart`, `apps/mobile/lib/main.dart` | ruta `/notificaciones`, `centro` opcional, panel en el `builder` | sin `centro` la app no sondea ni muestra campana |
| `apps/mobile/lib/sesion/sesion.dart` | `alCerrar` | callbacks best effort antes de salir |
| `apps/mobile/lib/comun/barra_superior.dart` | `botonDelSistema`: el `BackButton` de Material con la misma flecha | sólo lo usa el centro; el resto de las pantallas sigue igual |
| `apps/mobile/lib/comun/estado_vacio.dart` | `icono` opcional | por defecto el de antes |
| `apps/mobile/lib/inicio/pantalla_inicio.dart` | la campana junto al avatar | sólo con `centro` |
| `apps/mobile/lib/reservas/pantalla_mis_reservas.dart` | `reservaId` resalta una tarjeta | borde de acento y `Semantics(selected)` |
| `apps/mobile/test/accesibilidad_notificaciones_test.dart` | guías de Flutter por pantalla en los dos modos | sin tag de card |
| `apps/mobile/test/notificaciones_test.dart`, `apps/mobile/test/capturas/notificaciones_capturas.dart`, `apps/mobile/test/soporte/usuario.dart` | widget al 200 % en 360, capturas; `montarUsuario` recibe el centro | sin tag de card |
| `apps/mobile/integration_test/notificaciones/notificaciones_test.dart`, `soporte/red.dart`, `soporte/acciones.dart` | escenarios y soporte (ya commiteados) | permiso simulado por `SharedPreferences` |

## Perímetro

Auth: token de Firebase (emulador). Mocks: ninguno de servicio propio; el envío real, la bandeja del
sistema y la pantalla bloqueada quedan afuera (ver supuestos sin cobertura). CU-24.2 y CU-24.3 quedan
afuera: sólo comparten el modelo y el centro. Orden de bloqueos: al registrar un dispositivo se toma
la cuenta `FOR SHARE`; el barrido no bloquea reservas (sólo lee).

## Brief visual

**Invención 2 · densidad 4.** Un centro de notificaciones como el de cualquier app y un panel que
cae de arriba; el carácter viene de los tokens del club (lima, superficies elevadas), no de la forma.

- **Desde dónde.** La campana está en el Home junto al avatar; el panel aparece sobre cualquier
  pantalla con la app abierta; el aviso se abre desde el panel o desde el centro.
- **Qué se lee.** Cada aviso: ícono, «CLUBNAHUELMOSSE · cuándo», título y cuerpo. Sin leer se marca
  con un punto de acento; el color del ícono dice el tipo (lima recordatorio, verde confirmación,
  rojo alerta).
- **Teléfono chico.** En 360 con el texto al 200 % los avisos crecen en alto, nunca se recortan; el
  botón ACTIVAR NOTIFICACIONES queda fijo abajo. El grande gana aire lateral.
- **Material.** Tipografía Inter con el sobretítulo en mayúsculas del prototipo; lienzo `bgBase` y
  tarjetas `bgSurfaceRaised`; separación por espacio y un borde fino; radio grande único.
