import 'package:clubnahuelmosse/features/users/data/registration_service.dart';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/bottom_bar.dart';
import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/common/calendar.dart';
import 'package:clubnahuelmosse/common/text_field.dart';
import 'package:clubnahuelmosse/features/admin/presentation/deactivation_dialogs.dart';
import 'package:clubnahuelmosse/common/selector.dart';
import 'package:clubnahuelmosse/common/clock.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'my_bookings_test.dart' show bookingJson;
import 'support/admin.dart';
import 'support/mount.dart';
import 'support/user.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_screen.dart';

/// The WCAG contrast between two opaque colors.
double contrast(Color a, Color b) {
  final (lighter, darker) = a.computeLuminance() > b.computeLuminance()
      ? (a.computeLuminance(), b.computeLuminance())
      : (b.computeLuminance(), a.computeLuminance());
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  setUpAll(loadFonts);

  Future<void> tapAndSettle(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  group('registration', () {
    const missing = [
      'El nombre es obligatorio',
      'El apellido es obligatorio',
      'El DNI es obligatorio',
      'La fecha de nacimiento es obligatoria',
      'El correo es obligatorio',
      'La contraseña es obligatoria',
    ];

    testWidgets(
      'tapping «CREAR CUENTA» with an empty form shows every missing field @REV-04-S1',
      (tester) async {
        final requests = <http.Request>[];
        await mountScreen(
          tester,
          RegistrationScreen(
            registration: RegistrationService(
              apiRoutes({}, requests: requests),
            ),
          ),
          theme: darkTheme,
        );

        await tapAndSettle(tester, find.text('CREAR CUENTA'));

        for (final message in missing) {
          expect(find.text(message), findsOneWidget, reason: message);
        }
        expect(requests, isEmpty);
      },
    );

    testWidgets(
      'leaving an empty field shows no error before trying to create the account '
      '@REV-04-S1 @assumption:REV-04-ASM-01',
      (tester) async {
        await mountScreen(
          tester,
          RegistrationScreen(registration: RegistrationService(apiRoutes({}))),
          theme: darkTheme,
        );

        await tester.tap(find.bySemanticsLabel('Nombre'));
        await tester.pump();
        await tester.tap(find.bySemanticsLabel('Apellido'));
        await tester.pumpAndSettle();

        expect(find.text('El nombre es obligatorio'), findsNothing);
      },
    );

    testWidgets(
      'the screen reader announces the birth date format @REV-04-S4',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await mountScreen(
          tester,
          RegistrationScreen(registration: RegistrationService(apiRoutes({}))),
          theme: darkTheme,
        );

        final node = tester.getSemantics(
          find.bySemanticsLabel(RegExp('^Fecha de nacimiento')),
        );

        expect(
          '${node.label} ${node.hint} ${node.value}',
          contains('DD / MM / AAAA'),
        );
        semantics.dispose();
      },
    );
  });

  testWidgets(
    'the screen reader announces a field error together with the field @REV-04-S3',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: FormTextField(
              label: 'NOMBRE',
              semanticLabel: 'Nombre',
              controller: TextEditingController(),
              placeholder: 'Tu nombre',
              error: 'El nombre es obligatorio',
            ),
          ),
        ),
      );

      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Nombre')),
      );

      expect(
        '${node.label} ${node.hint} ${node.value}',
        contains('El nombre es obligatorio'),
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'saving a venue edit without a name shows what is missing and does not send '
    '@REV-04-S2 @assumption:REV-04-ASM-04',
    (tester) async {
      final requests = <http.Request>[];
      await mountAdmin(
        tester,
        api: ApiClient(
          'http://api.falsa',
          cliente: MockClient((request) async {
            requests.add(request);
            final (status, body) = switch ((request.method, request.url.path)) {
              ('GET', '/venues') => (200, '{"venues": [$venueMoronJson]}'),
              ('PUT', '/venues/00000000-0000-7000-8000-000000000001') => (
                200,
                venueMoronJson,
              ),
              _ => (404, '{}'),
            };
            return http.Response.bytes(
              utf8.encode(body),
              status,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );
      await tapAndSettle(
        tester,
        find.bySemanticsLabel('Editar sede Sede Morón'),
      );
      final name = find.descendant(
        of: find.bySemanticsLabel(RegExp('^Nombre')),
        matching: find.byType(EditableText),
      );
      await tester.enterText(name, '');
      await tapAndSettle(
        tester,
        find.descendant(
          of: find.bySemanticsLabel(RegExp('^Dirección')),
          matching: find.byType(EditableText),
        ),
      );

      await tapAndSettle(tester, find.text('GUARDAR CAMBIOS'));

      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      expect(
        tester.widget<EditableText>(name).focusNode.hasPrimaryFocus,
        isTrue,
      );
      expect(requests.where((p) => p.method == 'PUT'), isEmpty);
    },
  );

  Future<void> untilConfirmBooking(WidgetTester tester) async {
    await mountUser(
      tester,
      start:
          '/sedes/00000000-0000-7000-8000-000000000001/canchas/00000000-0000-7000-8000-000000000009',
      api: apiRoutes({
        ...venueRoutes(),
        'POST /bookings': (
          422,
          '{"errors": {"date": "Ese horario ya empezó"}}',
        ),
      }),
    );
    await tapAndSettle(tester, find.bySemanticsLabel('18:00 – 19:00'));
    await tapAndSettle(tester, find.text('CONTINUAR'));
  }

  testWidgets('a booking rejection stays in view until the person closes it '
      '@REV-04-S5 @assumption:REV-04-ASM-02', (tester) async {
    await untilConfirmBooking(tester);

    await tapAndSettle(tester, find.text('CONFIRMAR RESERVA'));
    // I20: the notice must still be there after 10 s; it is the test clock, not a real wait.
    await tester.pump(const Duration(seconds: 10));

    expect(find.text('Ese horario ya empezó'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    await tapAndSettle(tester, find.text('ELEGIR OTRO HORARIO'));
    expect(find.text('Ese horario ya empezó'), findsNothing);
    expect(find.text('HORARIO DISPONIBLE'), findsOneWidget);
  });

  testWidgets(
    'a booking change rejection stays in view until the person closes it '
    '@REV-04-S6 @assumption:REV-04-ASM-02',
    (tester) async {
      final routes = venueRoutes(grid: gridJson(taken: {9, 12}));
      await mountUser(
        tester,
        start: '/reservas',
        api: apiRoutes({
          ...routes,
          'GET /bookings': (200, '{"bookings": [${bookingJson()}]}'),
          'POST /bookings/00000000-0000-7000-8000-000000000001/modify': (
            422,
            '{"errors": {"date": "Ese horario ya empezó"}}',
          ),
        }),
      );
      await tapAndSettle(tester, find.text('MODIFICAR'));
      await tapAndSettle(tester, find.text('19:00 – 20:00'));
      await tapAndSettle(tester, find.text('CONTINUAR CON EL CAMBIO'));

      await tapAndSettle(tester, find.text('GUARDAR EL CAMBIO'));
      // I20: the notice must still be there after 10 s; it is the test clock, not a real wait.
      await tester.pump(const Duration(seconds: 10));

      expect(find.text('Ese horario ya empezó'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tapAndSettle(tester, find.text('ELEGIR OTRO HORARIO'));
      expect(find.text('Ese horario ya empezó'), findsNothing);
    },
  );

  testWidgets(
    'confirming a cancellation puts the focus on the option that does not cancel '
    '@REV-04-S7 @assumption:REV-04-ASM-03',
    (tester) async {
      final future = DateTime.now().toUtc().add(const Duration(days: 2));
      final start = DateTime.utc(future.year, future.month, future.day, 21);
      final upcoming = bookingJson(
        start: start.toIso8601String(),
        end: start.add(const Duration(hours: 1)).toIso8601String(),
      );
      await mountUser(
        tester,
        start: '/reservas',
        api: apiRoutes({
          ...venueRoutes(),
          'GET /bookings': (200, '{"bookings": [$upcoming]}'),
        }),
      );

      await tapAndSettle(tester, find.text('CANCELAR'));

      expect(find.text('¿Cancelar la reserva?'), findsOneWidget);
      expect(
        Focus.of(tester.element(find.text('NO CANCELAR'))).hasPrimaryFocus,
        isTrue,
      );
    },
  );

  Future<void> openDialog(
    WidgetTester tester,
    Future<bool> Function(BuildContext) open,
  ) async {
    await mountScreen(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => open(context),
            child: const Text('ABRIR'),
          ),
        ),
      ),
      theme: darkTheme,
    );
    await tapAndSettle(tester, find.text('ABRIR'));
  }

  bool focused(WidgetTester tester, String text) =>
      Focus.of(tester.element(find.text(text))).hasPrimaryFocus;

  testWidgets(
    'deactivating a venue puts the focus on «CANCELAR» @REV-04-S7 @assumption:REV-04-ASM-03',
    (tester) async {
      await openDialog(
        tester,
        (c) => confirmVenueDeactivation(c, 'Sede Morón'),
      );

      expect(focused(tester, 'CANCELAR'), isTrue);
      expect(
        tester.getTopLeft(find.text('DAR DE BAJA')).dy,
        lessThan(tester.getTopLeft(find.text('CANCELAR')).dy),
      );
    },
  );

  testWidgets(
    'deactivating a space puts the focus on «CANCELAR» @REV-04-S7 @assumption:REV-04-ASM-03',
    (tester) async {
      await openDialog(
        tester,
        (c) => confirmSpaceDeactivation(c, 'Moron_Rivadavia_19850_Futbol_F5_1'),
      );

      expect(focused(tester, 'CANCELAR'), isTrue);
    },
  );

  testWidgets(
    'the screen reader announces a selector error together with the selector @REV-04-S3',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await mountScreen(
        tester,
        Scaffold(
          body: SelectorField(
            label: 'DEPORTE',
            semanticLabel: 'Deporte',
            value: null,
            placeholder: 'Elegí un deporte',
            icon: Icons.sports_soccer,
            onTap: () {},
            error: 'Elegí un deporte',
          ),
        ),
        theme: darkTheme,
      );

      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Deporte')),
      );

      expect(
        '${node.label} ${node.hint} ${node.value}',
        contains('Elegí un deporte'),
      );
      expect(find.bySemanticsLabel('Elegí un deporte'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'in registration a field error is part of the field and not a separate node @REV-04-S3',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await mountScreen(
        tester,
        RegistrationScreen(registration: RegistrationService(apiRoutes({}))),
        theme: darkTheme,
      );

      await tapAndSettle(tester, find.text('CREAR CUENTA'));

      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Nombre')),
      );
      expect(
        '${node.label} ${node.hint} ${node.value}',
        contains('El nombre es obligatorio'),
      );
      expect(find.bySemanticsLabel('El nombre es obligatorio'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'with one field filled only what is missing is marked, and typing it clears its error '
    '@REV-04-S1 @assumption:REV-04-ASM-01',
    (tester) async {
      final requests = <http.Request>[];
      await mountScreen(
        tester,
        RegistrationScreen(
          registration: RegistrationService(
            apiRoutes({
              'POST /register': (
                201,
                '{"id": "00000000-0000-7000-8000-000000000001"}',
              ),
            }, requests: requests),
          ),
        ),
        theme: darkTheme,
      );
      await tester.enterText(find.bySemanticsLabel('Nombre'), 'Ana');
      await tester.enterText(find.bySemanticsLabel('Apellido'), 'Pérez');
      await tester.enterText(find.bySemanticsLabel('DNI'), '12345678');
      await tester.enterText(
        find.bySemanticsLabel('Fecha de nacimiento'),
        '14032000',
      );
      await tester.enterText(
        find.bySemanticsLabel('Contraseña'),
        'ClubNahuel1',
      );

      await tapAndSettle(tester, find.text('CREAR CUENTA'));

      expect(find.text('El correo es obligatorio'), findsOneWidget);
      expect(find.text('El nombre es obligatorio'), findsNothing);
      expect(requests, isEmpty);
      await tester.enterText(
        find.bySemanticsLabel('Correo electrónico'),
        'ana@correo.com',
      );
      await tester.pumpAndSettle();
      expect(find.text('El correo es obligatorio'), findsNothing);
      await tapAndSettle(tester, find.text('CREAR CUENTA'));
      expect(requests.where((p) => p.url.path == '/register'), hasLength(1));
    },
  );

  testWidgets('a typed birth date is compared with the club day @REV-04-S10 '
      '@assumption:REV-04-ASM-08', (tester) async {
    // 02:30 UTC on 13 November: at the club it is still the 12th.
    await withClock(Clock.fixed(DateTime.utc(2026, 11, 13, 2, 30)), () async {
      await mountScreen(
        tester,
        RegistrationScreen(registration: RegistrationService(apiRoutes({}))),
        theme: darkTheme,
      );
      await tester.enterText(
        find.bySemanticsLabel('Fecha de nacimiento'),
        '12112026',
      );
      await tapAndSettle(tester, find.text('CREAR CUENTA'));
      expect(
        find.text('La fecha tiene que ser anterior a hoy'),
        findsOneWidget,
      );

      await tester.enterText(
        find.bySemanticsLabel('Fecha de nacimiento'),
        '11112026',
      );
      await tester.pumpAndSettle();
      expect(find.text('La fecha tiene que ser anterior a hoy'), findsNothing);
    });
  });

  for (final width in [320.0, 360.0]) {
    testWidgets(
      'at ${width.toInt()} wide and with text at 200 % the member bar shows each destination '
      'whole @REV-04-S8 @assumption:REV-04-ASM-05',
      (tester) async {
        await mountScreen(
          tester,
          const Scaffold(
            bottomNavigationBar: BottomBar(current: Section.bookings),
          ),
          theme: darkTheme,
          size: Size(width, 800),
          textScale: 2,
        );

        for (final destination in ['INICIO', 'SEDES', 'RESERVAS', 'PERFIL']) {
          final rect = tester.getRect(find.text(destination));
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(destination),
          );
          expect(paragraph.didExceedMaxLines, isFalse, reason: destination);
          expect(
            paragraph.size.width,
            greaterThanOrEqualTo(
              paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5,
            ),
            reason: destination,
          );
          expect(rect.left, greaterThanOrEqualTo(0), reason: destination);
          expect(rect.right, lessThanOrEqualTo(width), reason: destination);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'with text at 200 % the member bar shows RESERVAS whole @REV-04-S8',
    (tester) async {
      await mountScreen(
        tester,
        const Scaffold(
          bottomNavigationBar: BottomBar(current: Section.bookings),
        ),
        theme: darkTheme,
        size: const Size(360, 800),
        textScale: 2,
      );

      final bookings = tester.renderObject<RenderParagraph>(
        find.text('RESERVAS'),
      );
      expect(bookings.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'with text at 200 % the admin bar does not push ESPACIOS to the edge @REV-04-S8',
    (tester) async {
      await mountScreen(
        tester,
        const Scaffold(
          bottomNavigationBar: AdminBar(current: AdminSection.spaces),
        ),
        theme: darkTheme,
        size: const Size(360, 800),
        textScale: 2,
      );

      final spaces = tester.renderObject<RenderParagraph>(
        find.text('ESPACIOS'),
      );
      expect(spaces.didExceedMaxLines, isFalse);
      expect(
        tester.getRect(find.text('ESPACIOS')).right,
        lessThanOrEqualTo(352),
      );
    },
  );

  testWidgets(
    'the dimmed button in dark mode reads with enough contrast @REV-04-S9',
    (tester) async {
      await mountScreen(
        tester,
        Scaffold(
          body: Center(
            child: PrimaryButton(
              label: 'GUARDAR SEDE',
              onTap: () {},
              dimmed: true,
            ),
          ),
        ),
        theme: darkTheme,
      );
      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      // The dimmed background is translucent: what the person sees is its blend with the screen.
      final background = Color.alphaBlend(
        style.backgroundColor!.resolve(<WidgetState>{})!,
        darkTheme.scaffoldBackgroundColor,
      );
      final text = style.foregroundColor!.resolve(<WidgetState>{})!;

      expect(contrast(text, background), greaterThanOrEqualTo(4.5));
    },
  );

  testWidgets('the birth calendar ends the day before the club day @REV-04-S10 '
      '@assumption:REV-04-ASM-08', (tester) async {
    DateTime? picked;
    // 02:30 UTC on 13 November: at the club it is still the 12th at 23:30.
    await withClock(Clock.fixed(DateTime.utc(2026, 11, 13, 2, 30)), () async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es', 'AR'),
          supportedLocales: const [Locale('es', 'AR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  picked = await pickBirthDate(context, DateTime(2030)),
              child: const Text('ABRIR'),
            ),
          ),
        ),
      );
      await tapAndSettle(tester, find.text('ABRIR'));
      await tapAndSettle(
        tester,
        find.textContaining(RegExp('aceptar', caseSensitive: false)),
      );
    });

    expect(picked, DateTime(2026, 11, 11));
  });

  test(
    'the club time comes from the clock, the one the screenshots fix @REV-04-S11',
    () {
      final now = withClock(
        Clock.fixed(DateTime.utc(2026, 11, 13, 2, 30)),
        clubNow,
      );

      expect(
        (now.year, now.month, now.day, now.hour, now.minute),
        (2026, 11, 12, 23, 30),
      );
    },
  );

  Future<void> createSpaceScreen(
    WidgetTester tester, {
    double scale = 1,
  }) async {
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mountAdmin(
      tester,
      start: '/admin/espacios/nuevo',
      size: const Size(320, 568),
      api: apiRoutes(spaceRoutes()),
    );
  }

  testWidgets(
    'the space creation form fits whole on a 320 × 568 screen @REV-04-S12',
    (tester) async {
      await createSpaceScreen(tester);
      await choose(tester, 'Sede', 'Sede Morón');
      await choose(tester, 'Deporte', 'Fútbol');
      await choose(tester, 'Tipo', 'Fútbol 5');
      await tapAndSettle(tester, find.text('GUARDAR ESPACIO'));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'at 320 × 568 the missing fields of the space creation form fit whole @REV-04-S12',
    (tester) async {
      await createSpaceScreen(tester);

      await tapAndSettle(tester, find.text('GUARDAR ESPACIO'));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'at 320 × 568 the complete space creation form, with its generated name, fits whole '
    '@REV-04-S12',
    (tester) async {
      await createSpaceScreen(tester, scale: 1.3);
      await choose(tester, 'Sede', 'Sede Morón');
      await choose(tester, 'Deporte', 'Fútbol');
      await choose(tester, 'Tipo', 'Fútbol 5');
      await choose(tester, 'Condición', 'Al aire libre');
      await choose(tester, 'Iluminación', 'Iluminada');
      await tester.enterText(find.bySemanticsLabel('Precio por hora'), '38000');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('at 320 × 568 the open venue selector fits whole @REV-04-S12', (
    tester,
  ) async {
    await createSpaceScreen(tester);

    await tapAndSettle(tester, find.bySemanticsLabel(RegExp('^Sede')));

    expect(tester.takeException(), isNull);
  });
}
