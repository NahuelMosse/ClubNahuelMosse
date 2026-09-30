# Implementation Plan: TP-01 · Página inicial (Home)

**Branch**: `card/TP-01` | **Date**: 2026-09-29 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

El Home reemplaza la pantalla fija de accesos rápidos por una que carga datos: saludo con el
nombre de quien inició sesión, el hero «RESERVÁ TU CANCHA» con la cantidad de sedes y canchas
que trae la API, la próxima reserva activa (la de inicio más cercano) con MODIFICAR y CANCELAR
reusando la tarjeta de Mis reservas, los chips de deporte del catálogo (decorativos) y los dos
accesos rápidos que ya existían. Sin próximas reservas el bloque no aparece. Un administrador
sigue entrando directo al panel: esa redirección ya existía (`Perfil.inicio`) y esta card sólo
la ejercita con un escenario.

## Technical Context

**Language/Version**: Dart 3.9 / Flutter 3.35 (app). Sin cambios de API: reusa
`GET /reservas?cuando=proximas` (ya ordena por `inicio` ascendente y no excluye las que ya
empezaron), `GET /espacios/catalogo` y `GET /sedes`.
**Storage**: sin cambios de esquema; pantalla de sólo lectura.
**Testing**: `integration_test` con sedes, espacios y reservas cargados por la API;
widget de accesibilidad y capturas del Home con datos servidos por un cliente falso.

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Diez escenarios del snapshot (RF1 del enunciado + Figma 37:147, 43:1422, 43:1462, 55:251) |
| II · Nada se supone en silencio | `TP-01-SUP-01` a `SUP-07`; AMB-04 resuelta antes del snapshot |
| III · Tests antes del código | Diez escenarios congelados en rojo en `15823ef` |
| IV · El backend es la autoridad | La próxima reserva, su orden y si cuenta una en curso salen de `GET /reservas?cuando=proximas`, ya existente; la app no reordena ni filtra |
| V · Rastro | Pantalla de sólo lectura: no estampa nada nuevo |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| TP-01-SUP-01 | Sin próximas reservas, el bloque «Tu próxima reserva» no aparece | `_PantallaInicioState.build`; `@TP-01-H02-01` |
| TP-01-SUP-02 | Si falla la carga, overlay compartido y el resto de la pantalla no se renderiza hasta reintentar | `_PantallaInicioState._cargar` (reusa `mostrarErrorDeRed`/`mostrarSesionVencida`) |
| TP-01-SUP-03 | Una reserva activa ya empezada y no terminada sigue como «próxima» | ya lo resuelve `ReservasSql.de_usuario` (`estado_actual = 'activa'`, sin filtrar por `inicio`); la app sólo consume el orden que llega |
| TP-01-SUP-05 | «Tu próxima reserva» es la activa de inicio más cercano | `ReservasSql.de_usuario` (`ORDER BY r.inicio, r.id`); `_PantallaInicioState._cargar` toma `.firstOrNull`; `@TP-01-H01-02` |
| TP-01-SUP-06 | Los chips de DEPORTES son decorativos: no navegan | `_Deportes` en `pantalla_inicio.dart` |
| TP-01-SUP-07 | El saludo es siempre «BUENOS DÍAS,», sin lógica horaria | `_Cabecera` en `pantalla_inicio.dart`; `@TP-01-H01-01` |

## Supuestos sin cobertura

- **TP-01-SUP-02** (overlay de error compartido): ningún escenario del snapshot pide simular una
  carga que falla en el Home, así que no lleva `@supuesto`; lo ejercita un test de widget sin
  tag de card (`test/inicio_test.dart`, «si la lectura falla avisa y deja reintentar»).
- **TP-01-SUP-03** (reserva en curso sigue como próxima): el snapshot no trae un escenario de
  «reserva ya empezada»; la regla vive enteramente en la consulta SQL existente, que CU-09 ya
  ejercita para otro flujo, pero esta card no agrega un caso que la pruebe desde el Home.
- **TP-01-SUP-06** (chips decorativos): no hay escenario que pida verificar que no navegan a
  ningún lado.

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/mobile/lib/inicio/pantalla_inicio.dart` | El Home entero | `StatefulWidget` con `Reservas`, `Espacios` y `Sedes` inyectados; carga los tres en `initState`; loading/retry de pantalla completa como en `PantallaMisReservas`; `TarjetaReserva` de `pantalla_mis_reservas.dart` reusada para la próxima reserva, sin duplicar su UI; `_Hero` calcula sedes y canchas sumando `Sede.canchas`; `_Deportes` itera `Catalogo.deportes` sin acción; cancelar/modificar reusan el mismo ciclo que Mis reservas y recargan el Home al volver |
| `apps/mobile/lib/app.dart` | Ruta `/inicio` | Inyecta `_reservas`, `_espacios` y `_sedes` (ya existían para otras pantallas) al `PantallaInicio` |
| `apps/mobile/lib/reservas/pantalla_mis_reservas.dart` | `textoDeCancelacion` | El texto de confirmación de cancelar sale de una función pública que usan Mis reservas y el Home, para que digan lo mismo |
| `apps/mobile/integration_test/inicio/home_test.dart` | Los diez escenarios de la card | Un `testWidgets` por ID; `@supuesto:TP-01-SUP-05` y `@supuesto:TP-01-SUP-07` van en el mismo test que ya ejercita ese escenario |
| `apps/mobile/test/soporte/montar.dart` | `apiInicio` e `inicioFalso(sesion)` | Cliente de API falso con fixtures fijas (4 sedes / 17 canchas, el catálogo de deportes, una próxima reserva parecida a la del prototipo) para los tests de widget y las capturas |
| `apps/mobile/test/inicio_test.dart` | Widget del Home | Saludo, conteo, próxima reserva, Home sin reservas, texto al 200 % en 360 px en los dos modos, y la lectura que falla (`TP-01-SUP-02`) |
| `apps/mobile/test/accesibilidad_sesion_test.dart` | «el Home» en la matriz de accesibilidad | Usa `inicioFalso` en vez de instanciar `PantallaInicio` directo (cambió su constructor) |
| `apps/mobile/test/perfil_test.dart` | «el Home y el avatar siguen al perfil» | Monta la app con `apiInicio()` para que el Home lea datos válidos |
| `apps/mobile/test/capturas/sesion_capturas.dart` | Capturas `home_*` y `tarjeta_cuenta_*` | Mismo cambio de constructor |

## Brief visual

**Invención 2 · densidad 6.** El Home es un tablero de arranque: la persona lo mira todos los
días antes de decidir qué reservar. Estructura convencional (hero, próxima acción, atajos) con
ejecución cuidada: la jerarquía tipográfica y el acento lima hacen el trabajo, no el layout.

- **Desde dónde.** Es la pantalla de aterrizaje después de iniciar sesión como usuario; «Ver
  todas» va a Mis reservas, «Buscar cancha» a Consultar canchas, «Ver sedes» al listado, y el
  avatar abre la tarjeta de cuenta con Perfil completo y Mis reservas.
- **Teléfono chico.** En 360 el saludo, el hero y el estado de la próxima reserva entran sin
  scroll; DEPORTES y ACCESOS RÁPIDOS quedan más abajo. Nada del hero se trunca: el texto de
  conteo es una sola línea corta.
- **Hero.** La portada lleva la foto de fútbol con el velo de la app y el saludo encima, como
  el prototipo; como va sobre foto usa los colores del modo oscuro en los dos modos. Los chips
  de DEPORTES son todos iguales (ninguno lima): resaltar uno sugeriría una selección que no
  existe (`TP-01-SUP-06`). En 360 el título ocupa dos líneas.
- **Variables visuales.** El lima (`accentInk`) marca lo que se puede tocar y lo que importa hoy
  (saludo, «VER TODAS →», precio de la reserva); el verde de éxito es sólo el estado ACTIVA,
  igual que en Mis reservas — ninguna variable nueva, se reusan los tokens ya definidos.
- **Material.** El mismo de Mis reservas y de la pantalla de inicio anterior: `bgBase`/
  `bgSurfaceRaised`, borde de 1 px, radio `radioLg`, densidad de `Medidas.s16`/`s24`. No se
  introduce ningún token nuevo.
