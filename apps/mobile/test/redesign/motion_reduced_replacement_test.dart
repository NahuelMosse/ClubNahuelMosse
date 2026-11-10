import 'package:clubnahuelmosse/features/bookings/data/booking_json.dart';
import 'dart:convert';

import 'package:clubnahuelmosse/common/motion.dart';
import 'package:clubnahuelmosse/common/sport_tile.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/booking_confirmed_screen.dart';
import 'package:clubnahuelmosse/features/bookings/domain/booking.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../my_bookings_test.dart' show bookingJson;
import '../notifications_test.dart'
    show FakeApi, noticesNow, centerOf, reminderNotice;
import '../support/mount.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notice_panel.dart';

final _one = closeTo(1, 1e-6);

Future<void> _mountFree(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: darkTheme,
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: screen,
    ),
  );
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> _until(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 20 && !condition(); i++) {
    await tester.pump();
  }
  expect(condition(), isTrue);
}

double _opacity(WidgetTester tester, Finder appearance) => tester
    .widget<FadeTransition>(
      find
          .descendant(of: appearance, matching: find.byType(FadeTransition))
          .first,
    )
    .opacity
    .value;

double _visibility(WidgetTester tester, Finder f) {
  if (f.evaluate().isEmpty) return 0;
  var visible = 1.0;
  for (final fade in tester.widgetList<FadeTransition>(
    find.ancestor(of: f, matching: find.byType(FadeTransition)),
  )) {
    visible *= fade.opacity.value;
  }
  return visible;
}

bool _allAtEnd(WidgetTester tester) {
  final count = find.byType(FadeIn).evaluate().length;
  return count > 0 &&
      [
        for (var i = 0; i < count; i++)
          _opacity(tester, find.byType(FadeIn).at(i)),
      ].every((o) => o == 1);
}

double _width(WidgetTester tester, Finder f) =>
    tester.getBottomRight(f).dx - tester.getTopLeft(f).dx;

Booking _confirmedBooking() {
  final booking = bookingFromJson(jsonDecode(bookingJson()));
  if (booking == null) fail('the test booking cannot be read');
  return booking;
}

void main() {
  setUpAll(loadFonts);

  testWidgets(
    'with reduce motion the celebration, the notice and the entrance show their end state on the first frame @RED-04-S14',
    (tester) async {
      _reduceMotion(tester);

      // The celebration.
      await _mountFree(
        tester,
        BookingConfirmedScreen(booking: _confirmedBooking()),
      );
      final title = find.text('¡Reserva confirmada!');
      final receipt = find.text('Horario');
      expect(find.byType(Celebration), findsOneWidget);
      final width = _width(tester, title);
      expect(_visibility(tester, receipt), _one);
      // The first mount of MaterialApp always leaves the frame of its initial route scheduled.
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpAndSettle();
      expect(_width(tester, title), closeTo(width, 1e-6));
      await _unmount(tester);

      // The in-app notice.
      final api = FakeApi();
      final session = FakeSession(userProfile);
      final center = centerOf(api, session);
      await _mountFree(
        tester,
        Stack(
          children: [
            const Scaffold(body: Center(child: Text('la pantalla de abajo'))),
            NoticePanel(center: center, now: () => noticesNow, onOpen: (_) {}),
          ],
        ),
      );
      api
        ..notices = [reminderNotice]
        ..unread = 1;
      await tester.runAsync(center.load);
      await tester.pump();
      await tester.pump();
      final notice = find.text('NOTIFICACIONES');
      expect(notice, findsOneWidget);
      final top = tester.getTopLeft(notice).dy;
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(notice).dy, closeTo(top, 1e-6));
      await _unmount(tester);

      // The staggered entrance of the home screen.
      await _mountFree(tester, fakeHome(FakeSession(userProfile)));
      await _until(tester, () => find.byType(SportTile).evaluate().isNotEmpty);
      expect(_allAtEnd(tester), isTrue);
    },
  );
}
