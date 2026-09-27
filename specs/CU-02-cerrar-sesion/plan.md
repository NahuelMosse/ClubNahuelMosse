# Implementation Plan: CU-02 · Cerrar sesión

**Branch**: `card/CU-02` | **Date**: 2026-09-27 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

El avatar de la cabecera abre la tarjeta de la cuenta del prototipo (43:1422): iniciales, nombre,
correo, «MIEMBRO ACTIVO» y los accesos «Perfil completo», «Mis reservas» y «Cerrar sesión». Cerrar
sesión borra la sesión de Firebase del dispositivo y las rutas, que escuchan a la sesión, vuelven
al login; también se cierra con «CERRAR SESIÓN» desde Mi perfil. Tocar afuera cierra la tarjeta
sin hacer nada. Es sólo de la app: la API no guarda sesiones.

## Technical Context

**Language/Version**: Dart 3.9 / Flutter 3.35
**Primary Dependencies**: firebase_auth (`signOut`), go_router (`refreshListenable`)
**Storage**: ninguno nuevo
**Testing**: `integration_test` en el emulador de Android; tests de widget con `SesionFalsa`
**Constraints**: el registro de push por dispositivo todavía no existe; lo da de baja CU-24.1 al
cerrar sesión (decisión 14)

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Cuatro escenarios; tarjeta y textos del prototipo (decisión 12) |
| II · Nada se supone en silencio | `CU-02-SUP-01` a `SUP-03`; AMB-02, 04 y 06 resueltas por decisión |
| III · Tests antes del código | 4 escenarios de pantalla commiteados en rojo |
| IV · El backend es la autoridad | No aplica: cerrar sesión no toca datos del servidor |
| V · Rastro | Sin rastro (`CU-02-SUP-03`) |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-02-SUP-01 | Cerrar sesión no necesita red | `Sesion.cerrar` sólo llama a Firebase `signOut` |
| CU-02-SUP-02 | El administrador cierra sesión desde un avatar en el panel; su tarjeta sólo tiene «Cerrar sesión» | `mostrarTarjetaCuenta`; `test/tarjeta_cuenta_test.dart` |
| CU-02-SUP-03 | No se registra la hora del cierre | — |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/mobile/lib/comun/avatar.dart` | `Avatar-Iniciales` en tres tamaños | iniciales = primera letra del nombre y del apellido |
| `apps/mobile/lib/comun/insignia.dart` | `Badge-Estado` lima | — |
| `apps/mobile/lib/comun/boton.dart` | `BotonContorno` (`Btn/Type=Secondary`) | — |
| `apps/mobile/lib/sesion/tarjeta_cuenta.dart` | `BotonCuenta`, `mostrarTarjetaCuenta` y `cerrarSesion` | diálogo con fondo `bg/scrim` que se cierra al tocar afuera; Perfil y Mis reservas se apilan sobre el inicio para que el atrás del teléfono vuelva; si Firebase no puede cerrar la sesión, la persona queda adentro y ve el error del servidor |
| `apps/mobile/lib/usuarios/pantalla_mi_perfil.dart` | cabecera del perfil y «CERRAR SESIÓN» | los datos personales los suma CU-05 |
| `apps/mobile/lib/reservas/pantalla_mis_reservas.dart` | destino de «Mis reservas» | el listado lo suma CU-08 |
| `apps/mobile/lib/inicio/`, `admin/` | el avatar en la cabecera | — |
| `apps/mobile/lib/app.dart`, `main.dart` | cada ruta de adentro con su rol; las rutas escuchan a `Sesion`; cada arranque arma la app de cero | sin sesión, al login; con otro rol, a su inicio |

## Brief visual

**Invención 1 · densidad 2.** Un menú de cuenta como cualquier otro.

- **Tarjeta.** Arriba a la derecha, bajo el avatar que la abre, sobre el fondo oscurecido. Se lee
  quién tiene la sesión y hay tres filas de 52 de alto; «Cerrar sesión» en rojo y sin chevron,
  porque no lleva a otra pantalla. Entra igual a 360 y a 430: ancho máximo 300.
- **Mi perfil.** Avatar grande, nombre, correo e insignia centrados; el botón de contorno abajo.
- **Variables visuales.** Rojo = acción que saca de la cuenta; lima = identidad (avatar, insignia).
- **Material.** El de CU-01: Inter, superficie elevada `bg/surface-raised` con borde fino y la
  sombra del prototipo, radio 20.
