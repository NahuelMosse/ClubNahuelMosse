import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/bookings/data/booking_json.dart';
import 'dart:async';
import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/common/club_timezone.dart';
import 'package:clubnahuelmosse/common/skeleton.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_greeting.dart';
import 'package:clubnahuelmosse/common/text_field.dart';
import 'package:clubnahuelmosse/common/member_profile.dart';
import 'package:clubnahuelmosse/common/logo_mark.dart';
import 'package:clubnahuelmosse/common/day_timeline.dart';
import 'package:clubnahuelmosse/common/marker.dart';
import 'package:clubnahuelmosse/common/motion.dart';
import 'package:clubnahuelmosse/common/pending_booking.dart';
import 'package:clubnahuelmosse/common/result.dart';
import 'package:clubnahuelmosse/common/selector.dart';
import 'package:clubnahuelmosse/common/snackbar.dart';
import 'package:clubnahuelmosse/common/sport_tile.dart';
import 'package:clubnahuelmosse/common/error_dialog.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/cancel_confirmation.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/booking_confirmed_screen.dart';
import 'package:clubnahuelmosse/features/bookings/domain/booking.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../my_bookings_test.dart' show bookingJson;
import '../notifications_test.dart'
    show FakeApi, noticesNow, centerOf, reminderNotice;
import '../support/admin.dart';
import '../support/mount.dart';
import '../support/user.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notice_panel.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/features/session/presentation/account_card.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/features/users/presentation/my_profile_screen.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_done_screen.dart';

Duration _ms(int n) => Duration(milliseconds: n);

final _zero = closeTo(0, 1e-6);
final _one = closeTo(1, 1e-6);

/// What the shake displaces at 60, 120, 180, 240, 300 and 360 ms.
const _shakeOffsets = [-9.0, 9.0, -6.0, 6.0, -3.0, 0.0];

/// The screen with the app's theme and language, without waiting for any animation to finish.
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

/// Pumps frames without advancing the clock, so that whatever was triggered starts.
Future<void> _start(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump();
  }
}

/// Pumps frames without advancing the clock until [condition] holds.
Future<void> _until(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 20 && !condition(); i++) {
    await tester.pump();
  }
  expect(condition(), isTrue);
}

/// The `FadeIn`s that wrap [f], from the closest to the farthest.
List<FadeIn> _appearances(WidgetTester tester, Finder f) => tester
    .widgetList<FadeIn>(find.ancestor(of: f, matching: find.byType(FadeIn)))
    .toList();

/// The `FadeIn` that wraps [f] and satisfies [matches].
Finder _appearanceWhere(Finder f, bool Function(FadeIn) matches) =>
    find.ancestor(
      of: f,
      matching: find.byWidgetPredicate((w) => w is FadeIn && matches(w)),
    );

double _opacity(WidgetTester tester, Finder appearance) => tester
    .widget<FadeTransition>(
      find
          .descendant(of: appearance, matching: find.byType(FadeTransition))
          .first,
    )
    .opacity
    .value;

/// How much of [f] is visible: the product of all the opacities that wrap it.
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

/// The visible width of [f], with the scale of whatever wraps it.
double _width(WidgetTester tester, Finder f) =>
    tester.getBottomRight(f).dx - tester.getTopLeft(f).dx;

/// How far [f] moved at 60, 120, 180, 240, 300 and 360 ms relative to its rest position.
Future<List<double>> _path(WidgetTester tester, Finder f) async {
  final positions = <double>[];
  for (var t = 0; t < 360; t += 60) {
    await tester.pump(_ms(60));
    positions.add(tester.getTopLeft(f).dx);
  }
  await tester.pumpAndSettle();
  final rest = tester.getTopLeft(f).dx;
  return [for (final x in positions) x - rest];
}

void _expectShakes(List<double> path, {String? reason}) {
  expect(path, hasLength(_shakeOffsets.length));
  for (var i = 0; i < _shakeOffsets.length; i++) {
    expect(
      path[i],
      closeTo(_shakeOffsets[i], 0.01),
      reason: '$reason at ${60 * (i + 1)} ms',
    );
  }
}

void _doesNotShake(List<double> path, {String? reason}) {
  expect(path, everyElement(closeTo(0, 0.01)), reason: reason);
}

Iterable<Shake> _shakes(WidgetTester tester, Finder f) => [
  ...tester.widgetList<Shake>(
    find.descendant(of: f, matching: find.byType(Shake)),
  ),
  ...tester.widgetList<Shake>(
    find.ancestor(of: f, matching: find.byType(Shake)),
  ),
];

/// The radius of the clip that reveals the icon of [inside].
double _clipRadius(WidgetTester tester, Finder inside) {
  final clips = find.descendant(
    of: inside,
    matching: find.byWidgetPredicate((w) => w is ClipOval || w is ClipPath),
  );
  expect(clips, findsWidgets);
  final object = tester.renderObject(clips.first);
  if (object is RenderClipPath) {
    final clipper = object.clipper;
    if (clipper == null) fail('the clip has no clipper of its own');
    return clipper.getClip(object.size).getBounds().width / 2;
  }
  if (object is RenderClipOval) {
    final clipper = object.clipper;
    if (clipper == null) fail('the clip has no clipper of its own');
    return clipper.getClip(object.size).width / 2;
  }
  fail('the clip is neither a ClipPath nor a ClipOval');
}

double _pulseScale(WidgetTester tester) => tester
    .widget<ScaleTransition>(
      find
          .descendant(
            of: find.byType(SuccessPulse),
            matching: find.byType(ScaleTransition),
          )
          .first,
    )
    .scale
    .value;

/// The 150 ms `AnimatedSwitcher` that changes only the list.
Finder get _listFade => find.byWidgetPredicate(
  (w) =>
      w is AnimatedSwitcher && w.duration == const Duration(milliseconds: 150),
);

Future<void> _tapWithoutWaiting(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
}

// ---- the apis ----

ApiClient _myBookingsApi(Completer<void>? historyPending) {
  final routes = venueRoutes();
  return ApiClient(
    'http://api.falsa',
    client: MockClient((request) async {
      final history = request.url.queryParameters['when'] == 'history';
      if (request.url.path == '/bookings' && history) {
        await historyPending?.future;
      }
      final (code, body) = request.url.path == '/bookings'
          ? (
              200,
              '{"bookings": [${history ? bookingJson(id: '00000000-0000-7000-8000-000000000002', status: 'completed') : bookingJson()}]}',
            )
          : routes['${request.method} ${request.url.path}'] ?? (404, '{}');
      return http.Response.bytes(
        utf8.encode(body),
        code,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );
}

ApiClient _venueApi(Completer<void>? pending) {
  final routes = venueRoutes();
  return ApiClient(
    'http://api.falsa',
    client: MockClient((request) async {
      final filtered =
          request.url.path == '/spaces' &&
          request.url.queryParameters.containsKey('sport');
      if (filtered) await pending?.future;
      final (code, body) = filtered
          ? (200, '{"spaces": [$spaceF5Json]}')
          : routes['${request.method} ${request.url.path}'] ?? (404, '{}');
      return http.Response.bytes(
        utf8.encode(body),
        code,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );
}

// ---- the screens ----

Widget _login({FakeCredentials? credentials}) => LoginScreen(
  session: Session(
    repository: SessionRepository(
      credentials: credentials ?? FakeCredentials(),
      api: fakeApi(status: 200, body: profileJson()),
    ),
  ),
  pending: PendingBooking(),
);

Widget _result(ResultTone tone) => ResultScreen(
  icon: Icons.check_circle_outline_rounded,
  tone: tone,
  title: 'Contraseña actualizada',
  text: 'Ya podés iniciar sesión con tu contraseña nueva.',
  primary: 'VOLVER AL INICIO',
  onPrimaryTap: () {},
  secondary: 'Ver más tarde',
  onSecondaryTap: () {},
);

Booking _confirmedBooking() {
  final booking = bookingFromJson(jsonDecode(bookingJson()));
  if (booking == null) fail('the test booking cannot be read');
  return booking;
}

/// A button that opens whatever [open] builds.
class _Host extends StatelessWidget {
  const _Host({required this.open});

  final void Function(BuildContext context) open;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => open(context),
          child: const Text('ABRIR'),
        ),
      ),
    ),
  );
}

Widget _cancellation() => _Host(
  open: (context) =>
      unawaited(confirmCancellation(context, 'Fútbol 5 · Sede Morón')),
);

void main() {
  setUpAll(loadFonts);

  // ---- T3: the list changes in place ----

  testWidgets(
    'switching to «Historial» changes only the list with a 150 ms fade @RED-04-S5',
    (tester) async {
      final pending = Completer<void>();
      await mountUser(tester, api: _myBookingsApi(pending), start: '/bookings');
      final title = tester.element(find.text('Mis reservas'));
      final selector = tester.element(find.text('Historial'));
      final list = _listFade;

      // The fade belongs to the list: the title and the selector stay outside.
      expect(list, findsOneWidget);
      expect(
        find.ancestor(of: find.text('Mis reservas'), matching: list),
        findsNothing,
      );
      expect(
        find.ancestor(of: find.text('Historial'), matching: list),
        findsNothing,
      );
      expect(
        find.descendant(of: list, matching: find.text('ACTIVA')),
        findsOneWidget,
      );

      await tester.tap(find.text('Historial'));
      await _start(tester);
      await tester.pump(_ms(200));
      expect(tester.element(find.text('Mis reservas')), same(title));
      expect(tester.element(find.text('Historial')), same(selector));
      expect(
        find.descendant(of: list, matching: find.byType(Skeleton)),
        findsWidgets,
      );

      pending.complete();
      await _start(tester);
      await tester.pump(_ms(75));
      final fresh = find.text('COMPLETADA');
      expect(find.descendant(of: list, matching: fresh), findsOneWidget);
      expect(_visibility(tester, fresh), allOf(greaterThan(0), lessThan(1)));
      await tester.pump(_ms(200));
      expect(_visibility(tester, fresh), _one);
      expect(tester.element(find.text('Mis reservas')), same(title));
      expect(tester.element(find.text('Historial')), same(selector));
    },
  );

  testWidgets(
    'filtering by sport in a venue changes only the list with a fade @RED-04-S5',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final pending = Completer<void>();
      await mountUser(
        tester,
        api: _venueApi(pending),
        start: '/venues/00000000-0000-7000-8000-000000000001',
      );
      const tennis = 'Moron_Rivadavia_19850_Tenis_PDL_1';
      const football = 'Moron_Rivadavia_19850_Futbol_F5_1';
      final title = tester.element(find.text('SEDE MORÓN'));
      final filter = tester.element(find.text('DEPORTE'));
      final list = _listFade;

      expect(list, findsOneWidget);
      expect(
        find.ancestor(of: find.text('SEDE MORÓN'), matching: list),
        findsNothing,
      );
      expect(
        find.ancestor(of: find.text('DEPORTE'), matching: list),
        findsNothing,
      );
      expect(
        find.descendant(of: list, matching: find.text(tennis)),
        findsOneWidget,
      );

      await _tapWithoutWaiting(tester, find.bySemanticsLabel('Deporte Fútbol'));
      await _start(tester);
      await tester.pump(_ms(200));
      expect(tester.element(find.text('SEDE MORÓN')), same(title));
      expect(tester.element(find.text('DEPORTE')), same(filter));
      expect(_listFade, findsOneWidget);

      pending.complete();
      await _start(tester);
      await tester.pump(_ms(200));
      expect(find.text(tennis), findsNothing);
      expect(
        find.descendant(of: list, matching: find.text(football)),
        findsOneWidget,
      );
      expect(tester.element(find.text('SEDE MORÓN')), same(title));
      expect(tester.element(find.text('DEPORTE')), same(filter));
      semantics.dispose();
    },
  );

  testWidgets(
    'with reduce motion the list changes on the first frame @RED-04-S14',
    (tester) async {
      _reduceMotion(tester);
      await mountUser(tester, api: _myBookingsApi(null), start: '/bookings');
      expect(find.text('ACTIVA'), findsOneWidget);

      await tester.tap(find.text('Historial'));
      await _start(tester);

      expect(find.text('COMPLETADA'), findsOneWidget);
      expect(find.text('ACTIVA'), findsNothing);
      expect(_visibility(tester, find.text('COMPLETADA')), _one);
    },
  );

  testWidgets(
    'the list of the other tab is not visible while loading @RED-04-ASM-07',
    (tester) async {
      final pending = Completer<void>();
      await mountUser(tester, api: _myBookingsApi(pending), start: '/bookings');
      expect(find.text('ACTIVA'), findsOneWidget);

      await tester.tap(find.text('Historial'));
      await _start(tester);
      await tester.pump(_ms(200));

      // The old list belongs to «Próximas»: with «Historial» selected it cannot be seen.
      expect(find.text('ACTIVA'), findsNothing);
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text('COMPLETADA'), findsNothing);

      pending.complete();
      await _start(tester);
      await tester.pump(_ms(200));
      expect(find.text('COMPLETADA'), findsOneWidget);
      expect(find.text('ACTIVA'), findsNothing);
      expect(find.byType(Skeleton), findsNothing);
    },
  );

  // ---- T4: the entrances, the errors and the successes ----

  testWidgets(
    'the login enters staggered: logo mark, form, button and footer @RED-04-S6',
    (tester) async {
      await _mountFree(tester, _login());
      Iterable<Duration> delays(Finder f) =>
          _appearances(tester, f).map((a) => a.delay);

      expect(
        _appearances(
          tester,
          find.byType(LogoMark),
        ).any((a) => a.turn != 0 && a.fromY < 0),
        isTrue,
        reason: 'the logo mark drops and spins',
      );
      expect(delays(find.byType(FormTextField).first), contains(_ms(460)));
      expect(delays(find.text('INICIAR SESIÓN')), contains(_ms(540)));
      expect(delays(find.text('¿No tenés cuenta?')), contains(_ms(620)));

      final form = _appearanceWhere(
        find.byType(FormTextField).first,
        (a) => a.delay == _ms(460),
      ).first;
      expect(_opacity(tester, form), 0);
      await tester.pump(_ms(400));
      expect(_opacity(tester, form), 0);
      await tester.pump(_ms(300));
      expect(_opacity(tester, form), allOf(greaterThan(0), lessThan(1)));
      await tester.pumpAndSettle();
      expect(_opacity(tester, form), 1);
    },
  );

  testWidgets(
    'the home screen enters staggered: greeting, marker, next booking and tiles @RED-04-S6',
    (tester) async {
      await _mountFree(tester, fakeHome(FakeSession(userProfile)));
      await _until(tester, () => find.byType(SportTile).evaluate().isNotEmpty);

      expect(
        _appearances(tester, find.text(HomeGreeting.forHour(clubNow()))),
        isNotEmpty,
      );
      expect(
        _appearances(
          tester,
          find.byType(AppMarker),
        ).any((a) => a.delay == _ms(250) && a.scaleFrom == 0.85),
        isTrue,
        reason: 'the marker at 250 ms, growing from 0.85 to 1',
      );
      expect(
        _appearances(
          tester,
          find.text('TU PRÓXIMA RESERVA'),
        ).any((a) => a.delay == _ms(450) && a.fromY > 0),
        isTrue,
        reason: 'the next booking at 450 ms, dropping from below',
      );
      expect(_appearances(tester, find.text('Buscar cancha')), isNotEmpty);

      final tiles = find.byType(SportTile).evaluate().length;
      expect(tiles, greaterThan(1));
      final delays = <Duration>[];
      for (var i = 0; i < tiles; i++) {
        final tile = _appearances(tester, find.byType(SportTile).at(i)).first;
        expect(tile.fromX, 120, reason: 'tile $i');
        expect(tile.turn, isNot(0), reason: 'tile $i');
        delays.add(tile.delay);
      }
      expect(delays.first, greaterThanOrEqualTo(_ms(700)));
      for (var i = 1; i < delays.length; i++) {
        expect(delays[i], greaterThan(delays[i - 1]), reason: 'tile $i');
      }

      // The clock started with the data: the marker waits its 250 ms.
      final marker = _appearanceWhere(
        find.byType(AppMarker),
        (a) => a.delay == _ms(250),
      ).first;
      expect(_opacity(tester, marker), 0);
      await tester.pump(_ms(200));
      expect(_opacity(tester, marker), 0);
      await tester.pump(_ms(300));
      expect(_opacity(tester, marker), allOf(greaterThan(0), lessThan(1)));
      await tester.pumpAndSettle();
      expect(_opacity(tester, marker), 1);
    },
  );

  testWidgets('my profile enters staggered: card and cards @RED-04-S6', (
    tester,
  ) async {
    await _mountFree(
      tester,
      MyProfileScreen(
        session: FakeSession(userProfile),
        appearance: Appearance.inMemory(),
      ),
    );
    await _until(
      tester,
      () => find.byType(MemberProfile).evaluate().isNotEmpty,
    );

    final card = _appearances(tester, find.byType(MemberProfile));
    expect(
      card.any(
        (a) => a.fromY == -24 && a.turn != 0 && a.curve == AppMotion.smooth,
      ),
      isTrue,
      reason: 'the card drops 24 while spinning, with the soft curve',
    );

    final delays = <Duration>[];
    for (final title in ['DATOS PERSONALES', 'SEGURIDAD', 'APARIENCIA']) {
      final wrappers = _appearances(tester, find.text(title));
      expect(wrappers, isNotEmpty, reason: title);
      delays.add(wrappers.first.delay);
    }
    final signOut = _appearances(tester, find.text('CERRAR SESIÓN'));
    expect(signOut, isNotEmpty);
    delays.add(signOut.first.delay);
    for (var i = 1; i < delays.length; i++) {
      expect(delays[i], greaterThan(delays[i - 1]), reason: 'block $i');
    }
    expect(
      card.map((a) => a.delay).reduce((a, b) => a < b ? a : b),
      lessThanOrEqualTo(delays.first),
    );
  });

  testWidgets(
    'reloading home from scratch does not repeat the entrance @RED-04-ASM-04',
    (tester) async {
      final data = ValueNotifier<int>(0);
      addTearDown(data.dispose);
      final session = FakeSession(userProfile);
      await _mountFree(
        tester,
        ValueListenableBuilder<int>(
          valueListenable: data,
          builder: (context, n, _) => fakeHome(session, withBooking: n.isEven),
        ),
      );
      await _until(tester, () => find.byType(SportTile).evaluate().isNotEmpty);
      expect(
        _allAtEnd(tester),
        isFalse,
        reason: 'the first time it does enter',
      );
      await tester.pumpAndSettle();
      expect(_allAtEnd(tester), isTrue);

      // Other data: the screen empties and reads again.
      data.value = 1;
      await tester.pump();
      expect(find.byType(SportTile), findsNothing);
      await _until(tester, () => find.byType(SportTile).evaluate().isNotEmpty);

      // The new blocks are already at their end state, without entering again.
      expect(find.byType(FadeIn), findsWidgets);
      expect(_allAtEnd(tester), isTrue);
      expect(find.text('TU PRÓXIMA RESERVA'), findsNothing);
    },
  );

  testWidgets('a text field that gets an error shakes once @RED-04-S7', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? error;
    late StateSetter rebuild;
    await _mountFree(
      tester,
      Padding(
        padding: const EdgeInsets.all(24),
        child: StatefulBuilder(
          builder: (context, set) {
            rebuild = set;
            return FormTextField(
              semanticLabel: 'Correo',
              controller: controller,
              error: error,
            );
          },
        ),
      ),
    );
    final field = find.descendant(
      of: find.byType(FormTextField),
      matching: find.byType(TextField),
    );
    final rest = tester.getTopLeft(field).dx;

    // Without an error it does not shake.
    await tester.pump(_ms(500));
    expect(tester.getTopLeft(field).dx, rest);

    rebuild(() => error = 'Completá tu correo electrónico');
    await _start(tester);
    expect(
      _shakes(
        tester,
        find.byType(FormTextField),
      ).any((t) => t.trigger == error),
      isTrue,
      reason: 'the trigger is the error',
    );
    _expectShakes(await _path(tester, field), reason: 'el campo');
    expect(tester.getTopLeft(field).dx, closeTo(rest, 0.01));

    // Only once: the same error, even if rebuilt, does not repeat it.
    rebuild(() => error = 'Completá tu correo electrónico');
    await _start(tester);
    _doesNotShake(await _path(tester, field), reason: 'el mismo error');
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a selector that gets an error shakes once @RED-04-S7', (
    tester,
  ) async {
    String? error;
    late StateSetter rebuild;
    await _mountFree(
      tester,
      Padding(
        padding: const EdgeInsets.all(24),
        child: StatefulBuilder(
          builder: (context, set) {
            rebuild = set;
            return SelectorField(
              label: 'DEPORTE',
              semanticLabel: 'Deporte',
              value: null,
              placeholder: 'Elegí un deporte',
              icon: Icons.expand_more_rounded,
              onTap: () {},
              error: error,
            );
          },
        ),
      ),
    );
    final selector = find.descendant(
      of: find.byType(SelectorField),
      matching: find.byType(InkWell),
    );
    final rest = tester.getTopLeft(selector).dx;

    await tester.pump(_ms(500));
    expect(tester.getTopLeft(selector).dx, rest);

    rebuild(() => error = 'Elegí un deporte');
    await _start(tester);
    expect(
      _shakes(
        tester,
        find.byType(SelectorField),
      ).any((t) => t.trigger == error),
      isTrue,
      reason: 'the trigger is the error',
    );
    _expectShakes(await _path(tester, selector), reason: 'el selector');
    expect(tester.getTopLeft(selector).dx, closeTo(rest, 0.01));

    rebuild(() => error = 'Elegí un deporte');
    await _start(tester);
    _doesNotShake(await _path(tester, selector), reason: 'el mismo error');
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets(
    'the invalid-credentials notice shakes every time it appears and the same error does not shake the field again @RED-04-ASM-10',
    (tester) async {
      final credentials = FakeCredentials(
        onSignIn: (_, _) async => throw const InvalidCredentials(),
      );
      await _mountFree(tester, _login(credentials: credentials));
      await tester.pumpAndSettle();
      final field = find.byType(TextField).first;

      // Resubmitting empty with the same error: it shakes the first time and not the second.
      await tester.tap(find.text('INICIAR SESIÓN'));
      await _start(tester);
      expect(find.text('Completá tu correo electrónico'), findsOneWidget);
      _expectShakes(await _path(tester, field), reason: 'el campo, 1.ª vez');
      await tester.tap(find.text('INICIAR SESIÓN'));
      await _start(tester);
      expect(find.text('Completá tu correo electrónico'), findsOneWidget);
      _doesNotShake(await _path(tester, field), reason: 'el mismo error');

      // With complete but wrong data, the notice shakes when it appears, every time.
      await tester.enterText(find.byType(TextField).first, 'nahuel@correo.com');
      await tester.enterText(find.byType(TextField).last, 'Mala1234');
      for (var time = 1; time <= 2; time++) {
        await tester.tap(find.text('INICIAR SESIÓN'));
        await _until(
          tester,
          () => find.text(invalidCredentialsMessage).evaluate().isNotEmpty,
        );
        await _start(tester);
        _expectShakes(
          await _path(tester, find.byType(ErrorSnackbar)),
          reason: 'el aviso, $time.ª vez',
        );
        await tester.tap(find.byTooltip('Cerrar aviso'));
        await tester.pumpAndSettle();
        expect(find.text(invalidCredentialsMessage), findsNothing);
      }
      expect(credentials.attempts, hasLength(2));
    },
  );

  testWidgets(
    'the success result animates its circle and staggers its text @RED-04-S8',
    (tester) async {
      await _mountFree(tester, _result(ResultTone.success));
      final palette = tester.element(find.byType(ResultScreen)).palette;

      final pulse = tester.widget<SuccessPulse>(find.byType(SuccessPulse));
      expect(pulse.icon, Icons.check_circle_outline_rounded);
      expect(pulse.background, palette.stateSuccessMuted);
      expect(pulse.ink, palette.stateSuccessInk);
      expect(_pulseScale(tester), closeTo(0.4, 1e-6));
      await tester.pump(_ms(550));
      expect(_pulseScale(tester), closeTo(1, 1e-3));

      // Title, text and action drop 14, staggered.
      for (final (finder, delay) in [
        (find.text('Contraseña actualizada'), 370),
        (find.text('Ya podés iniciar sesión con tu contraseña nueva.'), 460),
        (find.text('VOLVER AL INICIO'), 550),
      ]) {
        final entrance = _appearances(tester, finder);
        expect(
          entrance.any((a) => a.delay == _ms(delay) && a.fromY == 14),
          isTrue,
          reason: 'at $delay ms',
        );
      }
      await tester.pumpAndSettle();
      expect(_allAtEnd(tester), isTrue);
    },
  );

  testWidgets(
    'the notice result and the danger result also animate their circle @RED-04-S8',
    (tester) async {
      for (final tone in [ResultTone.warning, ResultTone.danger]) {
        await _mountFree(tester, _result(tone));
        final palette = tester.element(find.byType(ResultScreen)).palette;
        final (background, ink) = switch (tone) {
          ResultTone.warning => (
            palette.bgSurfaceRaised,
            palette.textSecondary,
          ),
          _ => (palette.stateDangerMuted, palette.stateDangerInk),
        };

        final pulse = tester.widget<SuccessPulse>(find.byType(SuccessPulse));
        expect(pulse.background, background, reason: '$tone');
        expect(pulse.ink, ink, reason: '$tone');
        expect(_pulseScale(tester), closeTo(0.4, 1e-6), reason: '$tone');
        expect(_clipRadius(tester, find.byType(SuccessPulse)), _zero);
        await tester.pump(_ms(550));
        expect(_pulseScale(tester), closeTo(1, 1e-3), reason: '$tone');
        await tester.pumpAndSettle();
        await _unmount(tester);
      }
    },
  );

  testWidgets(
    '«el tilde se dibuja»: the successful sign-up reveals its icon with the same piece @RED-04-ASM-08',
    (tester) async {
      await _mountFree(tester, const RegistrationDoneScreen());
      final palette = tester
          .element(find.byType(RegistrationDoneScreen))
          .palette;

      final pulse = tester.widget<SuccessPulse>(find.byType(SuccessPulse));
      expect(pulse.icon, Icons.check_circle_outline_rounded);
      expect(pulse.background, palette.stateSuccessMuted);
      expect(pulse.ink, palette.stateSuccessInk);
      expect(_pulseScale(tester), closeTo(0.4, 1e-6));

      // The icon is revealed with a growing clip.
      final icon = find.byType(SuccessPulse);
      expect(_clipRadius(tester, icon), _zero);
      await tester.pump(_ms(150));
      expect(_clipRadius(tester, icon), _zero);
      await tester.pump(_ms(250));
      expect(_clipRadius(tester, icon), greaterThan(0));
      await tester.pump(_ms(250));
      final full = _clipRadius(tester, icon);
      await tester.pumpAndSettle();
      expect(_clipRadius(tester, icon), closeTo(full, 1e-6));
      expect(_pulseScale(tester), _one);

      // The title and the text stagger as in ResultScreen.
      expect(_appearances(tester, find.text('¡Cuenta creada!')), isNotEmpty);
    },
  );

  testWidgets('the confirmed booking celebrates once @RED-04-S9', (
    tester,
  ) async {
    await _mountFree(
      tester,
      BookingConfirmedScreen(booking: _confirmedBooking()),
    );
    expect(find.byType(Celebration), findsOneWidget);
    final title = find.text('¡Reserva confirmada!');
    final receipt = find.text('Horario');

    final atStart = _width(tester, title);
    await tester.pump(_ms(500));
    final halfway = _width(tester, title);
    await tester.pump(_ms(300));
    expect(_visibility(tester, receipt), 0, reason: 'before 870 ms');

    // It ends by itself: if the celebration repeated, this would not finish.
    await tester.pumpAndSettle();
    final whole = _width(tester, title);
    expect(atStart / whole, lessThan(1));
    expect(halfway / whole, allOf(greaterThan(0.5), lessThan(1)));
    expect(_visibility(tester, receipt), _one);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pump(const Duration(seconds: 10));
    expect(_width(tester, title), closeTo(whole, 1e-6));
    expect(_visibility(tester, receipt), _one);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets(
    'changing the duration makes the day timeline beat and choosing a slot makes it grow @RED-04-S10',
    (tester) async {
      await mountUser(
        tester,
        api: apiRoutes(venueRoutes()),
        start:
            '/venues/00000000-0000-7000-8000-000000000001/spaces/00000000-0000-7000-8000-000000000009',
      );
      final line = find.byType(DayTimeline);
      expect(
        find.ancestor(of: line, matching: find.byType(Heartbeat)),
        findsOneWidget,
      );
      final base = _width(tester, line);
      double scale() => _width(tester, line) / base;

      await _tapWithoutWaiting(tester, find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(scale(), closeTo(1, 1e-3));
      await tester.pump(_ms(200));
      expect(scale(), allOf(greaterThan(1), lessThanOrEqualTo(1.0301)));
      await tester.pump(_ms(50));
      expect(scale(), closeTo(1.03, 3e-3));
      await tester.pump(_ms(250));
      expect(scale(), closeTo(1, 1e-3));
      await tester.pumpAndSettle();
      expect(scale(), closeTo(1, 1e-3));

      // The chosen slot grows from 0.88 to 1.
      final slot = find.text('18:00 – 19:00').first;
      final wholeWidth = _width(tester, slot);
      await _tapWithoutWaiting(tester, slot);
      await tester.pump();
      expect(_width(tester, slot) / wholeWidth, closeTo(0.88, 0.02));
      await tester.pump(_ms(200));
      expect(_width(tester, slot) / wholeWidth, greaterThan(0.88));
      await tester.pumpAndSettle();
      expect(_width(tester, slot) / wholeWidth, closeTo(1, 1e-3));
    },
  );

  testWidgets('the in-app notice drops from the top @RED-04-S12', (
    tester,
  ) async {
    final api = FakeApi();
    final session = FakeSession(userProfile);
    final center = centerOf(api, session);
    await mountScreen(
      tester,
      Stack(
        children: [
          const Scaffold(body: Center(child: Text('la pantalla de abajo'))),
          NoticePanel(center: center, now: () => noticesNow, onOpen: (_) {}),
        ],
      ),
      theme: darkTheme,
    );
    api
      ..notices = [reminderNotice]
      ..unread = 1;
    await tester.runAsync(center.load);
    await tester.pump();
    await tester.pump();

    final title = find.text('NOTIFICACIONES');
    expect(title, findsOneWidget);
    expect(
      _appearances(
        tester,
        title,
      ).any((a) => a.fromY == -150 && a.curve == AppMotion.bounce),
      isTrue,
      reason: 'drops from −150 with a bounce',
    );
    final top = tester.getTopLeft(title).dy;
    await tester.pump(_ms(100));
    expect(tester.getTopLeft(title).dy, greaterThan(top));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(title).dy - top, closeTo(150, 0.5));
  });

  testWidgets('the buttons of button.dart shrink while pressed @RED-04-S13', (
    tester,
  ) async {
    await mountScreen(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryButton(label: 'PRIMARIO', onTap: () {}),
              TextActionButton(label: 'TEXTO', onTap: () {}),
              OutlineButton(label: 'CONTORNO', onTap: () {}),
              DangerButton(label: 'PELIGRO', onTap: () {}),
            ],
          ),
        ),
      ),
      theme: darkTheme,
    );

    for (final text in ['PRIMARIO', 'TEXTO', 'CONTORNO', 'PELIGRO']) {
      final label = find.text(text);
      final released = _width(tester, label);
      final finger = await tester.startGesture(tester.getCenter(label));
      await tester.pump();
      await tester.pump(_ms(40));
      expect(_width(tester, label) / released, lessThan(1), reason: text);
      await tester.pump(_ms(40));
      expect(
        _width(tester, label) / released,
        closeTo(0.97, 3e-3),
        reason: text,
      );
      await finger.up();
      await tester.pump();
      await tester.pump(_ms(80));
      expect(_width(tester, label) / released, closeTo(1, 3e-3), reason: text);
      await tester.pumpAndSettle();
    }
  });

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

  // ---- T5: dialogs and account card ----

  testWidgets(
    'a DialogFrame dialog enters with a fade and a scale from 0.88 to 1 @RED-04-S11',
    (tester) async {
      await mountScreen(tester, _cancellation(), theme: darkTheme);
      await tester.tap(find.text('ABRIR'));
      await tester.pump();

      final title = find.text('¿Cancelar la reserva?');
      expect(title, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DialogFrame),
          matching: find.byWidgetPredicate((w) => w is FadeIn),
        ),
        findsWidgets,
        reason: 'the dialog animates inside the frame',
      );
      final entrance = _appearanceWhere(title, (a) => a.scaleFrom == 0.88);
      expect(entrance, findsOneWidget);
      final appearance = tester.widget<FadeIn>(entrance);
      expect(appearance.fromY, 0);
      expect(appearance.curve, AppMotion.fast);

      final atStart = _width(tester, title);
      expect(_opacity(tester, entrance), 0);
      await tester.pump(_ms(100));
      expect(_opacity(tester, entrance), allOf(greaterThan(0), lessThan(1)));
      await tester.pumpAndSettle();
      final whole = _width(tester, title);
      expect(atStart / whole, closeTo(0.88, 0.02));
      expect(_opacity(tester, entrance), 1);
    },
  );

  testWidgets(
    'the options selector enters with the same scale @RED-04-ASM-01',
    (tester) async {
      await mountScreen(
        tester,
        _Host(
          open: (context) => unawaited(
            pickOption<int>(
              context,
              title: 'Elegí el deporte',
              options: const [(1, 'Fútbol'), (2, 'Tenis')],
            ),
          ),
        ),
        theme: darkTheme,
      );
      await tester.tap(find.text('ABRIR'));
      await tester.pump();

      final title = find.text('Elegí el deporte');
      expect(title, findsOneWidget);
      final entrance = _appearanceWhere(title, (a) => a.scaleFrom == 0.88);
      expect(entrance, findsOneWidget);
      final appearance = tester.widget<FadeIn>(entrance);
      expect(appearance.fromY, 0);
      expect(appearance.curve, AppMotion.fast);

      final atStart = _width(tester, title);
      await tester.pumpAndSettle();
      expect(atStart / _width(tester, title), closeTo(0.88, 0.02));
    },
  );

  testWidgets('the account card drops 16 and appears in 350 ms @RED-04-S11', (
    tester,
  ) async {
    await mountScreen(
      tester,
      Scaffold(
        body: Center(child: AccountButton(session: FakeSession(userProfile))),
      ),
      theme: darkTheme,
    );
    await tester.tap(find.byType(AccountButton));
    await tester.pump();

    final name = find.text('Nahuel Mosse');
    expect(name, findsOneWidget);
    final entrance = _appearanceWhere(
      name,
      (a) => a.fromY == -16 && a.duration == _ms(350),
    );
    expect(entrance, findsOneWidget);

    final top = tester.getTopLeft(name).dy;
    expect(_opacity(tester, entrance), 0);
    await tester.pump(_ms(175));
    final halfway = tester.getTopLeft(name).dy;
    expect(_opacity(tester, entrance), allOf(greaterThan(0), lessThan(1)));
    await tester.pump(_ms(175));
    final below = tester.getTopLeft(name).dy;
    expect(below - top, closeTo(16, 0.01));
    expect(halfway, allOf(greaterThan(top), lessThan(below)));
    expect(_opacity(tester, entrance), 1);
  });

  testWidgets('the buttons of a dialog shrink while pressed @RED-04-S13', (
    tester,
  ) async {
    await mountScreen(tester, _cancellation(), theme: darkTheme);
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();

    for (final text in ['CANCELAR RESERVA', 'NO CANCELAR']) {
      final label = find.text(text);
      final released = _width(tester, label);
      final finger = await tester.startGesture(tester.getCenter(label));
      await tester.pump();
      await tester.pump(_ms(40));
      expect(_width(tester, label) / released, lessThan(1), reason: text);
      await tester.pump(_ms(40));
      expect(
        _width(tester, label) / released,
        closeTo(0.97, 3e-3),
        reason: text,
      );
      await finger.cancel();
      await tester.pump();
      await tester.pump(_ms(80));
      expect(_width(tester, label) / released, closeTo(1, 3e-3), reason: text);
    }
  });

  testWidgets(
    'with reduce motion the dialog appears whole on the first frame @RED-04-S14',
    (tester) async {
      _reduceMotion(tester);
      await mountScreen(tester, _cancellation(), theme: darkTheme);
      await tester.tap(find.text('ABRIR'));
      await tester.pump();

      final title = find.text('¿Cancelar la reserva?');
      final entrance = _appearanceWhere(title, (a) => a.scaleFrom == 0.88);
      expect(entrance, findsOneWidget);
      expect(_opacity(tester, entrance), 1);
      final atStart = _width(tester, title);
      await tester.pumpAndSettle();
      expect(_width(tester, title), closeTo(atStart, 1e-6));
    },
  );

  // ---- T6: the screenshots ----

  testWidgets(
    'screenshots are taken with the animations finished @RED-04-ASM-12',
    (tester) async {
      final screens = <String, Widget>{
        'login': _login(),
        'starts_at': fakeHome(FakeSession(userProfile)),
        'mi perfil': MyProfileScreen(
          session: FakeSession(userProfile),
          appearance: Appearance.inMemory(),
        ),
        'reserva confirmada': BookingConfirmedScreen(
          booking: _confirmedBooking(),
        ),
      };
      for (final MapEntry(key: name, value: screen) in screens.entries) {
        // Like the helpers of test/screenshots: `mountScreen` ends with pumpAndSettle.
        await mountScreen(tester, screen, theme: darkTheme);
        expect(find.byType(FadeIn), findsWidgets, reason: name);
        expect(_allAtEnd(tester), isTrue, reason: name);
        expect(tester.binding.hasScheduledFrame, isFalse, reason: name);
        await _unmount(tester);
      }
    },
  );
}
