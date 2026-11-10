import 'package:clubnahuelmosse/features/session/presentation/account_card.dart';
import 'dart:io';

import 'package:clubnahuelmosse/common/dates.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mount.dart';

Map<String, String> _lib() => {
  for (final file in Directory(
    'lib',
  ).listSync(recursive: true).whereType<File>())
    if (file.path.endsWith('.dart'))
      file.path.replaceAll(r'\', '/').substring(4): file.readAsStringSync(),
};

Set<String> _filesContaining(Pattern pattern) => {
  for (final MapEntry(key: path, value: text) in _lib().entries)
    if (text.contains(pattern)) path,
};

/// A session that Firebase cannot close.
class _SessionThatWontClose extends FakeSession {
  _SessionThatWontClose() : super(userProfile);

  @override
  Future<void> close() async => throw Exception('Firebase did not respond');
}

void main() {
  test(
    'only load_failure.dart, the sign-out and the screens without a session report the expired session and the network error @ARQ-03-S2 @ARQ-03-ASM-02',
    () {
      final calls = RegExp(r'show(SessionExpired|NetworkError)\(context');
      expect(_filesContaining(calls), {
        'features/session/presentation/load_failure.dart',
        'features/session/presentation/account_card.dart',
        'features/users/presentation/registration_screen.dart',
        'features/session/presentation/forgot_password_screen.dart',
      });
    },
  );

  testWidgets(
    'if Firebase cannot close the session, the person stays in and sees the server error @ARQ-03-ASM-05',
    (tester) async {
      final session = _SessionThatWontClose();
      await mountScreen(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => signOut(context, session),
              child: const Text('Cerrar sesión'),
            ),
          ),
        ),
        theme: darkTheme,
      );

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Error del servidor'), findsOneWidget);
      expect(session.profile, isNotNull);
    },
  );

  test(
    'my profile closes the expired session even when it is no longer on screen @ARQ-03-ASM-05',
    () {
      final profile =
          _lib()['features/users/presentation/my_profile_screen.dart']!;
      expect(
        profile,
        matches(RegExp(r'if \(!mounted\) \{[\s\S]{0,400}?session\.close\(\)')),
      );
    },
  );

  test(
    'every «pantalla_*.dart» declares only its widget and its State; its pieces go to files in the folder @ARQ-03-S3 @ARQ-03-ASM-06',
    () {
      final withPieces = {
        for (final MapEntry(key: path, value: text) in _lib().entries)
          if (path.split('/').last.startsWith('pantalla_') &&
              RegExp(r'^class ', multiLine: true).allMatches(text).length > 2)
            path,
      };
      expect(withPieces, isEmpty);
    },
  );

  test(
    'days and months come from intl in Spanish, with today\'s capitalization @ARQ-03-S1 @ARQ-03-ASM-07',
    () {
      expect(_filesContaining(RegExp("'[Mm]iércoles'")), isEmpty);
      expect(_filesContaining(RegExp("'[Nn]oviembre'")), isEmpty);
      final thursday = DateTime(2026, 11, 12);
      expect(shortDay(thursday), 'Jue 12');
      expect(longDate(thursday), 'Jue 12 de noviembre');
      expect(weekdayName(DateTime(2026, 11, 11)), 'Miércoles');
      expect(weekdayAbbreviation(DateTime(2026, 11, 14)), 'SÁB');
      expect(shortTime(DateTime(2026, 11, 12, 9, 5)), '09:05');
      expect(isoDate(thursday), '2026-11-12');
    },
  );

  test(
    'the DNI is grouped with intl and one that is not a number is shown as it arrives @ARQ-03-ASM-07',
    () {
      expect(readableDni('30111222'), '30.111.222');
      expect(readableDni('X12'), 'X12');
      expect(readableDni(''), '');
    },
  );

  test(
    'only the simulated notifications token uses DateTime.now @ARQ-03-ASM-04',
    () {
      expect(_filesContaining('DateTime.now()'), {
        'features/notifications/data/simulated_notification_system.dart',
      });
      expect(
        _lib()['features/users/presentation/my_profile_screen.dart'],
        contains('clubNow'),
      );
    },
  );

  test(
    'the five chips use SelectableChip, each in-progress indicator uses InProgress and the per-field errors are read in a single place @ARQ-03-S2 @ARQ-03-ASM-03',
    () {
      expect(
        _filesContaining('SelectableChip(').length,
        greaterThanOrEqualTo(6),
      );
      expect(_filesContaining('InProgress(').length, greaterThanOrEqualTo(6));
      expect(_filesContaining("'errors'"), {'common/field_errors.dart'});
      expect(_filesContaining('class _Elegible '), isEmpty);
    },
  );

  test(
    'the successful registration keeps its pulse and its spacing @ARQ-03-ASM-08',
    () {
      final registration =
          _lib()['features/users/presentation/registration_done_screen.dart']!;
      expect(registration, contains('ResultScreen('));
      for (final measure in ['100', '44', '20', '36']) {
        expect(registration, contains(measure), reason: measure);
      }
    },
  );
}
