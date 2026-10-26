# ARQ-03 · app limpia: librerías, sin duplicados y ordenada

card: ARQ-03
status: proposed
cap: 5 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-25): «veo varias cosas en el codigo que reinventan la rueda, si hay una libreria que lo hace, ponela, asi simplificamos el codigo, quiero que sea legible», «bueno si podemos reducir lineas de codigo agregando librerias o no repitiendo codigo, lo agradeceria», «sino podemos simplemente hacer que el codigo sea mas limpio y este mas organizado?» y «lo que se puede manejar con librerias se hace con librerias, lo que esta duplicado se comparte y lo demas se lo deja limpio y bien ordenado»"
  - "relevamiento · lectura completa de los 80 archivos de apps/mobile/lib (2026-10-25): el aviso de errores de red copiado en unas 20 pantallas, fechas y horas armadas con `padLeft`, cinco chips seleccionables copiados, el registro exitoso rearmando `PantallaResultado`, el indicador «dando de baja» copiado, el parseo de `errores` repetido, pantallas de más de 500 líneas"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "lo que se puede manejar con librerias se hace con librerias" · acceptance: las fechas, las horas y el DNI que muestra la app salen de `intl` (`DateFormat`, `NumberFormat`) desde `comun/fechas.dart`; ningún archivo de `lib/` arma una fecha o una hora con `padLeft`
- S2 · "lo que esta duplicado se comparte" · acceptance: el aviso de sesión vencida y de error de red con reintento vive en `sesion/fallo_de_carga.dart` y las pantallas lo llaman; los chips y pestañas seleccionables son un solo `ChipElegible`; el registro exitoso es una `PantallaResultado`; el indicador de una baja o anulación en curso es un solo `EnCurso`; los errores por campo que manda el servidor se leen con una sola función, `erroresDeCampo` en `comun/errores_de_campo.dart`
- S3 · "lo demas se lo deja limpio y bien ordenado" · acceptance: ninguna `pantalla_*.dart` pasa de 500 líneas (sus partes van a archivos propios en la misma carpeta) y las 350 capturas de `test/capturas/` dan idénticas sin regenerarlas
- ARQ-03-ASM-01 · lo que se ve no cambia: las capturas son el contrato visual y se corren sin `--update-goldens`; un texto, un color o un margen distinto es un error del refactor · S3
- ARQ-03-ASM-02 · las diferencias entre pantallas en el aviso de errores (no avisar si otra pantalla la tapa, correr algo antes del aviso de sesión vencida, reintentar o no) pasan a parámetros del helper; ninguna pantalla pierde la suya · S2
- ARQ-03-ASM-03 · no se usan `ChoiceChip` ni `SegmentedButton` de Material: cambian la forma, la altura táctil y la semántica que fijan los tests y las capturas · S2
- ARQ-03-ASM-04 · Mi perfil valida la fecha de nacimiento con el reloj del club (`ahoraEnElClub`), como el registro, y no con `DateTime.now()` · S3

## Tasks

- T1 · S1 · apps/mobile/lib/comun/fechas.dart (presentation), apps/mobile/lib/reservas/fechas.dart (presentation), apps/mobile/lib/comun/formato_fecha.dart (presentation), apps/mobile/lib/comun/reglas_registro.dart (presentation), apps/mobile/lib/comun/linea_del_dia.dart (presentation), apps/mobile/lib/notificaciones/notificacion.dart (presentation), apps/mobile/lib/reservas/horarios.dart (presentation), apps/mobile/lib/reservas/reservas.dart (presentation), apps/mobile/lib/reservas/reglas_busqueda.dart (presentation), apps/mobile/lib/admin/historial_reservas.dart (presentation) · tests: apps/mobile/test/limpieza_test.dart "las fechas, las horas y el DNI salen de intl y ningún archivo usa padLeft @ARQ-03-S1"
- T2 · S2,ARQ-03-ASM-02,ARQ-03-ASM-03 · apps/mobile/lib/sesion/fallo_de_carga.dart (presentation), apps/mobile/lib/comun/chip_elegible.dart (presentation), apps/mobile/lib/comun/en_curso.dart (presentation), apps/mobile/lib/comun/errores_de_campo.dart (presentation), apps/mobile/lib/usuarios/pantalla_registro_exitoso.dart (presentation), apps/mobile/lib/espacios/espacios.dart (presentation), apps/mobile/lib/sedes/sedes.dart (presentation), apps/mobile/lib/sesion/sesion.dart (presentation), apps/mobile/lib/sesion/recuperacion.dart (presentation), apps/mobile/lib/admin/ (presentation), apps/mobile/lib/reservas/ (presentation), apps/mobile/lib/sedes/ (presentation), apps/mobile/lib/usuarios/ (presentation), apps/mobile/lib/sesion/ (presentation), apps/mobile/lib/inicio/ (presentation), apps/mobile/lib/notificaciones/ (presentation) · tests: apps/mobile/test/limpieza_test.dart "sólo fallo_de_carga.dart avisa la sesión vencida y el error de red @ARQ-03-S2 @ARQ-03-ASM-02"; apps/mobile/test/limpieza_test.dart "los chips y pestañas seleccionables son un solo ChipElegible @ARQ-03-S2 @ARQ-03-ASM-03"; apps/mobile/test/limpieza_test.dart "el registro exitoso es una PantallaResultado y las bajas en curso usan EnCurso @ARQ-03-S2"; apps/mobile/test/limpieza_test.dart "los errores por campo que manda el servidor se leen sólo en errores_de_campo.dart @ARQ-03-S2"
- T3 · S3,ARQ-03-ASM-01,ARQ-03-ASM-04 · apps/mobile/lib/reservas/ (presentation), apps/mobile/lib/usuarios/ (presentation), apps/mobile/lib/sedes/ (presentation), apps/mobile/lib/inicio/ (presentation), apps/mobile/lib/admin/ (presentation) · tests: apps/mobile/test/limpieza_test.dart "ninguna pantalla pasa de 500 líneas @ARQ-03-S3"; apps/mobile/test/limpieza_test.dart "las capturas se comparan sin regenerarlas @ARQ-03-S3 @ARQ-03-ASM-01"; apps/mobile/test/limpieza_test.dart "mi perfil valida el nacimiento con el reloj del club y nadie usa DateTime.now @ARQ-03-ASM-04"

## Changes to existing behavior

- Ninguna pantalla cambia lo que muestra; las capturas lo verifican sin regenerarse
- Mi perfil valida la fecha de nacimiento con el reloj del club

## Look

- ref: las 350 capturas de apps/mobile/test/capturas/ como están en main (0ea8e52)
- behavior: load · igual que hoy; la card no cambia estados, textos ni movimiento
- tokens: lib/tema/tokens.dart, sin cambios

## Gate

```
suite: sh D:/Temp/w/herramientas/flutter-mobile.sh
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
captures: sh D:/Temp/w/herramientas/arq03-capturas.sh
```

## Log

- L1 · veo varias cosas en el codigo que reinventan la rueda, si hay una libreria que lo hace, ponela, asi simplificamos el codigo, quiero que sea legible · bueno si podemos reducir lineas de codigo agregando librerias o no repitiendo codigo, lo agradeceria · sino podemos simplemente hacer que el codigo sea mas limpio y este mas organizado? · lo que se puede manejar con librerias se hace con librerias, lo que esta duplicado se comparte y lo demas se lo deja limpio y bien ordenado
