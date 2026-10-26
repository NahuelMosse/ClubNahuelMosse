# NOT-01 · la app pide el permiso de notificaciones

status: proposed
cap: 2 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-26): «en otro hilo, te podes fijar si las notificaciones funcionan, es critico» y, ante el hallazgo de que en Android 13 o más nuevo la app nunca pide el permiso, eligió «Sí, en una card nueva»"
  - "relevamiento · revisión de punta a punta de las notificaciones (2026-10-26): `CentroDeNotificaciones._arrancar` revisa el permiso pero no lo pide; `solicitarPermiso` sólo lo llama «Activar» de la pantalla de notificaciones; en Android 13+ sin pedirlo el estado es `notDetermined`, el teléfono se registra con `permiso: false` y la API deja cada aviso `sin_permiso`"
  - "CU-24.1 · ../CU-nuevos (recordatorio de la reserva por notificación push): el aviso se envía una hora antes; FA2, sin permiso el aviso queda en el centro de notificaciones"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "te podes fijar si las notificaciones funcionan, es critico" · acceptance: cuando una persona usuaria entra a la app y el sistema todavía no le preguntó por las notificaciones, la app le pide el permiso una vez; con lo que conteste, el teléfono se registra en la API con ese permiso
- S2 · "Sí, en una card nueva" (la corrección del permiso) · acceptance: si la persona ya contestó (concedió o negó), la app no vuelve a preguntar al entrar; el botón «Activar» de la pantalla de notificaciones sigue pidiéndolo como hoy
- NOT-01-ASM-01 · se pregunta al entrar con el rol de usuario, no a un administrador (los administradores no reciben avisos de reservas); es el mismo momento en que hoy arranca el centro de notificaciones · S1
- NOT-01-ASM-02 · «todavía no le preguntó» es el estado `notDetermined` de Firebase Messaging; en el sistema simulado de los tests y escenarios es la ausencia de una respuesta guardada · S1

## Tasks

- T1 · S1,S2,NOT-01-ASM-01,NOT-01-ASM-02 · apps/mobile/lib/notificaciones/sistema.dart (data), apps/mobile/lib/notificaciones/sistema_fcm.dart (data), apps/mobile/lib/notificaciones/centro.dart (rule) · tests: apps/mobile/test/permiso_al_entrar_test.dart "al entrar, si el sistema todavía no le preguntó, la app pide el permiso y registra el teléfono con la respuesta @NOT-01-S1 @assumption:NOT-01-ASM-02"; apps/mobile/test/permiso_al_entrar_test.dart "si ya contestó, al entrar no vuelve a preguntar @NOT-01-S2"; apps/mobile/test/permiso_al_entrar_test.dart "un administrador no recibe la pregunta al entrar @assumption:NOT-01-ASM-01"; apps/mobile/test/permiso_al_entrar_test.dart "Activar sigue pidiendo el permiso @NOT-01-S2"
  reuses: apps/mobile/lib/notificaciones/sistema.dart SistemaDeNotificaciones.solicitarPermiso; apps/mobile/lib/notificaciones/centro.dart _revisarPermiso

## Changes to existing behavior

- al entrar como usuario por primera vez, el sistema operativo muestra su pregunta de notificaciones; antes sólo aparecía al tocar «Activar»

## Gate

```
suite: sh D:/Temp/w/herramientas/flutter-mobile.sh
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
```

## Log

- L1 · en otro hilo, te podes fijar si las notificaciones funcionan, es critico · (ante el hallazgo del permiso en Android 13+) Sí, en una card nueva
