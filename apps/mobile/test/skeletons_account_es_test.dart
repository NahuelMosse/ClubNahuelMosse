import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/skeleton.dart';
import 'package:clubnahuelmosse/common/sport_tile.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/booking_card.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_shortcut.dart';
import 'package:clubnahuelmosse/features/notifications/data/notifications_repository.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notice_card.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'my_bookings_test.dart' show bookingJson;
import 'notifications_spanish_test.dart'
    show FakeSystem, confirmationNotice, reminderNotice;
import 'support/admin.dart';
import 'support/held_api.dart';
import 'support/mount.dart';
import 'support/user.dart';

const _skeletonCard = ValueKey('skeleton-card');
const _skeletonTile = ValueKey('skeleton-tile');
const _skeletonShortcut = ValueKey('skeleton-shortcut');

final _homeAnswers = {
  'GET /bookings': (200, '{"bookings": [${bookingJson()}]}'),
  'GET /spaces/catalog': (200, catalogJson),
  'GET /venues': (200, '{"venues": [$venueMoronWithSports]}'),
};

final _noticeAnswers = {
  'GET /notifications': (
    200,
    '{"notifications": [$reminderNotice, $confirmationNotice], "unread": 1}',
  ),
};

/// Mounts the app at [route] with the API of [api] and leaves it loading: the shimmer runs
/// non-stop, so it does not wait for it to settle.
Future<void> _open(
  WidgetTester tester,
  HeldApi api,
  String route, {
  Session? session,
}) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final current = session ?? FakeSession(userProfile);
  await tester.pumpWidget(
    App(
      api: api.client,
      session: current,
      appearance: Appearance.inMemory(dark: true),
      notificationCenter: NotificationCenter(
        notifications: NotificationsRepository(
          api: api.client,
          session: current,
        ),
        session: current,
        system: FakeSystem(),
        every: Duration.zero,
        now: () => DateTime.utc(2026, 11, 13),
      ),
      initialLocation: route,
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(loadFonts);

  testWidgets(
    'the home loads with the shape of the next booking and the sports @VIS-03-S1',
    (tester) async {
      final api = HeldApi(_homeAnswers);
      await _open(tester, api, '/inicio');

      final card = tester.getRect(find.byKey(_skeletonCard));
      final tile = tester.getRect(find.byKey(_skeletonTile).first);
      final shortcut = tester.getRect(find.byKey(_skeletonShortcut).first);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      api.release();
      await tester.pumpAndSettle();

      expect(find.byType(Skeleton), findsNothing);
      expectSameBox(card, tester.getRect(find.byType(BookingCard)), edge: 2);
      expectSameBox(
        tile,
        tester.getRect(find.byType(SportTile).first),
        edge: 2,
      );
      expectSameBox(
        shortcut,
        tester.getRect(find.byType(HomeShortcut).first),
        edge: 2,
      );
    },
  );

  testWidgets(
    '«Notificaciones» loads with the shape of the notice card @VIS-03-S1',
    (tester) async {
      final api = HeldApi(_noticeAnswers, held: {'GET /notifications'});
      await _open(tester, api, '/notificaciones');

      final frames = tester.widgetList(find.byKey(_skeletonCard)).length;
      final first = tester.getRect(find.byKey(_skeletonCard).first);
      final last = tester.getRect(find.byKey(_skeletonCard).last);
      expect(frames, greaterThan(3));
      expect(
        last.bottom,
        greaterThanOrEqualTo(852),
        reason: 'the cards fill the screen',
      );

      api.release();
      await tester.pumpAndSettle();

      expect(find.byType(Skeleton), findsNothing);
      expectSameBox(
        first,
        tester.getRect(find.byType(NoticeCard).first),
        edge: 2,
      );
    },
  );
}
