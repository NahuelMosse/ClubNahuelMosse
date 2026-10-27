# SAL-01 · el saludo del inicio depende de la hora del club

status: proposed
cap: 45 min
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «y tambien podes arreglar el bug de los buenos dias» · «el error era que siempre decia buenos dias, sin importar la hora»"
  - "repo · apps/mobile/lib/inicio/saludo_de_inicio.dart (texto fijo «BUENOS DÍAS,»); specs/TP-01-home/ambiguedades.md TP-01-AMB-07 → TP-01-SUP-07 (saludo fijo, sin lógica horaria); apps/mobile/lib/comun/zona_club.dart (`ahoraEnElClub`)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "siempre decia buenos dias, sin importar la hora" · acceptance: el saludo del inicio dice «BUENOS DÍAS,», «BUENAS TARDES,» o «BUENAS NOCHES,» según la hora del club (UTC−3) en el momento en que se arma el inicio, sea cual sea la zona del teléfono
- SAL-01-ASM-01 · los tramos son: días de 06:00 a 11:59, tardes de 12:00 a 19:59, noches de 20:00 a 05:59 · S1
- SAL-01-ASM-02 · el saludo se calcula al armar el inicio; si el inicio queda abierto al cruzar un tramo, cambia la próxima vez que se arma · S1

## Tasks

- T1 · S1,SAL-01-ASM-01,SAL-01-ASM-02 · apps/mobile/lib/inicio/saludo_de_inicio.dart (presentation) · tests: apps/mobile/test/saludo_por_hora_test.dart "el saludo sigue la hora del club: días de 06:00 a 11:59, tardes de 12:00 a 19:59, noches de 20:00 a 05:59 @SAL-01-S1 @assumption:SAL-01-ASM-01"; apps/mobile/test/saludo_por_hora_test.dart "el saludo se calcula al armar el inicio @assumption:SAL-01-ASM-02"
  reuses: `ahoraEnElClub` de comun/zona_club
  también: apps/mobile/integration_test/inicio/home_test.dart · el test de L4, que espera el saludo de la hora del club

## Changes to existing behavior

- el saludo deja de ser fijo: reemplaza TP-01-SUP-07 («el saludo es siempre BUENOS DÍAS»)

## Gate

```
suite [timeout 1 h]: sh D:/Temp/w/herramientas/flutter-mobile.sh
fmt: D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib/inicio apps/mobile/test/saludo_por_hora_test.dart apps/mobile/test/inicio_test.dart apps/mobile/test/rediseno/movimiento_pantallas_test.dart apps/mobile/integration_test/inicio/home_test.dart
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
refactor-tests: los tests que buscaban «BUENOS DÍAS,» en el inicio (inicio_test, movimiento_pantallas_test, integration_test/inicio/home_test) esperan `SaludoDeInicio.paraLaHora(ahoraEnElClub())`, el saludo de la hora en que corren; lo demás que verifican no cambia
no-docs: un texto de pantalla
no-visual: cambia el texto del saludo, no su estilo ni su lugar
```

## Log

- L1 · y tambien podes arreglar el bug de los buenos dias · el error era que siempre decia buenos dias, sin importar la hora
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
- L4 · 2026-10-27 · replaces: apps/mobile/integration_test/inicio/home_test.dart "al iniciar sesión ve el Home con el saludo y su nombre @TP-01-H01-01 @supuesto:TP-01-SUP-07" · TP-01-SUP-07 fijaba el saludo; el pedido lo hace depender de la hora · by: apps/mobile/test/saludo_por_hora_test.dart "el saludo sigue la hora del club: días, tardes y noches @SAL-01-S1 @assumption:SAL-01-ASM-01"
- L5 · 2026-10-27 · replaces: apps/mobile/test/rediseno/movimiento_pantallas_test.dart "el inicio entra escalonado: saludo, marcador, próxima reserva y tiles @RED-04-S6" · busca «BUENOS DÍAS,» con el reloj real; se fija el reloj a la mañana del club · by: el mismo test con `withClock`
- L6 · 2026-10-27 · el test que reemplaza a L4 se titula "el saludo sigue la hora del club: días de 06:00 a 11:59, tardes de 12:00 a 19:59, noches de 20:00 a 05:59 @SAL-01-S1 @assumption:SAL-01-ASM-01" (el título nombra los tramos de SAL-01-ASM-01); el test de L4 queda esperando el saludo de la hora del club en que corre
- L7 · 2026-10-27 · T1 · `SaludoDeInicio.paraLaHora` elige el saludo; el test de L5 y inicio_test esperan `paraLaHora(ahoraEnElClub())` en vez de fijar el reloj (la línea `refactor-tests:` del Gate), y el de L4 deja la etiqueta `@supuesto:TP-01-SUP-07`, que esta card reemplaza
- L8 · 2026-10-27 · declared · K4 · apps/mobile/integration_test/inicio/home_test.dart · `dart format` reacomodó el archivo al acortar el título del test de L4; los bloques repetidos (iniciar sesión y abrir el Home) son de TP-01 y cada test de integración arma su propio usuario
