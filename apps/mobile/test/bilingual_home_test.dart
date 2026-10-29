import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

const _english = [Locale('en', 'US')];

void main() {
  setUpAll(cargarFuentes);

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('the home shows English @ENG-19-S1', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.platformDispatcher.localesTestValue = _english;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await montar(
      tester,
      inicioFalso(SesionFalsa(perfilUsuario)),
      tema: darkTheme,
    );
    expect(
      find.textContaining(RegExp(r'^GOOD (MORNING|AFTERNOON|EVENING),$')),
      findsOneWidget,
    );
    expect(find.text('BOOK YOUR COURT'), findsOneWidget);
    // The venues marker and the venues tab of the bottom bar read the same.
    expect(find.text('VENUES'), findsNWidgets(2));
    for (final label in ['COURTS', 'UPCOMING']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await tap(tester, find.bySemanticsLabel('Your account'));
    expect(find.text('Full profile'), findsOneWidget);
    expect(find.text('My bookings'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    await tester.tapAt(const Offset(10, 600));
    await tester.pumpAndSettle();
    expect(find.text('YOUR NEXT BOOKING'), findsOneWidget);
    expect(find.text('VIEW ALL →'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Find a court'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('QUICK ACCESS'), findsOneWidget);
    expect(find.text('By venue, date and time'), findsOneWidget);
    expect(find.text('View venues'), findsOneWidget);
    expect(find.text('Hours and courts of each one'), findsOneWidget);

    semantics.dispose();
  });
}
