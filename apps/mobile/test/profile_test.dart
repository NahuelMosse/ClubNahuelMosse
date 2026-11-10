import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/features/users/domain/registration_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/mount.dart';

void main() {
  setUpAll(loadFonts);

  late FakeCredentials credentials;
  final edits = <String>[];
  var deactivations = 0;

  /// The real app on the profile with a signed-in session. [me] is what `GET /yo`
  /// answers when the profile opens; on sign-in it answers the usual profile.
  Future<Appearance> mountProfile(
    WidgetTester tester, {
    (int, String) me = (200, ''),
    (int, String) edit = (200, ''),
    (int, String) deactivation = (204, ''),
    Appearance? appearance,
  }) async {
    credentials = FakeCredentials();
    edits.clear();
    deactivations = 0;
    var queries = 0;
    final api = ApiClient(
      'http://api.falsa',
      cliente: MockClient((request) async {
        if (request.method == 'DELETE') {
          deactivations++;
          final (code, body) = deactivation;
          return http.Response.bytes(utf8.encode(body), code);
        }
        if (request.method == 'PUT') {
          edits.add(request.body);
          final (code, body) = edit;
          return http.Response.bytes(utf8.encode(body), code);
        }
        queries++;
        final (code, body) = queries == 1 || me.$1 == 200
            ? (200, profileJson())
            : me;
        return http.Response.bytes(utf8.encode(body), code);
      }),
    );
    final session = Session(
      repository: SessionRepository(credentials: credentials, api: api),
    );
    await session.signIn('nahuel@correo.com', 'ClubNahuel1');
    final appearanceUsed = appearance ?? Appearance.inMemory();
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      App(
        api: api,
        session: session,
        appearance: appearanceUsed,
        initialLocation: '/perfil',
      ),
    );
    await tester.pumpAndSettle();
    return appearanceUsed;
  }

  testWidgets('shows the data with the DNI and the date to read', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mountProfile(tester);
    expect(find.text('DATOS PERSONALES'), findsOneWidget);
    expect(find.text('42.118.507'), findsOneWidget);
    expect(find.text('14/03/2000'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Correo: nahuel@correo.com. No se puede cambiar'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('the theme selector changes the app and is saved', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    SharedPreferences.setMockInitialValues({});
    final appearance = await mountProfile(
      tester,
      appearance: await Appearance.load(),
    );
    expect(appearance.dark, isTrue);

    await tester.ensureVisible(find.bySemanticsLabel('Modo oscuro'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Modo oscuro'));
    await tester.pumpAndSettle();

    expect(appearance.dark, isFalse);
    expect(
      Theme.of(tester.element(find.text('DATOS PERSONALES'))).brightness,
      Brightness.light,
    );
    final saved = await SharedPreferences.getInstance();
    expect(saved.getBool('modo_oscuro'), isFalse);
    semantics.dispose();
  });

  testWidgets(
    'if the server fails it shows no data and «ACEPTAR» leads to the home',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await mountProfile(tester, me: (503, ''));
      expect(find.text('Error del servidor'), findsOneWidget);
      expect(find.text('DATOS PERSONALES'), findsNothing);
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('with an expired session it shows no data and signs out', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mountProfile(tester, me: (401, '{}'));
    expect(find.text('Tu sesión expiró'), findsOneWidget);
    expect(find.text('DATOS PERSONALES'), findsNothing);
    await tester.tap(find.text('IR AL INICIO DE SESIÓN'));
    await tester.pumpAndSettle();
    expect(credentials.signOuts, 1);
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    '«ELIMINAR CUENTA» asks for confirmation and canceling does nothing',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await mountProfile(tester);
      await tester.ensureVisible(find.text('ELIMINAR CUENTA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ELIMINAR CUENTA'));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);
      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar tu cuenta?'), findsNothing);
      expect(credentials.signOuts, 0);
      semantics.dispose();
    },
  );

  test('the DNI reads with thousands dots and the date with slashes', () {
    expect(readableDni('42118507'), '42.118.507');
    expect(readableDni('4211850'), '4.211.850');
    expect(readableDate(DateTime(2000, 3, 4)), '04/03/2000');
  });

  test('a profile without DNI or date is a server error', () async {
    final session = Session(
      repository: SessionRepository(
        credentials: FakeCredentials(),
        api: apiRoutes({
          'GET /me': (
            200,
            '{"first_name": "N", "last_name": "M", "email": "a@b.com", "role": "user"}',
          ),
        }),
      ),
    );
    await expectLater(
      session.signIn('a@b.com', 'Clave1234'),
      throwsA(isA<Exception>()),
    );
  });

  group('editing the personal data', () {
    Future<void> startEditing(WidgetTester tester) async {
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
    }

    Future<void> save(WidgetTester tester) async {
      await tester.ensureVisible(find.text('GUARDAR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();
    }

    testWidgets('saves the normalized data and returns to read mode', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountProfile(
        tester,
        edit: (
          200,
          '{"first_name": "Agustín", "last_name": "Mosse", "email": "nahuel@correo.com", '
              '"role": "user", "dni": "42118507", "birth_date": "2000-03-14"}',
        ),
      );
      await startEditing(tester);
      await tester.enterText(find.bySemanticsLabel('Nombre'), '  Agustín ');
      await save(tester);

      expect(edits, [
        '{"first_name":"Agustín","last_name":"Mosse","dni":"42118507",'
            '"birth_date":"2000-03-14"}',
      ]);
      expect(find.text('GUARDAR'), findsNothing);
      expect(find.text('Agustín Mosse'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets(
      'flags the invalid data with the prototype message and sends nothing',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await mountProfile(tester);
        await startEditing(tester);
        await tester.enterText(find.bySemanticsLabel('DNI'), '42118');
        await tester.enterText(
          find.bySemanticsLabel('Fecha de nacimiento'),
          '32132000',
        );
        await tester.enterText(find.bySemanticsLabel('Apellido'), '');
        await save(tester);

        expect(
          find.text('El formato de los datos no es válido'),
          findsNWidgets(3),
        );
        expect(edits, isEmpty);

        // Fixing one field clears its error and the others remain.
        await tester.enterText(find.bySemanticsLabel('DNI'), '42118507');
        await tester.pump();
        expect(
          find.text('El formato de los datos no es válido'),
          findsNWidgets(2),
        );
        semantics.dispose();
      },
    );

    testWidgets('a DNI from another account is flagged with its own message', (
      tester,
    ) async {
      // Verifies CU-06-SUP-02.
      final semantics = tester.ensureSemantics();
      await mountProfile(
        tester,
        edit: (409, '{"errors": {"dni": "Este DNI ya está registrado"}}'),
      );
      await startEditing(tester);
      await tester.enterText(find.bySemanticsLabel('DNI'), '30111222');
      await save(tester);
      expect(find.text('Este DNI ya está registrado'), findsOneWidget);
      expect(find.text('GUARDAR'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('if the server fails it keeps what was typed', (tester) async {
      final semantics = tester.ensureSemantics();
      await mountProfile(tester, edit: (500, ''));
      await startEditing(tester);
      await tester.enterText(find.bySemanticsLabel('Nombre'), 'Agustín');
      await save(tester);
      expect(find.text('Error del servidor'), findsOneWidget);
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      final firstName = tester.widget<TextField>(
        find.descendant(
          of: find.bySemanticsLabel('Nombre'),
          matching: find.byType(TextField),
        ),
      );
      expect(firstName.controller?.text, 'Agustín');
      semantics.dispose();
    });
  });

  testWidgets(
    'the calendar opens even if the typed date is today or in the future',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await mountProfile(tester);
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.bySemanticsLabel('Fecha de nacimiento'),
        '01012999',
      );
      await tester.tap(find.byTooltip('Elegir la fecha en el calendario'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('the Home and the avatar follow the profile when it changes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = Session(
      repository: SessionRepository(
        credentials: FakeCredentials(),
        api: apiRoutes({
          'GET /me': (200, profileJson()),
          'PUT /me': (
            200,
            '{"first_name": "Agustín", "last_name": "Paz", "email": "nahuel@correo.com", '
                '"role": "user", "dni": "42118507", "birth_date": "2000-03-14"}',
          ),
        }),
      ),
    );
    await session.signIn('a@b.com', 'Clave1234');
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      App(
        api: homeApi(),
        session: session,
        appearance: Appearance.inMemory(),
        initialLocation: '/inicio',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nahuel'), findsOneWidget);

    await session.updateProfile(
      firstName: 'Agustín',
      lastName: 'Paz',
      dni: '42118507',
      birthDate: '2000-03-14',
    );
    await tester.pumpAndSettle();
    expect(find.text('Agustín'), findsOneWidget);
    expect(find.text('AP'), findsOneWidget);
    semantics.dispose();
  });

  group('deactivating the account', () {
    Future<void> confirmDeactivation(WidgetTester tester) async {
      await tester.ensureVisible(find.text('ELIMINAR CUENTA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ELIMINAR CUENTA'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('ELIMINAR CUENTA'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('confirmed, it deactivates, signs out and goes to the login', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountProfile(tester);
      await confirmDeactivation(tester);
      expect(deactivations, 1);
      expect(credentials.signOuts, 1);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets(
      'if the server fails the account stays and the button comes back',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await mountProfile(tester, deactivation: (500, ''));
        await confirmDeactivation(tester);
        expect(find.text('Error del servidor'), findsOneWidget);
        await tester.tap(find.text('ACEPTAR'));
        await tester.pumpAndSettle();
        expect(credentials.signOuts, 0);
        expect(find.text('ELIMINAR CUENTA'), findsOneWidget);
        expect(find.text('DATOS PERSONALES'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets('with an expired session it warns and signs out', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountProfile(tester, deactivation: (401, '{}'));
      await confirmDeactivation(tester);
      expect(find.text('Tu sesión expiró'), findsOneWidget);
      semantics.dispose();
    });
  });

  test(
    'a deactivation that returns after signing in with another account does not sign it out',
    () async {
      final response = Completer<http.Response>();
      final credentials = FakeCredentials();
      final session = Session(
        repository: SessionRepository(
          credentials: credentials,
          api: ApiClient(
            'http://api.falsa',
            cliente: MockClient((request) async {
              if (request.method == 'DELETE') return response.future;
              return http.Response(profileJson(), 200);
            }),
          ),
        ),
      );
      await session.signIn('a@b.com', 'Clave1234');
      final deactivation = session.deactivate();
      await session.close();
      await session.signIn('otra@b.com', 'Clave1234');
      response.complete(http.Response('', 204));
      await deactivation;

      expect(session.profile, isNotNull);
      expect(credentials.signOuts, 1);
    },
  );

  testWidgets(
    'a 401 when retrying after an outage counts as deactivation done',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var attempts = 0;
      credentials = FakeCredentials();
      final api = ApiClient(
        'http://api.falsa',
        cliente: MockClient((request) async {
          if (request.method == 'DELETE') {
            attempts++;
            if (attempts == 1) throw const SocketException('se cortó');
            return http.Response('{}', 401);
          }
          return http.Response.bytes(utf8.encode(profileJson()), 200);
        }),
      );
      final session = Session(
        repository: SessionRepository(credentials: credentials, api: api),
      );
      await session.signIn('nahuel@correo.com', 'ClubNahuel1');
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        App(
          api: api,
          session: session,
          appearance: Appearance.inMemory(),
          initialLocation: '/perfil',
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ELIMINAR CUENTA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ELIMINAR CUENTA'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('ELIMINAR CUENTA'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Error de conexión'), findsOneWidget);

      await tester.tap(find.text('REINTENTAR'));
      await tester.pumpAndSettle();
      expect(find.text('Tu sesión expiró'), findsNothing);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantics.dispose();
    },
  );
}
