import 'dart:async';

import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/bottom_bar.dart';
import 'package:clubnahuelmosse/common/skeleton.dart';
import 'package:clubnahuelmosse/common/sport_tile.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/booking_card.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_shortcut.dart';
import 'package:clubnahuelmosse/features/notifications/data/notifications_repository.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notice_card.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/features/session/domain/profile.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/features/users/presentation/profile_card.dart';
import 'package:clubnahuelmosse/features/users/presentation/profile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'my_bookings_test.dart' show bookingJson;
import 'notifications_test.dart'
    show FakeSystem, confirmationNotice, reminderNotice;
import 'support/admin.dart';
import 'support/held_api.dart';
import 'support/mount.dart';
import 'support/user.dart';

/// A profile whose read waits for [release]: «Mi perfil» stays loading.
class _HeldSession extends FakeSession {
  _HeldSession() : super(userProfile);

  final _gate = Completer<void>();

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<Profile> refresh() async {
    await _gate.future;
    return super.refresh();
  }
}

const _skeletonCard = ValueKey('skeleton-card');
const _skeletonTile = ValueKey('skeleton-tile');
const _skeletonShortcut = ValueKey('skeleton-shortcut');
const _skeletonHeader = ValueKey('skeleton-header');

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

/// Unmounts and lets the client's wait limit pass so that no Timer is left.
Future<void> _close(WidgetTester tester, HeldApi api) async {
  await tester.pumpWidget(const SizedBox());
  api.release();
  await tester.pump(const Duration(minutes: 2));
}

void main() {
  setUpAll(loadFonts);

  testWidgets(
    'the home loads with the shape of the next booking and the sports @VIS-03-S1',
    (tester) async {
      final api = HeldApi(_homeAnswers);
      await _open(tester, api, '/home');

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
      await _open(tester, api, '/notifications');

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

  testWidgets(
    '«Mi perfil» loads with a skeleton of its header and its data, not a spinner @VIS-03-S2',
    (tester) async {
      final api = HeldApi({});
      final session = _HeldSession();
      await _open(tester, api, '/profile', session: session);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(BottomBar), findsOneWidget);
      final header = tester.getRect(find.byKey(_skeletonHeader));
      final cards = [
        for (final e in find.byKey(_skeletonCard).evaluate())
          tester.getRect(find.byWidget(e.widget)),
      ];
      expect(cards, hasLength(3));

      session.release();
      await tester.pumpAndSettle();

      expect(find.byType(Skeleton), findsNothing);
      expectSameBox(
        header,
        tester.getRect(find.byType(ProfileHeader)),
        edge: 2,
      );
      final real = find.byType(ProfileCard);
      for (var i = 0; i < 3; i++) {
        expectSameBox(cards[i], tester.getRect(real.at(i)), edge: 2);
      }
    },
  );

  testWidgets(
    'the account skeletons shimmer, stop with reduce motion and say «Cargando» once @assumption:VIS-03-ASM-05 @VIS-03-ASM-05',
    (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      final screens = <(String, HeldApi, Session?)>[
        ('/home', HeldApi(_homeAnswers), null),
        (
          '/notifications',
          HeldApi(_noticeAnswers, held: {'GET /notifications'}),
          null,
        ),
        ('/profile', HeldApi({}), _HeldSession()),
      ];

      for (final (route, api, session) in screens) {
        await _open(tester, api, route, session: session);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.hasRunningAnimations, isTrue, reason: '$route shimmers');
        expect(
          find.bySemanticsLabel('Cargando'),
          findsOneWidget,
          reason: route,
        );
        await _close(tester, api);
      }

      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      for (final (route, api, session) in screens) {
        api.holdAgain();
        await _open(tester, api, route, session: session);
        await tester.pump(const Duration(seconds: 3));
        expect(find.byType(Skeleton), findsWidgets, reason: route);
        expect(tester.hasRunningAnimations, isFalse, reason: '$route still');
        expect(
          find.bySemanticsLabel('Cargando'),
          findsOneWidget,
          reason: route,
        );
        await _close(tester, api);
      }
    },
  );
}
