import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/common/text_field.dart';
import 'package:clubnahuelmosse/common/logo_mark.dart';
import 'package:clubnahuelmosse/common/motion.dart';
import 'package:clubnahuelmosse/common/pending_booking.dart';
import 'package:clubnahuelmosse/common/snackbar.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/mount.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'the login enters staggered: logo mark, form, button and footer @RED-04-S6',
    (tester) async {
      await _mountFree(tester, _login());
      Iterable<Duration> delays(Finder f) =>
          _appearances(tester, f).map((a) => a.delay);

      expect(
        _appearances(
          tester,
          find.byType(LogoMark),
        ).any((a) => a.turn != 0 && a.fromY < 0),
        isTrue,
        reason: 'the logo mark drops and spins',
      );
      expect(delays(find.byType(FormTextField).first), contains(_ms(460)));
      expect(delays(find.text('INICIAR SESIÓN')), contains(_ms(540)));
      expect(delays(find.text('¿No tenés cuenta?')), contains(_ms(620)));

      final form = _appearanceWhere(
        find.byType(FormTextField).first,
        (a) => a.delay == _ms(460),
      ).first;
      expect(_opacity(tester, form), 0);
      await tester.pump(_ms(400));
      expect(_opacity(tester, form), 0);
      await tester.pump(_ms(300));
      expect(_opacity(tester, form), allOf(greaterThan(0), lessThan(1)));
      await tester.pumpAndSettle();
      expect(_opacity(tester, form), 1);
    },
  );

  testWidgets(
    'the invalid-credentials notice shakes every time it appears and the same error does not shake the field again @RED-04-ASM-10',
    (tester) async {
      final credentials = FakeCredentials(
        onSignIn: (_, _) async => throw const InvalidCredentials(),
      );
      await _mountFree(tester, _login(credentials: credentials));
      await tester.pumpAndSettle();
      final field = find.byType(TextField).first;

      // Resubmitting empty with the same error: it shakes the first time and not the second.
      await tester.tap(find.text('INICIAR SESIÓN'));
      await _start(tester);
      expect(find.text('Completá tu correo electrónico'), findsOneWidget);
      _expectShakes(await _path(tester, field), reason: 'el campo, 1.ª vez');
      await tester.tap(find.text('INICIAR SESIÓN'));
      await _start(tester);
      expect(find.text('Completá tu correo electrónico'), findsOneWidget);
      _doesNotShake(await _path(tester, field), reason: 'el mismo error');

      // With complete but wrong data, the notice shakes when it appears, every time.
      await tester.enterText(find.byType(TextField).first, 'nahuel@correo.com');
      await tester.enterText(find.byType(TextField).last, 'Mala1234');
      for (var time = 1; time <= 2; time++) {
        await tester.tap(find.text('INICIAR SESIÓN'));
        await _until(
          tester,
          () => find.text(invalidCredentialsMessage).evaluate().isNotEmpty,
        );
        await _start(tester);
        _expectShakes(
          await _path(tester, find.byType(ErrorSnackbar)),
          reason: 'el aviso, $time.ª vez',
        );
        await tester.tap(find.byTooltip('Cerrar aviso'));
        await tester.pumpAndSettle();
        expect(find.text(invalidCredentialsMessage), findsNothing);
      }
      expect(credentials.attempts, hasLength(2));
    },
  );
}

Duration _ms(int n) => Duration(milliseconds: n);

/// What the shake displaces at 60, 120, 180, 240, 300 and 360 ms.
const _shakeOffsets = [-9.0, 9.0, -6.0, 6.0, -3.0, 0.0];

/// The screen with the app's theme and language, without waiting for any animation to finish.
Future<void> _mountFree(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: darkTheme,
      localeListResolutionCallback: resolveLanguage,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: screen,
    ),
  );
}

/// Pumps frames without advancing the clock, so that whatever was triggered starts.
Future<void> _start(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump();
  }
}

/// Pumps frames without advancing the clock until [condition] holds.
Future<void> _until(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 20 && !condition(); i++) {
    await tester.pump();
  }
  expect(condition(), isTrue);
}

/// The `FadeIn`s that wrap [f], from the closest to the farthest.
List<FadeIn> _appearances(WidgetTester tester, Finder f) => tester
    .widgetList<FadeIn>(find.ancestor(of: f, matching: find.byType(FadeIn)))
    .toList();

/// The `FadeIn` that wraps [f] and satisfies [matches].
Finder _appearanceWhere(Finder f, bool Function(FadeIn) matches) =>
    find.ancestor(
      of: f,
      matching: find.byWidgetPredicate((w) => w is FadeIn && matches(w)),
    );

Widget _login({FakeCredentials? credentials}) => LoginScreen(
  session: Session(
    repository: SessionRepository(
      credentials: credentials ?? FakeCredentials(),
      api: fakeApi(status: 200, body: profileJson()),
    ),
  ),
  pending: PendingBooking(),
);

double _opacity(WidgetTester tester, Finder appearance) => tester
    .widget<FadeTransition>(
      find
          .descendant(of: appearance, matching: find.byType(FadeTransition))
          .first,
    )
    .opacity
    .value;

void _expectShakes(List<double> path, {String? reason}) {
  expect(path, hasLength(_shakeOffsets.length));
  for (var i = 0; i < _shakeOffsets.length; i++) {
    expect(
      path[i],
      closeTo(_shakeOffsets[i], 0.01),
      reason: '$reason at ${60 * (i + 1)} ms',
    );
  }
}

void _doesNotShake(List<double> path, {String? reason}) {
  expect(path, everyElement(closeTo(0, 0.01)), reason: reason);
}

/// How far [f] moved at 60, 120, 180, 240, 300 and 360 ms relative to its rest position.
Future<List<double>> _path(WidgetTester tester, Finder f) async {
  final positions = <double>[];
  for (var t = 0; t < 360; t += 60) {
    await tester.pump(_ms(60));
    positions.add(tester.getTopLeft(f).dx);
  }
  await tester.pumpAndSettle();
  final rest = tester.getTopLeft(f).dx;
  return [for (final x in positions) x - rest];
}
