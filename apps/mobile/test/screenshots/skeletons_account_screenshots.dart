import 'dart:async';

import 'package:clubnahuelmosse/features/notifications/data/notifications_repository.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/features/session/domain/profile.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../my_bookings_test.dart' show bookingJson;
import '../notifications_spanish_test.dart'
    show FakeSystem, confirmationNotice, reminderNotice;
import '../support/admin.dart';
import '../support/held_api.dart';
import '../support/mount.dart';
import '../support/skeleton_capture.dart';
import '../support/user.dart';

/// A profile whose read waits for [release]: My profile stays loading.
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

/// Asserts nothing: it produces each loading state of the account screens next to the same
/// screen loaded, dark, 393x852.
void main() {
  Future<void> mount(
    WidgetTester tester,
    HeldApi api,
    String route, {
    Session? session,
  }) async {
    final current = session ?? FakeSession(userProfile);
    await mountApp(
      tester,
      api: api.client,
      session: current,
      route: route,
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
    );
  }

  Future<void> capture(WidgetTester tester, String file) async {
    await tester.pump();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
  }

  testWidgets('home loading and loaded', (tester) async {
    final api = HeldApi(_homeAnswers);
    await mount(tester, api, '/home');
    await capture(tester, 'skeletons/home_loading.png');
    api.release();
    await tester.pumpAndSettle();
    await capture(tester, 'skeletons/home_loaded.png');
    await drainApp(tester);
  });

  testWidgets('notifications loading and loaded', (tester) async {
    final api = HeldApi(_noticeAnswers, held: {'GET /notifications'});
    await mount(tester, api, '/notifications');
    await capture(tester, 'skeletons/notifications_loading.png');
    api.release();
    await tester.pumpAndSettle();
    await capture(tester, 'skeletons/notifications_loaded.png');
    await drainApp(tester);
  });

  testWidgets('profile loading and loaded', (tester) async {
    final api = HeldApi({});
    final session = _HeldSession();
    await mount(tester, api, '/profile', session: session);
    await capture(tester, 'skeletons/profile_loading.png');
    session.release();
    await tester.pumpAndSettle();
    await capture(tester, 'skeletons/profile_loaded.png');
    await drainApp(tester);
  });
}
