import 'package:clubnahuelmosse/features/users/data/registration_service.dart';
import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/features/admin/data/booking_history_api.dart';
import 'package:clubnahuelmosse/features/admin/domain/pending_panel_filters.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_panel_screen.dart';
import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'anular_reserva_test.dart' as anular show listado, reservaJson;
import 'mis_reservas_test.dart' show reservaJson;
import 'soporte/admin.dart';
import 'soporte/montar.dart';
import 'soporte/usuario.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_screen.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

/// Contesta [respuestas] en orden a cada POST a [ruta] (la última se repite); un `null` es
/// un corte de red. Lo que no es ese POST lo contesta [resto].
MockClient _conCorte(
  String ruta,
  List<(int, String)?> respuestas,
  (int, String) Function(http.Request) resto, {
  void Function()? alLlegar,
}) {
  var n = 0;
  return MockClient((pedido) async {
    final (int, String) respuesta;
    if (pedido.url.path == ruta && pedido.method == 'POST') {
      final siguiente =
          respuestas[n < respuestas.length ? n : respuestas.length - 1];
      n++;
      // El servidor recibió el pedido aunque la respuesta no haya vuelto.
      alLlegar?.call();
      if (siguiente == null) throw const SocketException('sin red');
      respuesta = siguiente;
    } else {
      respuesta = resto(pedido);
    }
    return http.Response.bytes(
      utf8.encode(respuesta.$2),
      respuesta.$1,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

void main() {
  setUpAll(cargarFuentes);

  group('registro', () {
    const yaRegistrado =
        '{"errores": {"correo": "Ese correo ya está registrado"}, '
        '"mensaje": "Ese correo ya está registrado"}';

    Future<void> abrirRegistro(
      WidgetTester tester,
      List<(int, String)?> respuestas,
    ) async {
      final rutas = GoRouter(
        initialLocation: '/registro',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) =>
                const Scaffold(body: Text('Iniciar sesión')),
          ),
          GoRoute(
            path: '/registro',
            builder: (context, _) => RegistrationScreen(
              registration: RegistrationService(
                ClienteApi(
                  'http://api.falsa',
                  cliente: _conCorte(
                    '/registro',
                    respuestas,
                    (_) => (404, '{}'),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(rutas.dispose);
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: rutas, theme: darkTheme),
      );
      await tester.pumpAndSettle();
      for (final (campo, valor) in [
        ('Nombre', 'Ana'),
        ('Apellido', 'Pérez'),
        ('DNI', '12345678'),
        ('Fecha de nacimiento', '14032000'),
        ('Correo electrónico', 'ana@correo.com'),
        ('Contraseña', 'ClubNahuel1'),
      ]) {
        await tester.enterText(find.bySemanticsLabel(campo), valor);
      }
      await tester.pump();
      await tester.ensureVisible(find.text('CREAR CUENTA'));
      await tester.pump();
      await tester.tap(find.text('CREAR CUENTA'), warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'un 409 después de un corte dice que la cuenta ya existe y ofrece iniciar sesión',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await abrirRegistro(tester, [null, (409, yaRegistrado)]);
        expect(find.text('Error de conexión'), findsOneWidget);

        await tester.tap(find.text('REINTENTAR'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Tu cuenta ya existe'), findsOneWidget);
        expect(find.text('Ese correo ya está registrado'), findsNothing);
        await tester.ensureVisible(find.text('INICIAR SESIÓN'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('INICIAR SESIÓN'));
        await tester.pumpAndSettle();
        expect(find.text('Iniciar sesión'), findsOneWidget);
        semantica.dispose();
      },
    );

    testWidgets('un 409 sin corte sigue marcando el correo repetido', (
      tester,
    ) async {
      await abrirRegistro(tester, [(409, yaRegistrado)]);

      expect(find.text('Ese correo ya está registrado'), findsWidgets);
      expect(find.textContaining('Tu cuenta ya existe'), findsNothing);
    });
  });

  testWidgets('cancelar: un 409 después de un corte cuenta como cancelada', (
    tester,
  ) async {
    final futura = DateTime.now().toUtc().add(const Duration(days: 2));
    final inicio = DateTime.utc(futura.year, futura.month, futura.day, 21);
    final proxima = reservaJson(
      inicio: inicio.toIso8601String(),
      fin: inicio.add(const Duration(hours: 1)).toIso8601String(),
    );
    final rutas = rutasDeSedes();
    var cancelada = false;
    await montarUsuario(
      tester,
      inicio: '/reservas',
      api: ClienteApi(
        'http://api.falsa',
        cliente: _conCorte(
          '/reservas/00000000-0000-7000-8000-000000000001/cancelar',
          [
            null,
            (409, '{"errores": {"reserva": "Esto cambió mientras tanto"}}'),
          ],
          (pedido) {
            if (pedido.method == 'GET' && pedido.url.path == '/reservas') {
              return (200, '{"reservas": ${cancelada ? '[]' : '[$proxima]'}}');
            }
            return rutas['${pedido.method} ${pedido.url.path}'] ?? (404, '{}');
          },
          alLlegar: () => cancelada = true,
        ),
      ),
    );

    await tester.ensureVisible(find.text('CANCELAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCELAR RESERVA'));
    await tester.pumpAndSettle();
    expect(find.text('Error de conexión'), findsOneWidget);

    await tester.tap(find.text('REINTENTAR'));
    await tester.pumpAndSettle();

    expect(find.text('Reserva cancelada con éxito'), findsOneWidget);
    expect(find.text('Esto cambió mientras tanto'), findsNothing);
  });

  testWidgets('anular: un 409 después de un corte cuenta como anulada', (
    tester,
  ) async {
    final api = ClienteApi(
      'http://api.falsa',
      cliente: _conCorte(
        '/reservas/00000000-0000-7000-8000-000000000001/anular',
        [null, (409, '{"errores": {"reserva": "Esto cambió mientras tanto"}}')],
        (pedido) => switch (pedido.url.path) {
          '/reservas/todas' => (200, anular.listado(anular.reservaJson())),
          '/espacios/catalogo' => (200, catalogoJson),
          _ => (404, '{}'),
        },
      ),
    );
    final sesion = SesionFalsa(perfilAdmin);
    await montar(
      tester,
      AdminPanelScreen(
        history: BookingHistory(api: api, sesion: sesion),
        venues: Venues(
          repository: VenuesRepository(api: api, session: sesion),
        ),
        spaces: Spaces(
          repository: SpacesRepository(api: api, session: sesion),
        ),
        session: sesion,
        pending: PendingPanelFilters(),
      ),
      tema: darkTheme,
    );

    await tester.ensureVisible(find.text('ANULAR RESERVA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ANULAR RESERVA'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Lluvia');
    await tester.ensureVisible(find.text('CONFIRMAR ANULACIÓN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONFIRMAR ANULACIÓN'));
    await tester.pumpAndSettle();
    expect(find.text('Error de conexión'), findsOneWidget);

    await tester.tap(find.text('REINTENTAR'));
    await tester.pumpAndSettle();

    expect(find.text('Reserva anulada correctamente'), findsOneWidget);
    expect(find.text('Esto cambió mientras tanto'), findsNothing);
  });
}
