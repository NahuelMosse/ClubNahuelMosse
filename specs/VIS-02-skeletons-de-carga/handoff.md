# Handoff VIS-02 T1

Hecho: RED commiteado (`apps/mobile/test/esqueletos_de_carga_test.dart`, falla porque `comun/esqueleto.dart` no existe).

## Falta (todo el código)

API que el test espera en `apps/mobile/lib/comun/esqueleto.dart`:
- `Esqueleto({width, double alto, radio})` bloque redondeado (campo público `alto`); color: oscuro `bgSurfaceRaised`, claro `bgSurface` (por Theme.brightness; en claro raised == bgBase).
- `ZonaDeEsqueletos({child})`: un AnimationController por zona, `repeat()` solo si `!MediaQuery.disableAnimationsOf(context)` (si se activa, detenerlo); brillo con ShaderMask srcATop + LinearGradient deslizante; `Semantics(label:'Cargando', container:true)` + `ExcludeSemantics` sobre los bloques.
- `enum FormaDeEsqueleto { sede, cancha, reserva, aviso, grilla }` y `EsqueletoDeLista({key, forma, cantidad = 3})` (incluye la zona). Medidas estimadas: sede alto 220 radioLg; cancha 96; reserva 112; aviso 76 con cuadro 40x40 radioMd; grilla pares de 52 radioMd, separación 8 (como `GrillaDeAPares`, Medidas.altoControl).
- Borrar `EsperaDeLista` de `comun/carga_de_lista.dart` y cambiar llamadores: `sedes/contenido_de_sede.dart:156` (cancha, conservar `key: ValueKey('carga')`), `inicio/pantalla_inicio.dart:233` (reserva, con Padding horizontal s24), `reservas/pantalla_mis_reservas.dart:218` (reserva), `sedes/pantalla_sedes.dart:144` (sede), `admin/listado_admin.dart:111` (sede/espacio, según listado).
- Spinners de pantalla a reemplazar: `notificaciones/pantalla_notificaciones.dart:137` (aviso, con padding), `sedes/pantalla_sede.dart:219` (cancha), `reservas/pantalla_horarios.dart:361` y `:476` (grilla), `reservas/pantalla_buscar_cancha.dart:368` y `:408` (cancha/grilla), `admin/cuerpo_del_panel_admin.dart:52` (reserva, sliver).
- Dejar: botones, `admin/nombre_generado.dart`, `comun/pantalla_de_carga.dart`, `sesion/pantalla_nueva_contrasena.dart`, `usuarios/pantalla_mi_perfil.dart`, `comun/acciones_de_resultado.dart`, `comun/en_curso.dart`, `admin/pantalla_alta_espacio.dart`.

Tests existentes a actualizar (asertan el spinner): `test/rediseno/movimiento_pantallas_test.dart` líneas ~360, 462, 470 (cambiar por `find.byType(Esqueleto)`); `test/admin/pantalla_panel_admin_test.dart` líneas ~170 y 179 (cargandoMas; el nuevo bloque es `Esqueleto`). Anotar en `## Log` la línea `refactor-tests` (Edit solo en card.md).

Layers: marcar en `## Tasks` lo ya marcado (presentation). Completar `reuses:/new:` ya está (`new:`).
Luego: `dart format`, `flutter analyze --no-pub apps/mobile`, gate `sh D:/Temp/w/herramientas/flutter-mobile.sh`, Log por tarea, `close.mjs`. No push.
Flutter: D:/projects/flutter/bin. Tests con `montar`/`montarUsuario` hacen pumpAndSettle: con shimmer repetido cuelga en estado de carga; los tests nuevos usan `App` directo con `pump`.
