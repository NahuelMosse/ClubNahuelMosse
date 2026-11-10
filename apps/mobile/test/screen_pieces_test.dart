import 'dart:io';

import 'package:clubnahuelmosse/common/booking_card.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mount.dart';

/// The code of a `lib/` file, without comments.
String _code(String path) => File(
  'lib/$path',
).readAsLinesSync().where((l) => !l.trimLeft().startsWith('//')).join('\n');

/// A screen and the pieces of its folder that it imports, directly or indirectly.
Map<String, String> _withPieces(String screen) {
  final folder = screen.substring(0, screen.lastIndexOf('/'));
  final folderImport = RegExp(r"^import '([a-z_]+/.dart)'", multiLine: true);
  final seen = <String, String>{};
  final pending = [screen];
  while (pending.isNotEmpty) {
    final path = pending.removeLast();
    if (seen.containsKey(path)) continue;
    final code = _code(path);
    seen[path] = code;
    for (final m in folderImport.allMatches(code)) {
      pending.add('$folder/${m.group(1)}');
    }
  }
  return seen;
}

String _all(String screen) => _withPieces(screen).values.join('\n');

/// What sits over a photo does not read the palette in a fixed mode nor hand-written grays.
void _noFixedTones(String screen) {
  _withPieces(screen).forEach((path, code) {
    expect(code, isNot(contains('Paleta.oscura')), reason: path);
    expect(code, isNot(contains('Paleta.clara')), reason: path);
    expect(code, isNot(contains('0xFFD4D4D8')), reason: path);
  });
}

void _accentOverPhoto(String screen) {
  _noFixedTones(screen);
  expect(_all(screen), contains('accentOnMedia'), reason: screen);
}

void main() {
  setUpAll(loadFonts);

  test(
    'the home overline uses accentOnMedia in the screen or its pieces @RED-01-S2 @ARQ-03-S3',
    () => _accentOverPhoto('features/home/presentation/home_screen.dart'),
  );

  test(
    'the venue overline uses accentOnMedia in the screen or its pieces @RED-01-S2 @ARQ-03-S3',
    () => _accentOverPhoto('features/venues/presentation/venue_screen.dart'),
  );

  test(
    'the confirm booking overline uses accentOnMedia in the screen or its pieces @RED-01-S2 @ARQ-03-S3',
    () => _accentOverPhoto(
      'features/bookings/presentation/confirm_booking_screen.dart',
    ),
  );

  test(
    'the availability overline uses accentOnMedia in the screen or its pieces @RED-01-S2 @ARQ-03-S3',
    () => _accentOverPhoto(
      'features/bookings/presentation/availability_screen.dart',
    ),
  );

  test(
    'the login accent uses accentOnMedia in the screen or its pieces @RED-01-S2 @ARQ-03-S3',
    () => _accentOverPhoto('features/session/presentation/login_screen.dart'),
  );

  test(
    'the text over a photo on each screen and its pieces comes from the on-media tokens @RED-01-S3 @ARQ-03-S3',
    () {
      for (final screen in [
        'features/home/presentation/home_screen.dart',
        'features/venues/presentation/venue_screen.dart',
        'features/venues/presentation/venues_screen.dart',
        'features/bookings/presentation/confirm_booking_screen.dart',
        'features/bookings/presentation/availability_screen.dart',
        'features/session/presentation/login_screen.dart',
      ]) {
        _noFixedTones(screen);
        expect(_all(screen), contains('textOnMedia'), reason: screen);
      }
    },
  );

  test(
    'the profile header goes from bgHeroFrom to bgHeroTo @RED-01-S5 @ARQ-03-S3',
    () {
      expect(
        _all('features/users/presentation/my_profile_screen.dart'),
        contains('[p.bgHeroFrom, p.bgHeroTo]'),
      );
    },
  );

  testWidgets(
    'the admin panel and «Mis reservas» show the booking with the same card @REV-06-S5 @assumption:REV-06-ASM-04 @ARQ-03-S3',
    (tester) async {
      await mountScreen(
        tester,
        const BookingDateAndTime(
          date: 'sábado 7 de junio',
          time: '18:00 – 19:00',
        ),
        theme: darkTheme,
      );
      expect(find.text('sábado 7 de junio'), findsOneWidget);
      expect(find.text('18:00 – 19:00'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);

      for (final screen in [
        'features/admin/presentation/admin_panel_screen.dart',
        'features/bookings/presentation/my_bookings_screen.dart',
      ]) {
        final code = _all(screen);
        expect(code, contains('common/booking_card.dart'), reason: screen);
        expect(code, contains('BookingDateAndTime('), reason: screen);
        expect(code, isNot(contains('Icons.schedule_rounded')), reason: screen);
      }
    },
  );

  test(
    'only the simulated notifications token uses DateTime.now and my profile validates the birth date with the club clock @ARQ-03-ASM-04 @ARQ-03-S3',
    () {
      final withClock = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().contains('DateTime.now()'))
          .map((f) => f.path.replaceAll('\\', '/').substring('lib/'.length))
          .toSet();
      expect(withClock, {
        'features/notifications/data/simulated_notification_system.dart',
      });

      final profile = _withPieces(
        'features/users/presentation/my_profile_screen.dart',
      );
      expect(profile.values.join('\n'), contains('clubNow'));
      for (final MapEntry(:key, :value) in profile.entries) {
        expect(value, isNot(contains('DateTime.now()')), reason: key);
      }
    },
  );
}
