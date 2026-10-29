import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/features/users/data/registration_service.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_screen.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/montar.dart';

/// Contesta [respuestas] en orden a cada POST a [ruta] (la última se repite); un `null` es
/// un corte de red. Lo que no es ese POST lo contesta [resto].
MockClient _conCorte(
  String ruta,
  List<(int, String)?> respuestas,
  (int, String) Function(http.Request) resto,
) {
  var n = 0;
  return MockClient((pedido) async {
    final (int, String) respuesta;
    if (pedido.url.path == ruta && pedido.method == 'POST') {
      final siguiente =
          respuestas[n < respuestas.length ? n : respuestas.length - 1];
      n++;
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
                ApiClient(
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
        MaterialApp.router(
          theme: darkTheme,
          localeListResolutionCallback: resolveLanguage,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: rutas,
        ),
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
}
