import 'package:clubnahuelmosse/common/bib.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues_screen.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/mount.dart';
import '../support/fixed_clock.dart';
import '../support/user.dart';

void main() {
  testWidgets(
    'the venue card counter is the bib over the photo, in the on-photo text color @RED-01-ASM-04 @RED-03-ASM-14',
    (tester) async {
      await mountUser(
        tester,
        api: apiRoutes(venueRoutes(venues: '[$venueMoronWithSports]')),
      );

      final bib = find.descendant(
        of: find.byType(VenueCard),
        matching: find.byType(GiantBib),
      );
      final counter = tester.widget<GiantBib>(bib);
      expect(counter.text, '02');
      expect(counter.color, Palette.dark.textOnMedia);
    },
  );
}
