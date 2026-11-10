import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The code of a `lib/` file, without comments.
String _code(String route) => File(
  'lib/$route',
).readAsLinesSync().where((l) => !l.trimLeft().startsWith('//')).join('\n');

/// What goes over a photo does not read the palette of a fixed mode nor hand-written grays.
void _noFixedTones(String route) {
  final code = _code(route);
  expect(code, isNot(contains('Paleta.oscura')), reason: route);
  expect(code, isNot(contains('Paleta.clara')), reason: route);
  expect(code, isNot(contains('0xFFD4D4D8')), reason: route);
}

void _accentOverPhoto(String route) {
  _noFixedTones(route);
  expect(_code(route), contains('accentOnMedia'), reason: route);
}

void main() {
  test('the button over a photo uses accentOnMedia @RED-01-S2', () {
    _accentOverPhoto('common/button.dart');
  });

  test('the home overline uses accentOnMedia @RED-01-S2', () {
    _accentOverPhoto('features/home/presentation/home_screen.dart');
  });

  test('the venue overline uses accentOnMedia @RED-01-S2', () {
    _accentOverPhoto('features/venues/presentation/venue_screen.dart');
  });

  test('the confirm booking overline uses accentOnMedia @RED-01-S2', () {
    _accentOverPhoto(
      'features/bookings/presentation/confirm_booking_screen.dart',
    );
  });

  test('the schedule overline uses accentOnMedia @RED-01-S2', () {
    _accentOverPhoto('features/bookings/presentation/availability_screen.dart');
  });

  test('the login accent uses accentOnMedia @RED-01-S2', () {
    _accentOverPhoto('features/session/presentation/login_screen.dart');
  });

  test(
    'the on-photo text of each screen comes from the on-media tokens @RED-01-S3',
    () {
      for (final route in [
        'features/home/presentation/home_screen.dart',
        'features/venues/presentation/venue_screen.dart',
        'features/venues/presentation/venues_screen.dart',
        'features/bookings/presentation/confirm_booking_screen.dart',
        'features/bookings/presentation/availability_screen.dart',
        'features/session/presentation/login_screen.dart',
      ]) {
        _noFixedTones(route);
        expect(_code(route), contains('textOnMedia'), reason: route);
      }
    },
  );

  test('the filled danger button uses stateDangerStrong @RED-01-S4', () {
    final code = _code('common/button.dart');
    expect(code, contains('backgroundColor: p.stateDangerStrong'));
  });

  test(
    'the on-photo label, like «Fútbol 5», is violet with white text @RED-01-ASM-03',
    () {
      _noFixedTones('common/label.dart');
      expect(
        _code('common/label.dart'),
        contains('(p.accentBase, p.accentOn)'),
      );
    },
  );

  test('the venue card counter is violet with a white figure @RED-01-ASM-04', () {
    final code = _code('features/venues/presentation/venues_screen.dart');
    _noFixedTones('features/venues/presentation/venues_screen.dart');
    final counter = RegExp(
      r"color: p\.accentBase,[\s\S]{0,400}?'\$\{sede\.canchas\}',\s*style: Textos\.\w+\.copyWith\(color: p\.accentOn\)",
    );
    expect(counter.hasMatch(code), isTrue);
  });

  test('the profile header goes from bgHeroFrom to bgHeroTo @RED-01-S5', () {
    expect(
      _code('features/users/presentation/my_profile_screen.dart'),
      contains('[p.bgHeroFrom, p.bgHeroTo]'),
    );
  });
}
