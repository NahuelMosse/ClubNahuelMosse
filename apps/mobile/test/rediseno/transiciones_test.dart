import 'package:clubnahuelmosse/features/bookings/data/booking_json.dart';
import 'dart:async';
import 'dart:convert';

import 'package:clubnahuelmosse/features/admin/presentation/booking_detail_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/new_space_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/edit_space_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/space_created_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_spaces_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/venue_form_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_panel_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/venue_created_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_venues_screen.dart';
import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/bottom_bar.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/space_search_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/confirm_change_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/confirm_booking_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/availability_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/my_bookings_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/booking_confirmed_screen.dart';
import 'package:clubnahuelmosse/features/bookings/domain/booking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../mis_reservas_test.dart' show reservaJson;
import '../notificaciones_test.dart' show ApiFalsa, centroDe;
import '../soporte/admin.dart';
import '../soporte/montar.dart';
import '../soporte/usuario.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notifications_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/account_card.dart';
import 'package:clubnahuelmosse/features/session/presentation/forgot_password_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/spaces/domain/space.dart';
import 'package:clubnahuelmosse/features/users/presentation/change_password_screen.dart';
import 'package:clubnahuelmosse/features/users/presentation/my_profile_screen.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_done_screen.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_screen.dart';
import 'package:clubnahuelmosse/features/venues/domain/venue.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venue_screen.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues_screen.dart';

const _ancho = 393.0;
const _alto = 852.0;

Duration _ms(int n) => Duration(milliseconds: n);

typedef _Paso = Future<void> Function(WidgetTester tester);

GoRouter _rutas(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

Future<void> _ir(WidgetTester tester, String ruta, {Object? extra}) async =>
    _rutas(tester).go(ruta, extra: extra);

Future<void> _empujar(WidgetTester tester, String ruta) async =>
    unawaited(_rutas(tester).push<void>(ruta));

/// Toca [f] sin esperar a que termine la transición que dispara.
Future<void> _tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
}

Future<void> _tocarYEsperar(WidgetTester tester, Finder f) async {
  await _tocar(tester, f);
  await tester.pumpAndSettle();
}

/// Deja que la navegación se arme, sin que corra el reloj de la transición.
Future<void> _arrancar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// Descarta la app anterior: una `App` nueva sobre la vieja conservaría su enrutador.
Future<void> _reiniciar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void _reducirMovimiento(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

double _izquierda(WidgetTester tester, Type pantalla) =>
    tester.getTopLeft(find.byType(pantalla)).dx;

double _arriba(WidgetTester tester, Finder pantalla) =>
    tester.getTopLeft(pantalla).dy;

/// La pantalla ya está en su lugar y ninguna transición de página la desliza.
void _sinTransicion(WidgetTester tester, Type pantalla, {String? motivo}) {
  expect(find.byType(pantalla), findsOneWidget, reason: motivo);
  expect(_izquierda(tester, pantalla), 0, reason: motivo);
  expect(
    find.ancestor(
      of: find.byType(pantalla),
      matching: find.byType(SlideTransition),
    ),
    findsNothing,
    reason: motivo,
  );
  // Ni una transición de la ruta en curso, sea cual sea.
  expect(
    ModalRoute.of(tester.element(find.byType(pantalla)))?.animation?.status,
    AnimationStatus.completed,
    reason: motivo,
  );
  // Tampoco un fundido ni un zoom a medias.
  expect(_opacidadesDe(tester, pantalla), everyElement(1), reason: motivo);
  expect(
    [
      for (final z in tester.widgetList<ScaleTransition>(
        find.ancestor(
          of: find.byType(pantalla),
          matching: find.byType(ScaleTransition),
        ),
      ))
        z.scale.value,
    ],
    everyElement(1),
    reason: motivo,
  );
}

/// La pantalla está en su lugar desde el primer cuadro y sigue así: no hay transición en curso.
Future<void> _quieta(
  WidgetTester tester,
  Type pantalla, {
  String? motivo,
}) async {
  _sinTransicion(tester, pantalla, motivo: motivo);
  await tester.pump(_ms(100));
  _sinTransicion(tester, pantalla, motivo: motivo);
}

/// La pantalla entra desde la derecha: a los 160 ms va a mitad de camino y a los 320 ya llegó.
Future<void> _entraDesdeLaDerecha(
  WidgetTester tester,
  Type pantalla, {
  String? motivo,
}) async {
  await _arrancar(tester);
  expect(find.byType(pantalla), findsOneWidget, reason: motivo);
  await tester.pump(_ms(160));
  final aMitad = _izquierda(tester, pantalla);
  expect(aMitad, greaterThan(0), reason: motivo);
  expect(aMitad, lessThan(_ancho), reason: motivo);
  await tester.pump(_ms(160));
  expect(_izquierda(tester, pantalla), 0, reason: motivo);
}

/// La pantalla sale hacia la derecha: a los 140 ms va a mitad de camino y a los 280 ya no está.
Future<void> _saleHaciaLaDerecha(
  WidgetTester tester,
  Type pantalla, {
  String? motivo,
}) async {
  await _arrancar(tester);
  expect(find.byType(pantalla), findsOneWidget, reason: motivo);
  await tester.pump(_ms(140));
  final aMitad = _izquierda(tester, pantalla);
  expect(aMitad, greaterThan(0), reason: motivo);
  expect(aMitad, lessThan(_ancho), reason: motivo);
  await tester.pump(_ms(140));
  await tester.pump();
  expect(find.byType(pantalla), findsNothing, reason: motivo);
}

List<double> _opacidadesDe(WidgetTester tester, Type pantalla) => [
  for (final f in tester.widgetList<FadeTransition>(
    find.ancestor(
      of: find.byType(pantalla),
      matching: find.byType(FadeTransition),
    ),
  ))
    f.opacity.value,
];

// ---- las apps ----

ApiClient _apiUsuario() => apiRutas({
  ...rutasDeSedes(grilla: grillaJson(ocupadas: {9, 12})),
  'GET /reservas': (200, '{"reservas": [${reservaJson()}]}'),
});

const _reservaAdmin =
    '{"id": "00000000-0000-7000-8000-000000000001", "espacio_id": "00000000-0000-7000-8000-000000000009", "sede_id": "00000000-0000-7000-8000-000000000001", "espacio":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", "tipo": "F5", "sede":'
    ' "Sede Morón", "direccion": "Av. Rivadavia 19850", "inicio":'
    ' "2026-11-12T21:00:00-03:00", "fin": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "estado": "activa", "motivo": null, "usuario_id": "00000000-0000-7000-8000-000000000001", "usuario": "Nahuel Mosse",'
    ' "creado_en": "2026-11-02T18:42:00-03:00", "cancelada_en": null,'
    ' "cancelada_por_nombre": null, "espacio_de_baja": false}';

ApiClient _apiAdmin() => apiRutas({
  ...rutasDeEspacios(),
  'GET /reservas/todas': (
    200,
    '{"reservas": [$_reservaAdmin], "total": 1, "pagina": 1, "por_pagina": 20,'
        ' "contadores": {"todas": 1, "activas": 1, "completadas": 0,'
        ' "anuladas": 0}}',
  ),
});

/// Alto para que el inicio construya todos sus bloques, también los de abajo.
const _telefonoAlto = Size(393, 1600);

Future<void> _usuarioEn(WidgetTester tester, String inicio) => montarUsuario(
  tester,
  api: _apiUsuario(),
  inicio: inicio,
  tamano: _telefonoAlto,
);

Future<void> _adminEn(WidgetTester tester, String inicio) =>
    montarAdmin(tester, api: _apiAdmin(), inicio: inicio);

Future<void> _usuarioConCentro(WidgetTester tester, String inicio) {
  final api = ApiFalsa();
  return montarUsuario(
    tester,
    api: api.cliente,
    inicio: inicio,
    tamano: _telefonoAlto,
    centro: (sesion) => centroDe(api, sesion),
  );
}

// ---- las pantallas hijas (S2 y S3) ----

class _Hija {
  const _Hija(
    this.nombre,
    this.montar,
    this.abrir,
    this.pantalla, {
    this.conBarra = false,
  });

  final String nombre;

  /// Deja la app en la pantalla desde donde se llega.
  final _Paso montar;

  /// Hace lo que hace la persona para llegar, sin esperar a que termine la transición.
  final _Paso abrir;
  final Type pantalla;

  /// La pantalla tiene la flecha «Volver» de la barra superior.
  final bool conBarra;
}

final _hijas = <_Hija>[
  _Hija(
    'sede',
    (t) => _usuarioEn(t, '/sedes'),
    (t) => _ir(t, '/sedes/00000000-0000-7000-8000-000000000001'),
    VenueScreen,
  ),
  _Hija(
    'horarios',
    (t) => _usuarioEn(t, '/sedes/00000000-0000-7000-8000-000000000001'),
    (t) => _ir(
      t,
      '/sedes/00000000-0000-7000-8000-000000000001/canchas/00000000-0000-7000-8000-000000000009',
    ),
    AvailabilityScreen,
  ),
  _Hija(
    'confirmar reserva',
    (t) async {
      await _usuarioEn(
        t,
        '/sedes/00000000-0000-7000-8000-000000000001/canchas/00000000-0000-7000-8000-000000000009',
      );
      await _tocarYEsperar(t, find.text('18:00 – 19:00'));
    },
    (t) => _tocar(t, find.text('CONTINUAR')),
    ConfirmBookingScreen,
  ),
  _Hija(
    'modificar',
    (t) => _usuarioEn(t, '/reservas'),
    (t) => _tocar(t, find.text('MODIFICAR').first),
    AvailabilityScreen,
  ),
  _Hija(
    'confirmar cambio',
    (t) async {
      await _usuarioEn(t, '/reservas');
      await _tocarYEsperar(t, find.text('MODIFICAR').first);
      await _tocarYEsperar(t, find.text('19:00 – 20:00'));
    },
    (t) => _tocar(t, find.text('CONTINUAR CON EL CAMBIO')),
    ConfirmChangeScreen,
  ),
  _Hija(
    'contraseña',
    (t) => _usuarioEn(t, '/perfil'),
    (t) => _tocar(t, find.text('Cambiar contraseña')),
    ChangePasswordScreen,
    conBarra: true,
  ),
  _Hija(
    'registro',
    (t) => _usuarioEn(t, '/'),
    (t) => _tocar(t, find.text('COMENZAR')),
    RegistrationScreen,
    conBarra: true,
  ),
  _Hija(
    'recuperar contraseña',
    (t) => _usuarioEn(t, '/'),
    (t) => _tocar(t, find.text('¿Olvidaste tu contraseña?')),
    ForgotPasswordScreen,
    conBarra: true,
  ),
  _Hija(
    'notificaciones',
    (t) => _usuarioConCentro(t, '/inicio'),
    (t) => _tocar(t, find.byIcon(Icons.notifications_none_rounded)),
    NotificationsScreen,
    conBarra: true,
  ),
  _Hija(
    'buscar cancha',
    (t) => _usuarioEn(t, '/inicio'),
    (t) => _tocar(t, find.text('Buscar cancha')),
    SpaceSearchScreen,
    conBarra: true,
  ),
  _Hija(
    'detalle de reserva del admin',
    (t) => _adminEn(t, '/admin'),
    (t) => _tocar(t, find.text('Nahuel Mosse')),
    BookingDetailScreen,
  ),
  _Hija(
    'alta de sede',
    (t) => _adminEn(t, '/admin/sedes'),
    (t) => _tocar(t, find.text('AGREGAR SEDE')),
    VenueFormScreen,
  ),
  _Hija(
    'edición de sede',
    (t) => _adminEn(t, '/admin/sedes'),
    (t) => _tocar(t, find.text('Editar sede').first),
    VenueFormScreen,
  ),
  _Hija(
    'alta de espacio',
    (t) => _adminEn(t, '/admin/espacios'),
    (t) => _tocar(t, find.text('ALTA ESPACIO')),
    NewSpaceScreen,
  ),
  _Hija(
    'edición de espacio',
    (t) => _adminEn(t, '/admin/espacios'),
    (t) => _tocar(t, find.text('Editar').first),
    EditSpaceScreen,
  ),
];

// ---- las raíces (S1) ----

class _Raiz {
  const _Raiz(this.nombre, this.montar, this.ruta, this.pantalla);

  final String nombre;
  final _Paso montar;
  final String ruta;
  final Type pantalla;
}

final _raices = <_Raiz>[
  _Raiz(
    'inicio',
    (t) => _usuarioEn(t, '/sedes/00000000-0000-7000-8000-000000000001'),
    '/inicio',
    HomeScreen,
  ),
  _Raiz('sedes', (t) => _usuarioEn(t, '/inicio'), '/sedes', VenuesScreen),
  _Raiz(
    'reservas',
    (t) => _usuarioEn(t, '/inicio'),
    '/reservas',
    MyBookingsScreen,
  ),
  _Raiz('perfil', (t) => _usuarioEn(t, '/inicio'), '/perfil', MyProfileScreen),
  _Raiz(
    'panel del admin',
    (t) => _adminEn(t, '/admin/sedes'),
    '/admin',
    AdminPanelScreen,
  ),
  _Raiz(
    'sedes del admin',
    (t) => _adminEn(t, '/admin'),
    '/admin/sedes',
    AdminVenuesScreen,
  ),
  _Raiz(
    'espacios del admin',
    (t) => _adminEn(t, '/admin'),
    '/admin/espacios',
    AdminSpacesScreen,
  ),
  _Raiz(
    'login',
    (t) => _usuarioEn(t, '/sedes/00000000-0000-7000-8000-000000000001'),
    '/',
    LoginScreen,
  ),
];

// ---- los resultados (S4) ----

class _Resultado {
  const _Resultado(this.nombre, this.montar, this.abrir, this.pantalla);

  final String nombre;
  final _Paso montar;
  final _Paso abrir;
  final Type pantalla;
}

Booking _reservaConfirmada() {
  final reserva = bookingFromJson(jsonDecode(reservaJson()));
  if (reserva == null) fail('la reserva de prueba no se lee');
  return reserva;
}

final _resultados = <_Resultado>[
  _Resultado(
    'registro exitoso',
    (t) => _usuarioEn(t, '/registro'),
    (t) => _ir(t, '/registro/exitoso'),
    RegistrationDoneScreen,
  ),
  _Resultado(
    'reserva confirmada',
    (t) => _usuarioEn(t, '/reservas'),
    (t) => _ir(t, '/reservas/confirmada', extra: _reservaConfirmada()),
    BookingConfirmedScreen,
  ),
  _Resultado(
    'sede creada',
    (t) => _adminEn(t, '/admin/sedes'),
    (t) => _ir(
      t,
      '/admin/sedes/creada',
      extra: Venue.fromJson(jsonDecode(sedeMoronJson)),
    ),
    VenueCreatedScreen,
  ),
  _Resultado(
    'espacio creado',
    (t) => _adminEn(t, '/admin/espacios'),
    (t) => _ir(
      t,
      '/admin/espacios/creado',
      extra: Space.fromJson(jsonDecode(espacioF5Json)),
    ),
    SpaceCreatedScreen,
  ),
];

Finder get _panelDeFiltros =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == '_FiltersPanel');

void main() {
  setUpAll(cargarFuentes);

  testWidgets('cada raíz de pestaña aparece en el primer cuadro @RED-04-S1', (
    tester,
  ) async {
    for (final raiz in _raices) {
      for (final empujando in [false, true]) {
        final como = empujando ? 'push' : 'go';
        await raiz.montar(tester);
        if (empujando) {
          await _empujar(tester, raiz.ruta);
        } else {
          await _ir(tester, raiz.ruta);
        }
        await _arrancar(tester);
        await _quieta(tester, raiz.pantalla, motivo: '${raiz.nombre} ($como)');
        await _reiniciar(tester);
      }
    }
  });

  testWidgets(
    'cada pantalla hija entra desde la derecha en 320 ms @RED-04-S2',
    (tester) async {
      for (final hija in _hijas) {
        await hija.montar(tester);
        await hija.abrir(tester);
        await _entraDesdeLaDerecha(tester, hija.pantalla, motivo: hija.nombre);
        await _reiniciar(tester);
      }
    },
  );

  testWidgets(
    'volver con el atrás de la barra o del sistema sale hacia la derecha en 280 ms @RED-04-S3',
    (tester) async {
      for (final hija in _hijas) {
        await hija.montar(tester);
        await hija.abrir(tester);
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await _saleHaciaLaDerecha(
          tester,
          hija.pantalla,
          motivo: '${hija.nombre} (atrás del sistema)',
        );
        await _reiniciar(tester);

        if (!hija.conBarra) continue;
        await hija.montar(tester);
        await hija.abrir(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Volver'));
        await _saleHaciaLaDerecha(
          tester,
          hija.pantalla,
          motivo: '${hija.nombre} (atrás de la barra)',
        );
        await _reiniciar(tester);
      }
    },
  );

  testWidgets(
    'cada pantalla de resultado aparece con un fundido de 250 ms @RED-04-S4',
    (tester) async {
      for (final resultado in _resultados) {
        await resultado.montar(tester);
        await resultado.abrir(tester);
        await _arrancar(tester);
        expect(
          find.byType(resultado.pantalla),
          findsOneWidget,
          reason: resultado.nombre,
        );
        expect(
          find.ancestor(
            of: find.byType(resultado.pantalla),
            matching: find.byType(SlideTransition),
          ),
          findsNothing,
          reason: resultado.nombre,
        );
        await tester.pump(_ms(125));
        final aMitad = _opacidadesDe(tester, resultado.pantalla);
        expect(
          aMitad.any((o) => o > 0 && o < 1),
          isTrue,
          reason: '${resultado.nombre} a los 125 ms: $aMitad',
        );
        await tester.pump(_ms(125));
        expect(
          _opacidadesDe(tester, resultado.pantalla),
          everyElement(1),
          reason: '${resultado.nombre} a los 250 ms',
        );
        await _reiniciar(tester);
      }
    },
  );

  testWidgets(
    'con reducir movimiento las transiciones terminan en el primer cuadro @RED-04-S14',
    (tester) async {
      _reducirMovimiento(tester);

      // Avanzar: la hija ya está en su lugar.
      await _usuarioEn(tester, '/sedes');
      await _ir(tester, '/sedes/00000000-0000-7000-8000-000000000001');
      await _arrancar(tester);
      _sinTransicionDeEmpuje(tester, VenueScreen);

      // Volver: la hija ya no está.
      await tester.binding.handlePopRoute();
      await _arrancar(tester);
      await tester.pump();
      expect(find.byType(VenueScreen), findsNothing);
      await _reiniciar(tester);

      // Resultado: el fundido ya terminó.
      await _usuarioEn(tester, '/reservas');
      await _ir(tester, '/reservas/confirmada', extra: _reservaConfirmada());
      await _arrancar(tester);
      expect(find.byType(BookingConfirmedScreen), findsOneWidget);
      expect(_opacidadesDe(tester, BookingConfirmedScreen), everyElement(1));
      await _reiniciar(tester);

      // Raíz de pestaña.
      await _usuarioEn(tester, '/sedes/00000000-0000-7000-8000-000000000001');
      await _ir(tester, '/inicio');
      await _arrancar(tester);
      await _quieta(tester, HomeScreen);
      await _reiniciar(tester);

      // El panel de filtros del admin.
      await _adminEn(tester, '/admin');
      await tester.tap(find.text('Filtros'));
      await _hastaQue(tester, () => _panelDeFiltros.evaluate().isNotEmpty);
      expect(_arriba(tester, _panelDeFiltros), 0);
    },
  );

  testWidgets(
    'tocar la pestaña activa dentro de una sede o «VER TODAS» y «Ver sedes» del inicio llegan sin animación @RED-04-ASM-05',
    (tester) async {
      // La pestaña activa, desde adentro de una sede, lleva al listado.
      await _usuarioEn(tester, '/sedes/00000000-0000-7000-8000-000000000001');
      await _tocar(
        tester,
        find.descendant(
          of: find.byType(BottomBar),
          matching: find.text('SEDES'),
        ),
      );
      await _arrancar(tester);
      await _quieta(tester, VenuesScreen, motivo: 'la pestaña activa');
      // La sede que se deja sale con su push inverso.
      await tester.pump(_ms(280));
      expect(find.byType(VenueScreen), findsNothing);
      await _reiniciar(tester);

      await _usuarioEn(tester, '/inicio');
      await _tocar(tester, find.text('VER TODAS →'));
      await _arrancar(tester);
      await _quieta(tester, MyBookingsScreen, motivo: 'VER TODAS');
      expect(find.byType(HomeScreen), findsNothing);
      await _reiniciar(tester);

      await _usuarioEn(tester, '/inicio');
      await _tocar(tester, find.text('Ver sedes'));
      await _arrancar(tester);
      await _quieta(tester, VenuesScreen, motivo: 'Ver sedes');
      expect(find.byType(HomeScreen), findsNothing);
    },
  );

  testWidgets('cerrar sesión muestra el login sin animación @RED-04-ASM-06', (
    tester,
  ) async {
    await _usuarioEn(tester, '/inicio');
    await _tocarYEsperar(tester, find.byType(AccountButton));
    await _tocar(tester, find.text('Cerrar sesión'));
    for (var i = 0; i < 5 && find.byType(LoginScreen).evaluate().isEmpty; i++) {
      await tester.pump();
    }
    await _quieta(tester, LoginScreen, motivo: 'cerrar sesión');
    await _reiniciar(tester);

    // Volver de recuperar la contraseña al login.
    await _usuarioEn(tester, '/recuperar-contrasena');
    await _ir(tester, '/');
    await _arrancar(tester);
    await _quieta(tester, LoginScreen, motivo: 'recuperar → login');
  });

  testWidgets(
    'el panel de filtros del admin sube desde abajo en 450 ms @RED-04-ASM-09',
    (tester) async {
      await _adminEn(tester, '/admin');
      await tester.tap(find.text('Filtros'));
      await _hastaQue(tester, () => _panelDeFiltros.evaluate().isNotEmpty);

      // Entra desde abajo del todo.
      expect(_arriba(tester, _panelDeFiltros), closeTo(_alto, 1));
      await tester.pump(_ms(225));
      final aMitad = _arriba(tester, _panelDeFiltros);
      expect(aMitad, greaterThan(0));
      expect(aMitad, lessThan(_alto));
      await tester.pump(_ms(225));
      expect(_arriba(tester, _panelDeFiltros), 0);
      await tester.pumpAndSettle();

      // Y sale hacia abajo.
      await tester.tap(find.byTooltip('Cerrar'));
      await _arrancar(tester);
      await tester.pump(_ms(100));
      final saliendo = _arriba(tester, _panelDeFiltros);
      expect(saliendo, greaterThan(0));
      expect(saliendo, lessThan(_alto));
      await tester.pump(_ms(450));
      await tester.pump();
      expect(_panelDeFiltros, findsNothing);
    },
  );
}

/// Con reducir movimiento la hija ya está en su lugar, sin deslizarse.
void _sinTransicionDeEmpuje(WidgetTester tester, Type pantalla) {
  expect(find.byType(pantalla), findsOneWidget);
  expect(_izquierda(tester, pantalla), 0);
}

/// Pasa cuadros sin avanzar el reloj hasta que se cumple [condicion].
Future<void> _hastaQue(WidgetTester tester, bool Function() condicion) async {
  for (var i = 0; i < 20 && !condicion(); i++) {
    await tester.pump();
  }
  expect(condicion(), isTrue);
}
