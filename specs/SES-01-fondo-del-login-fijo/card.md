# SES-01 · el fondo del inicio de sesión no se mueve al abrir el teclado

status: proposed
cap: 45 min
sources:
  - "pedido (texto) · mensaje del usuario en la sesión (2026-10-27): «hay un bug que la imagen de fondo del login al abrir el teclado se mueve el fondo, no tiene sentido»"
  - "repo · apps/mobile/lib/sesion/formulario_de_inicio_sesion.dart (`Scaffold` con `resizeToAvoidBottomInset` por defecto; `Stack` con `FondoDeInicioSesion` y el formulario), apps/mobile/lib/sesion/fondo_de_inicio_sesion.dart (`BoxFit.cover`)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "la imagen de fondo del login al abrir el teclado se mueve el fondo" · acceptance: con el teclado abierto, la foto de fondo del inicio de sesión ocupa la misma área que con el teclado cerrado (no se achica ni se re-encuadra)
- S2 · "no tiene sentido" · acceptance: con el teclado abierto, el formulario se puede desplazar hasta el botón de ingresar, que queda por encima del teclado
- SES-01-ASM-01 · el arreglo es sólo para la pantalla de inicio de sesión, la única con foto de fondo · S1

## Tasks

- T1 · S1,S2,SES-01-ASM-01 · apps/mobile/lib/sesion/formulario_de_inicio_sesion.dart (presentation) · tests: apps/mobile/test/fondo_del_login_test.dart "con el teclado abierto la foto del inicio de sesión ocupa la misma área @SES-01-S1 @assumption:SES-01-ASM-01"; apps/mobile/test/fondo_del_login_test.dart "con el teclado abierto el botón de ingresar se alcanza desplazando @SES-01-S2"
  reuses: apps/mobile/lib/sesion/fondo_de_inicio_sesion.dart `FondoDeInicioSesion`

## Changes to existing behavior

- con el teclado abierto la foto del inicio de sesión queda quieta; el formulario se desplaza sobre ella

## Gate

```
suite: sh D:/Temp/w/herramientas/flutter-mobile.sh test/fondo_del_login_test.dart test/pantalla_inicio_sesion_test.dart
fmt: D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test/fondo_del_login_test.dart
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
no-docs: un arreglo de diseño de una pantalla; el contrato y el modelo de datos no cambian
no-visual: con el teclado cerrado la pantalla se ve igual; lo cubre el test de área de la foto
```

## Log

- L1 · hay un bug que la imagen de fondo del login al abrir el teclado se mueve el fondo, no tiene sentido
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base: sólo la app
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
