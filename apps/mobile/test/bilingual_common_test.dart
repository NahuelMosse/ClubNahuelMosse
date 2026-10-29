import 'dart:convert';
import 'dart:ui';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/bottom_bar.dart';
import 'package:clubnahuelmosse/common/dates.dart';
import 'package:clubnahuelmosse/common/day_timeline.dart';
import 'package:clubnahuelmosse/common/error_dialog.dart';
import 'package:clubnahuelmosse/common/list_loading.dart';
import 'package:clubnahuelmosse/common/password_form.dart';
import 'package:clubnahuelmosse/common/profile_header.dart';
import 'package:clubnahuelmosse/common/selected_badge.dart';
import 'package:clubnahuelmosse/common/skeleton_zone.dart';
import 'package:clubnahuelmosse/common/top_bar.dart';
import 'package:clubnahuelmosse/features/notifications/data/notifications_repository.dart';
import 'package:clubnahuelmosse/features/notifications/domain/notification_system.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/bell_button.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notice_panel.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notifications_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/montar.dart';
import 'soporte/usuario.dart';

const _english = [Locale('en', 'US')];

/// 20:00 of the club on Thursday 12 November.
final _now = DateTime.utc(2026, 11, 12, 20);

String _notice(String id, DateTime club, {bool read = false}) =>
    '{"id": "$id", "tipo": "recordatorio", "titulo": "Your booking is in 1 hour", '
    '"cuerpo": "Football 5", "reserva_id": null, '
    '"creada_en": "${club.add(const Duration(hours: 3)).toIso8601String()}", '
    '"leida": $read}';

class _System implements NotificationSystem {
  _System({this.allowed = true});

  final bool allowed;

  @override
  String get platform => 'android';

  @override
  Future<bool> isAllowed() async => allowed;

  @override
  Future<bool> wasAsked() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<String?> token() async => 'token';

  @override
  Future<void> forgetToken() async {}

  @override
  Stream<void> get onArrive => const Stream.empty();

  @override
  Stream<NoticeTapped> get onTap => const Stream.empty();

  @override
  Future<NoticeTapped?> openedBy() async => null;
}

NotificationCenter _center(List<String> notices, {bool allowed = true}) {
  final session = SesionFalsa(perfilUsuario);
  final api = ApiClient(
    'http://api.falsa',
    cliente: MockClient((request) async {
      final (code, body) = switch ((request.method, request.url.path)) {
        ('GET', '/notificaciones') => (
          200,
          '{"notificaciones": [${notices.join(', ')}], "no_leidas": ${notices.length}}',
        ),
        ('GET', '/yo') => (200, perfilJson()),
        _ => (204, ''),
      };
      return http.Response.bytes(
        utf8.encode(body),
        code,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );
  return NotificationCenter(
    notifications: NotificationsRepository(api: api, session: session),
    session: session,
    system: _System(allowed: allowed),
    every: Duration.zero,
    now: () => DateTime.utc(2026, 11, 13),
  );
}

void main() {
  setUpAll(cargarFuentes);

  Future<void> mountEnglish(WidgetTester tester, Widget widget) async {
    tester.platformDispatcher.localesTestValue = _english;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await montar(tester, widget, tema: darkTheme);
  }

  group('notifications', () {
    testWidgets(
      'notifications, the bell and the notice panel show English @ENG-19-S1',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final center = _center([
          _notice('1', DateTime.utc(2026, 11, 12, 19, 58)),
          _notice('2', DateTime.utc(2026, 11, 12, 17), read: true),
          _notice('3', DateTime.utc(2026, 11, 11, 15), read: true),
        ]);
        await mountEnglish(
          tester,
          NotificationsScreen(
            center: center,
            session: SesionFalsa(perfilUsuario),
            now: () => _now,
            onOpen: (_, _) {},
          ),
        );

        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('TODAY'), findsOneWidget);
        expect(find.text('YESTERDAY'), findsOneWidget);
        expect(find.text('CLUBNAHUELMOSSE · 2 MIN AGO'), findsOneWidget);
        expect(find.text('CLUBNAHUELMOSSE · 3 H AGO'), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            'Your booking is in 1 hour. Football 5. 2 MIN AGO, unread',
          ),
          findsOneWidget,
        );
        expect(find.text('HOY'), findsNothing);

        final empty = _center([]);
        await mountEnglish(
          tester,
          NotificationsScreen(
            center: empty,
            session: SesionFalsa(perfilUsuario),
            now: () => _now,
            onOpen: (_, _) {},
          ),
        );
        expect(find.text('No notifications yet'), findsOneWidget);
        expect(
          find.text('Here you will see the reminders for your bookings.'),
          findsOneWidget,
        );

        final off = _center([], allowed: false);
        await mountEnglish(
          tester,
          NotificationsScreen(
            center: off,
            session: SesionFalsa(perfilUsuario),
            now: () => _now,
            onOpen: (_, _) {},
          ),
        );
        expect(find.text('Notifications are off'), findsOneWidget);
        expect(
          find.text(
            'Turn on notices so we can remind you about your bookings an hour before.',
          ),
          findsOneWidget,
        );
        expect(find.text('TURN ON NOTIFICATIONS'), findsOneWidget);

        final bell = _center([_notice('1', DateTime.utc(2026, 11, 12, 19))]);
        await mountEnglish(tester, NotificationsButton(center: bell));
        expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
        await tester.runAsync(bell.load);
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel('Notifications, 1 unread'),
          findsOneWidget,
        );

        final arriving = <String>[];
        final panelCenter = _center(arriving);
        await mountEnglish(
          tester,
          NoticePanel(center: panelCenter, now: () => _now, onOpen: (_) {}),
        );
        arriving.add(_notice('9', DateTime.utc(2026, 11, 12, 19, 58)));
        await tester.runAsync(panelCenter.load);
        await tester.pumpAndSettle();
        expect(find.text('NOTIFICATIONS'), findsOneWidget);
        expect(find.text('MARK ALL READ'), findsOneWidget);
        expect(find.bySemanticsLabel('Close notifications'), findsOneWidget);
        semantics.dispose();
      },
    );
  });

  group('common', () {
    Future<void> open(
      WidgetTester tester,
      Future<void> Function(BuildContext) f,
    ) async {
      await mountEnglish(
        tester,
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => f(context),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    }

    Future<void> close(WidgetTester tester) async {
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'shared errors, offline and validation messages show English @ENG-19-S1',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final errors = <(Object, String, String, String, String)>[
          (
            const SinConexion(),
            'Connection error',
            'We could not connect. Check your internet connection and try again.',
            'RETRY',
            'Back',
          ),
          (
            const ServidorSinRespuesta(),
            'Server error',
            'The server is not responding. Try again in a few minutes.',
            'OK',
            '',
          ),
          (
            const ErrorDelServidor(500),
            'Server error',
            'We could not process the operation right now. Try again later.',
            'OK',
            '',
          ),
        ];
        for (final (error, title, text, primary, secondary) in errors) {
          await open(tester, (context) => showNetworkError(context, error));
          expect(find.text(title), findsOneWidget);
          expect(find.text(text), findsOneWidget);
          expect(find.text(primary), findsOneWidget);
          if (secondary.isNotEmpty)
            expect(find.text(secondary), findsOneWidget);
          await tester.tap(find.byType(TextButton).last);
          await tester.pumpAndSettle();
        }

        final notices = <(Future<void> Function(BuildContext), List<String>)>[
          (
            (c) => showTimeSlotTaken(c, 'x'),
            ['That time slot was taken', 'CHOOSE ANOTHER TIME'],
          ),
          (
            (c) => showTimeSlotRejected(c, 'x'),
            ['We could not confirm the time slot', 'CHOOSE ANOTHER TIME'],
          ),
          (
            (c) => confirmNewSchedule(c, 'x'),
            ['Save the new schedule?', 'SAVE ANYWAY', 'REVIEW THE SCHEDULE'],
          ),
          (
            showBookingCanceled,
            [
              'Booking canceled',
              'The time slot was freed and the booking moved to your history.',
              'OK',
            ],
          ),
          (
            showBookingVoided,
            [
              'Booking voided',
              'The time slot was freed and the booking moved to the voided ones.',
              'OK',
            ],
          ),
          (
            showChangedMeanwhile,
            [
              'This changed in the meantime',
              'Someone else changed this data while you were viewing it. We updated it so you see the current state.',
              'SEE THE UPDATE',
            ],
          ),
          (
            showSessionExpired,
            [
              'Your session expired',
              'For security we signed you out. Sign in again to continue.',
              'GO TO SIGN IN',
            ],
          ),
        ];
        for (final (show, texts) in notices) {
          await open(tester, show);
          for (final text in texts) {
            expect(find.text(text), findsOneWidget, reason: text);
          }
          await close(tester);
        }

        await mountEnglish(tester, ListRetry(onTap: () {}));
        expect(find.text('RETRY'), findsOneWidget);

        await mountEnglish(
          tester,
          const DayTimeline(
            slots: [SlotState.free, SlotState.taken, SlotState.chosen],
          ),
        );
        for (final text in [
          'YOUR DAY ON THE COURT',
          'Free',
          'Taken',
          'Chosen',
        ]) {
          expect(find.text(text), findsOneWidget, reason: text);
        }
        expect(find.bySemanticsLabel('08 h free'), findsOneWidget);
        expect(find.bySemanticsLabel('10 h chosen'), findsOneWidget);

        await mountEnglish(
          tester,
          const Scaffold(bottomNavigationBar: BottomBar(current: Section.home)),
        );
        for (final text in ['HOME', 'VENUES', 'BOOKINGS', 'PROFILE']) {
          expect(find.text(text), findsOneWidget, reason: text);
        }
        await mountEnglish(
          tester,
          const Scaffold(
            bottomNavigationBar: AdminBar(current: AdminSection.venues),
          ),
        );
        for (final text in ['BOOKINGS', 'VENUES', 'SPACES']) {
          expect(find.text(text), findsOneWidget, reason: text);
        }

        await mountEnglish(tester, const Scaffold(appBar: TopBar(title: 't')));
        expect(find.byTooltip('Back'), findsOneWidget);
        expect(find.bySemanticsLabel('Back'), findsOneWidget);

        await mountEnglish(
          tester,
          PasswordUpdated(primary: 'x', onPrimaryTap: () {}),
        );
        expect(find.text('Password updated'), findsOneWidget);
        expect(
          find.text(
            'Your password was changed. Use it the next time you sign in.',
          ),
          findsOneWidget,
        );
        await mountEnglish(
          tester,
          PasswordFormTemplate(
            bar: const TopBar(title: 't'),
            title: 'x',
            explanation: 'y',
            fields: const [],
            submitting: false,
            onSave: () {},
          ),
        );
        expect(find.text('SAVE PASSWORD'), findsOneWidget);

        await mountEnglish(tester, const Scaffold(body: ProfileHeader()));
        expect(find.text('MEMBER CARD'), findsOneWidget);
        await mountEnglish(tester, const Scaffold(body: SelectedBadge()));
        expect(find.text('SELECTED'), findsOneWidget);
        await mountEnglish(
          tester,
          const Scaffold(body: SkeletonZone(child: SizedBox(height: 10))),
        );
        expect(find.bySemanticsLabel('Loading'), findsOneWidget);

        expect(duration(1), '1 hour');
        expect(duration(3), '3 hours');
        semantics.dispose();
      },
    );
  });
}
