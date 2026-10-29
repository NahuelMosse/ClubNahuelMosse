import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'package:clubnahuelmosse/features/session/data/password_recovery.dart';
import 'package:clubnahuelmosse/features/session/presentation/forgot_password_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/new_password_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'soporte/montar.dart';

void main() {
  setUpAll(cargarFuentes);

  late List<http.Request> requests;

  /// Monta [pantalla] dentro de rutas mínimas, para ver adónde lleva cada botón.
  Future<void> montarEnRutas(WidgetTester tester, Widget pantalla) async {
    final rutas = GoRouter(
      initialLocation: '/pantalla',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('LOGIN')),
        GoRoute(path: '/pantalla', builder: (_, _) => pantalla),
        GoRoute(
          path: '/recuperar-contrasena',
          builder: (_, _) => const Text('PEDIR'),
        ),
      ],
    );
    addTearDown(rutas.dispose);
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
  }

  PasswordRecovery recuperacion(Map<String, (int, String)> respuestas) {
    requests = [];
    return PasswordRecovery(apiRutas(respuestas, pedidos: requests));
  }

  bool habilitado(WidgetTester tester, String button) =>
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, button))
          .onPressed !=
      null;

  group('pedir el enlace', () {
    testWidgets(
      'con un correo mal escrito no deja enviar y lo marca al salir',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await montarEnRutas(
          tester,
          ForgotPasswordScreen(
            recovery: recuperacion({'POST /recuperacion': (202, '')}),
          ),
        );
        await tester.enterText(
          find.bySemanticsLabel('Correo electrónico'),
          'nmosse@unimoron',
        );
        await tester.pump();
        expect(find.text('Revisá el formato del correo'), findsNothing);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(find.text('Revisá el formato del correo'), findsOneWidget);
        expect(habilitado(tester, 'ENVIAR ENLACE'), isFalse);
        expect(requests, isEmpty);
        semantica.dispose();
      },
    );

    testWidgets('envía el correo normalizado, muestra el aviso y reenvía', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarEnRutas(
        tester,
        ForgotPasswordScreen(
          recovery: recuperacion({'POST /recuperacion': (202, '')}),
        ),
      );
      await tester.enterText(
        find.bySemanticsLabel('Correo electrónico'),
        ' Nahuel@Correo.com ',
      );
      await tester.pump();
      await tester.tap(find.text('ENVIAR ENLACE'));
      await tester.pumpAndSettle();

      expect(find.text('Revisá tu correo'), findsOneWidget);
      expect(
        find.text(
          'Si el correo está registrado, te enviamos un enlace para crear una contraseña nueva. El enlace vence en 30 minutos.',
        ),
        findsOneWidget,
      );
      expect(requests.single.body, '{"correo":"nahuel@correo.com"}');

      await tester.tap(find.text('Reenviar el correo'));
      await tester.pumpAndSettle();
      expect(requests, hasLength(2));

      await tester.tap(find.text('VOLVER AL INICIO DE SESIÓN'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('si el servidor falla no muestra el aviso de enviado', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarEnRutas(
        tester,
        ForgotPasswordScreen(
          recovery: recuperacion({'POST /recuperacion': (500, '')}),
        ),
      );
      await tester.enterText(
        find.bySemanticsLabel('Correo electrónico'),
        'nahuel@correo.com',
      );
      await tester.pump();
      await tester.tap(find.text('ENVIAR ENLACE'));
      await tester.pumpAndSettle();
      expect(find.text('Error del servidor'), findsOneWidget);
      expect(find.text('Revisá tu correo'), findsNothing);
      semantica.dispose();
    });
  });

  group('crear la contraseña nueva', () {
    Widget pantalla(Map<String, (int, String)> respuestas) => NewPasswordScreen(
      recovery: recuperacion(respuestas),
      session: SesionFalsa(null),
      code: 'abc',
    );

    testWidgets('un enlace que ya no sirve lleva a pedir otro', (tester) async {
      final semantica = tester.ensureSemantics();
      await montarEnRutas(
        tester,
        pantalla({'POST /recuperacion/consulta': (410, '')}),
      );
      expect(find.text('El enlace no es válido'), findsOneWidget);
      await tester.tap(find.text('PEDIR UN ENLACE NUEVO'));
      await tester.pumpAndSettle();
      expect(find.text('PEDIR'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('sin código ni siquiera consulta a la API', (tester) async {
      final semantica = tester.ensureSemantics();
      await montarEnRutas(
        tester,
        NewPasswordScreen(
          recovery: recuperacion({}),
          session: SesionFalsa(null),
          code: '',
        ),
      );
      expect(find.text('El enlace no es válido'), findsOneWidget);
      expect(requests, isEmpty);
      semantica.dispose();
    });

    testWidgets('guarda con un enlace vigente y vuelve al login', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarEnRutas(
        tester,
        pantalla({
          'POST /recuperacion/consulta': (204, ''),
          'PUT /recuperacion': (204, ''),
        }),
      );
      expect(habilitado(tester, 'GUARDAR CONTRASEÑA'), isFalse);
      await tester.enterText(
        find.bySemanticsLabel('Contraseña nueva'),
        'ClubNahuel2',
      );
      await tester.enterText(
        find.bySemanticsLabel('Repetir contraseña'),
        'ClubNahuel2',
      );
      await tester.pump();
      await tester.tap(find.text('GUARDAR CONTRASEÑA'));
      await tester.pumpAndSettle();

      expect(find.text('Contraseña actualizada'), findsOneWidget);
      expect(requests.last.body, '{"codigo":"abc","nueva":"ClubNahuel2"}');
      await tester.tap(find.text('VOLVER AL INICIO DE SESIÓN'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('si el enlace se usó mientras escribía, lo avisa al guardar', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarEnRutas(
        tester,
        pantalla({
          'POST /recuperacion/consulta': (204, ''),
          'PUT /recuperacion': (410, ''),
        }),
      );
      await tester.enterText(
        find.bySemanticsLabel('Contraseña nueva'),
        'ClubNahuel2',
      );
      await tester.enterText(
        find.bySemanticsLabel('Repetir contraseña'),
        'ClubNahuel2',
      );
      await tester.pump();
      await tester.tap(find.text('GUARDAR CONTRASEÑA'));
      await tester.pumpAndSettle();
      expect(find.text('El enlace no es válido'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('la repetición distinta no deja guardar', (tester) async {
      final semantica = tester.ensureSemantics();
      await montarEnRutas(
        tester,
        pantalla({'POST /recuperacion/consulta': (204, '')}),
      );
      await tester.enterText(
        find.bySemanticsLabel('Contraseña nueva'),
        'ClubNahuel2',
      );
      await tester.enterText(
        find.bySemanticsLabel('Repetir contraseña'),
        'ClubNahuel3',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(habilitado(tester, 'GUARDAR CONTRASEÑA'), isFalse);
      semantica.dispose();
    });
  });

  group('abrir la app desde el enlace', () {
    Future<void> abrir(WidgetTester tester, String ruta) async {
      await tester.binding.handlePushRoute(ruta);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'un enlace nuevo con la pantalla abierta se vuelve a comprobar',
      (tester) async {
        final requests = <http.Request>[];
        final api = apiRutas({
          'POST /recuperacion/consulta': (410, ''),
        }, pedidos: requests);
        await tester.pumpWidget(
          App(
            api: api,
            session: SesionFalsa(null),
            appearance: Appearance.inMemory(),
            initialLocation: '/recuperar?codigo=viejo',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('El enlace no es válido'), findsOneWidget);

        await abrir(tester, '/recuperar?codigo=nuevo');
        expect(requests.map((p) => p.body), [
          '{"codigo":"viejo"}',
          '{"codigo":"nuevo"}',
        ]);
      },
    );

    testWidgets('con la sesión abierta, al terminar la cierra y va al login', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final session = SesionFalsa(perfilUsuario);
      await tester.pumpWidget(
        App(
          api: apiRutas({
            'POST /recuperacion/consulta': (204, ''),
            'PUT /recuperacion': (204, ''),
          }),
          session: session,
          appearance: Appearance.inMemory(),
          initialLocation: '/recuperar?codigo=abc',
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.bySemanticsLabel('Contraseña nueva'),
        'ClubNahuel2',
      );
      await tester.enterText(
        find.bySemanticsLabel('Repetir contraseña'),
        'ClubNahuel2',
      );
      await tester.pump();
      await tester.tap(find.text('GUARDAR CONTRASEÑA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('VOLVER AL INICIO DE SESIÓN'));
      await tester.pumpAndSettle();

      expect(session.cierres, 1);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantica.dispose();
    });
  });
}
