import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/bib.dart';
import 'package:clubnahuelmosse/common/member_profile.dart';
import 'package:clubnahuelmosse/common/logo_mark.dart';
import 'package:clubnahuelmosse/common/day_timeline.dart';
import 'package:clubnahuelmosse/common/marker.dart';
import 'package:clubnahuelmosse/common/pending_booking.dart';
import 'package:clubnahuelmosse/common/sport_tile.dart';
import 'package:clubnahuelmosse/common/die_cut.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/my_bookings_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/bookings.dart';
import 'package:clubnahuelmosse/features/bookings/data/bookings_api.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/mount.dart';
import '../support/fixed_clock.dart';
import '../support/user.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/venues/presentation/photos.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venue_card.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

const _dark = Palette.dark;

const _borderKey = ValueKey('borde-reserva-activa');

const _catalog =
    '{"sports": ['
    '{"key": "Futbol", "name": "Fútbol", "kinds": ['
    '{"key": "F5", "name": "Fútbol 5"}]}, '
    '{"key": "Tenis", "name": "Tenis", "kinds": ['
    '{"key": "PDL", "name": "Polvo de ladrillo"}]}, '
    '{"key": "Padel", "name": "Pádel", "kinds": [{"key": "PAD", "name": "Pádel"}]}, '
    '{"key": "Voley", "name": "Vóley", "kinds": [{"key": "IND", "name": "Indoor"}]}, '
    '{"key": "Basquet", "name": "Básquet", "kinds": [{"key": "B5", "name": "Básquet 5"}]}, '
    '{"key": "Hockey", "name": "Hockey", "kinds": [{"key": "H7", "name": "Hockey 7"}]}, '
    '{"key": "Golf", "name": "Golf", "kinds": [{"key": "DR", "name": "Driving range"}]}'
    ']}';

const _catalogWithUnknown =
    '{"sports": ['
    '{"key": "Futbol", "name": "Fútbol", "kinds": ['
    '{"key": "F5", "name": "Fútbol 5"}]}, '
    '{"key": "Rugby", "name": "Rugby", "kinds": ['
    '{"key": "R7", "name": "Rugby 7"}]}'
    ']}';

String _venue(String id, String name, String direction, int spaceCount) =>
    '{"id": "$id", "name": "$name", "address": "$direction", '
    '"opens_at": "08:00", "closes_at": "23:00", "open_days": [1, 2, 3, 4, 5, 6, 7], '
    '"space_count": $spaceCount, "sports": ["Futbol", "Tenis"]}';

final _venues =
    '{"venues": [${_venue('00000000-0000-7000-8000-000000000001', 'Sede Haedo', 'Av. Vergara 1850', 6)}, '
    '${_venue('00000000-0000-7000-8000-000000000002', 'Sede Morón', 'Av. Rivadavia 19850', 4)}, '
    '${_venue('00000000-0000-7000-8000-000000000003', 'Sede Castelar', 'Av. Santa Rosa 1200', 4)}, '
    '${_venue('00000000-0000-7000-8000-000000000004', 'Sede Ituzaingó', 'Blas Parera 300', 3)}]}';

/// A club instant: [day] of November 2026 at [hour]:[minute] (UTC−3).
DateTime _atClub(int day, int hour, [int minute = 0]) =>
    DateTime.utc(2026, 11, day, hour + 3, minute);

String _uuid(int n) =>
    '00000000-0000-7000-8000-${n.toString().padLeft(12, '0')}';

String _booking({
  String id = '00000000-0000-7000-8000-000000000001',
  DateTime? startsAt,
  String state = 'active',
  String? reason,
}) {
  final start = startsAt ?? _atClub(12, 21);
  final end = start.add(const Duration(hours: 1));
  return '{"id": "$id", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000002", '
      '"space": "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", '
      '"kind": "F5", "venue": "Sede Morón", "address": "Av. Rivadavia 19850", '
      '"starts_at": "${start.toIso8601String()}", "ends_at": "${end.toIso8601String()}", '
      '"price_per_hour": 38000, "total": 38000, "status": "$state", '
      '"reason": ${reason == null ? 'null' : '"$reason"'}, '
      '"cancelable": ${state == 'active'}}';
}

Future<void> _mountHome(
  WidgetTester tester, {
  List<String>? bookings,
  String? next,
  String catalog = _catalog,
  ThemeData? theme,
  Size size = const Size(393, 852),
}) {
  final session = FakeSession(userProfile);
  final list = (bookings ?? [_booking()]).join(', ');
  final api = apiRoutes({
    'GET /bookings': (
      200,
      '{"bookings": [$list]'
          '${next == null ? '' : ', "siguiente": "$next"'}}',
    ),
    'GET /spaces/catalog': (200, catalog),
    'GET /venues': (200, _venues),
  });
  return mountScreen(
    tester,
    HomeScreen(
      sesion: session,
      reservas: Bookings(BookingsApi(api: api, sesion: session)),
      espacios: Spaces(
        repository: SpacesRepository(api: api, session: session),
      ),
      venues: Venues(
        repository: VenuesRepository(api: api, session: session),
      ),
    ),
    theme: theme ?? darkTheme,
    size: size,
  );
}

Future<void> _mountMyBookings(
  WidgetTester tester, {
  String upcoming = '[]',
  String historial = '[]',
  String startRoute = '/reservas',
  bool dark = true,
}) {
  final routes = venueRoutes();
  return mountUser(
    tester,
    start: startRoute,
    dark: dark,
    size: const Size(393, 1600),
    api: ApiClient(
      'http://api.falsa',
      cliente: MockClient((request) async {
        final (c, body) = request.url.path == '/bookings'
            ? (
                200,
                '{"bookings": ${request.url.queryParameters['when'] == 'history' ? historial : upcoming}}',
              )
            : routes['${request.method} ${request.url.path}'] ?? (404, '{}');
        return http.Response.bytes(
          utf8.encode(body),
          c,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    ),
  );
}

Finder _inMarker(Finder child) =>
    find.descendant(of: find.byType(AppMarker), matching: child);

Color? _figureColor(WidgetTester tester, String figure) =>
    tester.widget<Text>(_inMarker(find.text(figure))).style?.color;

Color? _borderColor(WidgetTester tester, Finder border) {
  final w = tester.widget(border);
  if (w is Container) {
    return w.color ?? (w.decoration as BoxDecoration?)?.color;
  }
  if (w is DecoratedBox) return (w.decoration as BoxDecoration).color;
  if (w is ColoredBox) return w.color;
  final box = find.descendant(of: border, matching: find.byType(DecoratedBox));
  if (box.evaluate().isNotEmpty) {
    return (tester.widget<DecoratedBox>(box.first).decoration as BoxDecoration)
        .color;
  }
  return tester
      .widget<ColoredBox>(
        find.descendant(of: border, matching: find.byType(ColoredBox)).first,
      )
      .color;
}

bool _withFocusOutline(WidgetTester tester, Finder card) => tester
    .widgetList<DecoratedBox>(
      find.descendant(of: card, matching: find.byType(DecoratedBox)),
    )
    .any(
      (c) =>
          c.decoration is BoxDecoration &&
          (c.decoration as BoxDecoration).border?.top.color ==
              _dark.borderFocus,
    );

Finder _inCard(Finder child) =>
    find.descendant(of: find.byType(BookingCard), matching: child);

const _countdowns = ['HOY', 'MAÑANA', 'FALTAN 2 DÍAS'];

void _withoutCountdown() {
  for (final text in _countdowns) {
    expect(find.text(text), findsNothing, reason: text);
  }
}

void main() {
  setUpAll(loadFonts);

  group('home', () {
    testWidgets(
      'the home hero has the marker with venues, courts and upcoming @RED-03-S1',
      (tester) async {
        await _mountHome(tester);

        expect(find.byType(AppMarker), findsOneWidget);
        final cells = tester.widget<AppMarker>(find.byType(AppMarker)).cells;
        expect(
          [for (final c in cells) (c.label.toUpperCase(), c.figure)],
          [('SEDES', '04'), ('CANCHAS', '17'), ('PRÓXIMAS', '01')],
        );
        for (final text in ['SEDES', 'CANCHAS', 'PRÓXIMAS', '04', '17', '01']) {
          expect(_inMarker(find.text(text)), findsOneWidget, reason: text);
        }
        expect(
          tester.getTopLeft(find.byType(AppMarker)).dy,
          lessThan(tester.getTopLeft(find.text('TU PRÓXIMA RESERVA')).dy),
        );
      },
    );

    testWidgets(
      'the sports section shows one tile per catalog sport @RED-03-S1',
      (tester) async {
        await _mountHome(tester);

        const expected = [
          ('Futbol', 'Fútbol', '⚽'),
          ('Tenis', 'Tenis', '🎾'),
          ('Padel', 'Pádel', '🏓'),
          ('Voley', 'Vóley', '🏐'),
          ('Basquet', 'Básquet', '🏀'),
          ('Hockey', 'Hockey', '🏑'),
          ('Golf', 'Golf', '⛳'),
        ];
        expect(find.text('DEPORTES'), findsOneWidget);
        expect(find.byType(SportTile), findsNWidgets(expected.length));
        for (final (i, (key, name, emoji)) in expected.indexed) {
          final tile = find.byType(SportTile).at(i);
          final widget = tester.widget<SportTile>(tile);
          expect(widget.name, name);
          expect(widget.emoji, emoji, reason: key);
          expect(widget.image, sportPhoto(key), reason: key);
          expect(
            find.descendant(of: tile, matching: find.text(name)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: tile, matching: find.byType(Image)),
            findsOneWidget,
          );
        }
      },
    );

    testWidgets(
      'the highlighted marker cell is «PRÓXIMAS» and counts the active upcoming bookings @RED-03-ASM-01',
      (tester) async {
        await _mountHome(
          tester,
          bookings: [
            _booking(
              id: '00000000-0000-7000-8000-000000000001',
              startsAt: _atClub(12, 21),
            ),
            _booking(
              id: '00000000-0000-7000-8000-000000000002',
              startsAt: _atClub(13, 10),
            ),
            _booking(
              id: '00000000-0000-7000-8000-000000000003',
              startsAt: _atClub(14, 10),
            ),
          ],
        );

        final cells = tester.widget<AppMarker>(find.byType(AppMarker)).cells;
        final highlighted = cells.where((c) => c.highlighted).toList();
        expect(highlighted, hasLength(1));
        expect(highlighted.single.label.toUpperCase(), 'PRÓXIMAS');
        expect(highlighted.single.figure, '03');
        expect(_figureColor(tester, '03'), _dark.accentOnMedia);
        expect(_figureColor(tester, '04'), _dark.textOnMedia);
        expect(find.text('LIBRES HOY'), findsNothing);
      },
    );

    testWidgets(
      'the marker replaces «N sedes · N canchas · disponibilidad en tiempo real» and shows the figures with two digits, 04 @RED-03-ASM-02',
      (tester) async {
        await _mountHome(tester);

        expect(
          find.text('4 sedes · 17 canchas · disponibilidad en tiempo real'),
          findsNothing,
        );
        expect(
          find.textContaining('disponibilidad en tiempo real'),
          findsNothing,
        );
        expect(_inMarker(find.text('04')), findsOneWidget);
        expect(_inMarker(find.text('17')), findsOneWidget);
        expect(find.text('4'), findsNothing);
      },
    );

    testWidgets(
      'the tiles use the app photos, do not navigate and are announced only by their name @RED-03-ASM-03',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _mountHome(tester);

        for (final tile in tester.widgetList<SportTile>(
          find.byType(SportTile),
        )) {
          expect(tile.onTap, isNull, reason: tile.name);
          expect(tile.selected, isFalse, reason: tile.name);
        }
        expect(find.text('ELEGIDO'), findsNothing);
        for (final name in ['Fútbol', 'Tenis']) {
          final node = tester.getSemantics(find.bySemanticsLabel(name));
          expect(node.label, name);
          expect(node.flagsCollection.isButton, isFalse, reason: name);
        }

        await tester.tap(find.byType(SportTile).first);
        await tester.pumpAndSettle();
        expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets(
      'an unknown sport has the emoji 🏅 and the football one ⚽ @RED-03-ASM-12',
      (tester) async {
        await _mountHome(tester, catalog: _catalogWithUnknown);

        final tiles = tester
            .widgetList<SportTile>(find.byType(SportTile))
            .toList();
        expect(
          [for (final t in tiles) (t.name, t.emoji)],
          [('Fútbol', '⚽'), ('Rugby', '🏅')],
        );
        expect(tiles.last.image, sportPhoto('Rugby'));
      },
    );

    testWidgets(
      'with more than one batch of upcoming the marker says 20+ @RED-03-ASM-13',
      (tester) async {
        await _mountHome(
          tester,
          bookings: [
            for (var i = 1; i <= 20; i++)
              _booking(
                id: _uuid(i),
                startsAt: _atClub(12, 21).add(Duration(days: i)),
              ),
          ],
          next: 'marcador-de-la-siguiente-tanda',
        );

        expect(_inMarker(find.text('20+')), findsOneWidget);
        expect(_figureColor(tester, '20+'), _dark.accentOnMedia);
      },
    );
  });

  group('booking card', () {
    testWidgets(
      'the booking card separates header and detail with the die-cut @RED-03-S2',
      (tester) async {
        await _mountHome(tester);
        await _expectDieCutBetweenHeaderAndDetail(tester);

        await _mountMyBookings(tester, upcoming: '[${_booking()}]');
        await _expectDieCutBetweenHeaderAndDetail(tester);
      },
    );

    testWidgets(
      'an active booking has the accent border and the countdown @RED-03-S2',
      (tester) async {
        for (final (theme, p) in [
          (darkTheme, Palette.dark),
          (lightTheme, Palette.light),
        ]) {
          await _mountHome(
            tester,
            bookings: [_booking(startsAt: _atClub(14, 12))],
            theme: theme,
          );

          final border = _inCard(find.byKey(_borderKey));
          expect(border, findsOneWidget);
          expect(_borderColor(tester, border), p.accentBase);
          expect(tester.getSize(border).width, 4);
          expect(
            tester.getTopLeft(border).dx -
                tester.getTopLeft(find.byType(BookingCard)).dx,
            inInclusiveRange(0, 2),
          );
          expect(_inCard(find.text('FALTAN 2 DÍAS')), findsOneWidget);
        }
      },
    );

    testWidgets(
      'the countdown says «HOY», «MAÑANA» or «FALTAN N DÍAS» @RED-03-S2',
      (tester) async {
        for (final (startsAt, countdown) in [
          (_atClub(12, 21), 'HOY'),
          (_atClub(13, 12), 'MAÑANA'),
          (_atClub(14, 12), 'FALTAN 2 DÍAS'),
          (_atClub(19, 10), 'FALTAN 7 DÍAS'),
        ]) {
          await _mountHome(tester, bookings: [_booking(startsAt: startsAt)]);

          expect(
            _inCard(find.text(countdown)),
            findsOneWidget,
            reason: countdown,
          );
          for (final other in [..._countdowns, 'FALTAN 7 DÍAS']) {
            if (other != countdown) {
              expect(
                find.text(other),
                findsNothing,
                reason: '$countdown without $other',
              );
            }
          }
        }
      },
    );

    testWidgets('a cancelled booking has no border or countdown @RED-03-S2', (
      tester,
    ) async {
      await _mountMyBookings(
        tester,
        historial:
            '[${_booking(id: '00000000-0000-7000-8000-000000000001', state: 'canceled', startsAt: _atClub(14, 12))}, '
            '${_booking(id: '00000000-0000-7000-8000-000000000002', state: 'voided', reason: 'lluvia', startsAt: _atClub(14, 12))}, '
            '${_booking(id: '00000000-0000-7000-8000-000000000003', state: 'completed', startsAt: _atClub(10, 12))}]',
        startRoute: '/reservas?historial=1',
      );

      expect(find.byType(BookingCard), findsNWidgets(3));
      expect(find.byKey(_borderKey), findsNothing);
      _withoutCountdown();
      expect(find.textContaining('FALTAN'), findsNothing);
      expect(find.byType(DieCut), findsNWidgets(3));
    });

    testWidgets('my bookings does not add a marker @RED-03-ASM-05', (
      tester,
    ) async {
      await _mountMyBookings(tester, upcoming: '[${_booking()}]');
      expect(find.byType(DieCut), findsOneWidget);
      expect(find.byType(AppMarker), findsNothing);

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();
      expect(find.byType(AppMarker), findsNothing);
    });

    testWidgets(
      'the countdown looks at the club day and not the hour @RED-03-ASM-06',
      (tester) async {
        // 23:50 on the 12th at the club: the booking at 00:30 on the 13th is tomorrow, not today.
        await withClock(Clock.fixed(_atClub(12, 23, 50)), () async {
          await _mountHome(
            tester,
            bookings: [_booking(startsAt: _atClub(13, 0, 30))],
          );
          expect(_inCard(find.text('MAÑANA')), findsOneWidget);
          expect(find.text('HOY'), findsNothing);
        });

        // 00:10 on the 12th at the club: the booking at 23:50 that day is today.
        await withClock(Clock.fixed(_atClub(12, 0, 10)), () async {
          await _mountHome(
            tester,
            bookings: [_booking(startsAt: _atClub(12, 23, 50))],
          );
          expect(_inCard(find.text('HOY')), findsOneWidget);
          expect(find.text('MAÑANA'), findsNothing);
        });
      },
    );

    testWidgets(
      'the countdown goes on the home next booking and not on «Mis reservas» @RED-03-ASM-09',
      (tester) async {
        final semantics = tester.ensureSemantics();
        for (final startsAt in [
          _atClub(12, 21),
          _atClub(13, 12),
          _atClub(14, 12),
        ]) {
          await _mountMyBookings(
            tester,
            upcoming: '[${_booking(startsAt: startsAt)}]',
          );

          _withoutCountdown();
          expect(find.bySemanticsLabel(RegExp('faltan')), findsNothing);
          expect(find.byType(DieCut), findsOneWidget);
          expect(find.byKey(_borderKey), findsOneWidget);
          expect(
            _borderColor(tester, find.byKey(_borderKey)),
            _dark.accentBase,
          );
        }

        await _mountHome(
          tester,
          bookings: [_booking(startsAt: _atClub(14, 12))],
        );
        expect(find.text('FALTAN 2 DÍAS'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets(
      'a highlighted active booking keeps the focus outline and adds the border @RED-03-ASM-10',
      (tester) async {
        await _mountMyBookings(
          tester,
          upcoming:
              '[${_booking(id: '00000000-0000-7000-8000-000000000001', startsAt: _atClub(13, 10))}, '
              '${_booking(id: '00000000-0000-7000-8000-000000000002', startsAt: _atClub(14, 10))}]',
          startRoute: '/reservas?reserva=00000000-0000-7000-8000-000000000002',
        );

        final common = find.byType(BookingCard).at(0);
        final highlighted = find.byType(BookingCard).at(1);
        expect(_withFocusOutline(tester, highlighted), isTrue);
        expect(_withFocusOutline(tester, common), isFalse);
        for (final card in [common, highlighted]) {
          expect(
            find.descendant(of: card, matching: find.byKey(_borderKey)),
            findsOneWidget,
          );
        }
      },
    );

    testWidgets(
      'the screen reader announces the countdown at the end of the card, «… faltan 2 días» @RED-03-ASM-11',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _mountHome(
          tester,
          bookings: [_booking(startsAt: _atClub(14, 12))],
        );

        final label = find.bySemanticsLabel(
          RegExp(r'^Fútbol 5, Sede Morón, .*, faltan 2 días$'),
        );
        expect(label, findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('FALTAN')), findsNothing);
        semantics.dispose();
      },
    );
  });

  group('my profile', () {
    Future<void> mountProfile(WidgetTester tester, {bool dark = true}) =>
        mountUser(
          tester,
          start: '/perfil',
          dark: dark,
          api: apiRoutes(venueRoutes()),
        );

    Finder onCard(Finder child) =>
        find.descendant(of: find.byType(MemberProfile), matching: child);

    testWidgets('the my profile header is the member card @RED-03-S3', (
      tester,
    ) async {
      await mountProfile(tester);

      expect(find.byType(MemberProfile), findsOneWidget);
      final card = tester.widget<MemberProfile>(find.byType(MemberProfile));
      expect(card.initials, 'NM');
      expect(card.name, 'Nahuel Mosse');
      expect(card.email, 'nmosse@unimoron.edu.ar');
      expect(onCard(find.text('NM')), findsOneWidget);
      expect(onCard(find.text('Nahuel Mosse')), findsOneWidget);
      expect(onCard(find.text('nmosse@unimoron.edu.ar')), findsOneWidget);
    });

    testWidgets(
      'the my profile card says «MIEMBRO ACTIVO» and shows no marker @RED-03-ASM-04',
      (tester) async {
        await mountProfile(tester);

        final card = tester.widget<MemberProfile>(find.byType(MemberProfile));
        expect(card.number, 'MIEMBRO ACTIVO');
        expect(card.stats, isEmpty);
        expect(onCard(find.text('MIEMBRO ACTIVO')), findsOneWidget);
        expect(onCard(find.byType(AppMarker)), findsNothing);
      },
    );

    testWidgets(
      'the my profile card has the photo in both modes @RED-03-ASM-07',
      (tester) async {
        for (final dark in [true, false]) {
          await mountProfile(tester, dark: dark);

          final card = tester.widget<MemberProfile>(find.byType(MemberProfile));
          expect(card.image, sportPhoto('Futbol'), reason: '$dark');
          expect(onCard(find.byType(Image)), findsOneWidget);
        }
      },
    );
  });

  group('venues', () {
    testWidgets('each venue card has the bib with its courts @RED-03-S4', (
      tester,
    ) async {
      await mountUser(
        tester,
        size: const Size(393, 1800),
        api: apiRoutes(
          venueRoutes(
            venues:
                '[$venueMoronWithSports, $venueHaedoWithoutCourts, '
                '${_venue('00000000-0000-7000-8000-000000000007', 'Sede Ituzaingó', 'Blas Parera 300', 12)}]',
          ),
        ),
      );

      final cards = find.byType(VenueCard);
      expect(cards, findsNWidgets(3));
      final bibs = <String>[];
      for (var i = 0; i < 3; i++) {
        final card = cards.at(i);
        final bib = find.descendant(of: card, matching: find.byType(GiantBib));
        expect(bib, findsOneWidget);
        final spaceCount = tester.widget<VenueCard>(card).venue.spaceCount;
        final text = spaceCount.toString().padLeft(2, '0');
        expect(tester.widget<GiantBib>(bib).text, text);
        final painter = tester
            .widgetList<CustomPaint>(
              find.descendant(of: bib, matching: find.byType(CustomPaint)),
            )
            .map((c) => c.painter)
            .whereType<BibPainter>()
            .single;
        expect(painter.text, text);
        bibs.add(text);
      }
      expect(bibs, ['02', '00', '12']);
    });
  });

  group('schedules', () {
    Future<void> openSchedule(WidgetTester tester, {String? grid}) => mountUser(
      tester,
      start:
          '/sedes/00000000-0000-7000-8000-000000000001/canchas/00000000-0000-7000-8000-000000000009',
      size: const Size(393, 2400),
      api: apiRoutes(venueRoutes(grid: grid)),
    );

    String stateOf(int hour) {
      final label = RegExp('^${hour.toString().padLeft(2, '0')} h ');
      return find.bySemanticsLabel(label).evaluate().isEmpty
          ? 'sin celda'
          : [
              for (final e in ['libre', 'ocupada', 'elegida'])
                if (find
                    .bySemanticsLabel('${hour.toString().padLeft(2, '0')} h $e')
                    .evaluate()
                    .isNotEmpty)
                  e,
            ].single;
    }

    testWidgets(
      'above the grid goes the day timeline with the state of each slot @RED-03-S5',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await openSchedule(tester);

        expect(find.byType(DayTimeline), findsOneWidget);
        expect(
          tester.getTopLeft(find.byType(DayTimeline)).dy,
          lessThan(tester.getTopLeft(find.text('08:00 – 09:00')).dy),
        );
        const taken = {9, 12, 16, 17, 21, 22};
        for (var h = 8; h < 23; h++) {
          final hour = h.toString().padLeft(2, '0');
          expect(find.byKey(ValueKey('franja-$hour')), findsOneWidget);
          expect(
            stateOf(h),
            taken.contains(h) ? 'ocupada' : 'libre',
            reason: '$hour h',
          );
        }
        expect(find.byKey(const ValueKey('franja-07')), findsNothing);
        expect(find.byKey(const ValueKey('franja-23')), findsNothing);
        semantics.dispose();
      },
    );

    testWidgets(
      'with two hours each hour is free if a free slot covers it and the selected one marks its two hours @RED-03-ASM-08',
      (tester) async {
        final semantics = tester.ensureSemantics();
        String slot(int h, bool free) =>
            '{"starts_at": "${h.toString().padLeft(2, '0')}:00", '
            '"ends_at": "${(h + 2).toString().padLeft(2, '0')}:00", '
            '"available": $free}';
        await openSchedule(
          tester,
          grid:
              '{"date": "2026-11-12", "today": "2026-11-12", "opens": true, '
              '"slots": [${slot(8, true)}, ${slot(9, false)}, '
              '${slot(10, false)}, ${slot(11, false)}, ${slot(12, true)}, '
              '${slot(13, false)}], "unavailable": 4}',
        );
        await tester.tap(find.bySemanticsLabel('Una hora más'));
        await tester.pumpAndSettle();

        // Hour 9 is free thanks to the 08:00 slot, even if the 09:00 one is not.
        expect(
          {for (var h = 8; h < 23; h++) h: stateOf(h)},
          {
            8: 'libre',
            9: 'libre',
            10: 'ocupada',
            11: 'ocupada',
            12: 'libre',
            13: 'libre',
            for (var h = 14; h < 23; h++) h: 'ocupada',
          },
        );

        await tester.tap(find.bySemanticsLabel('12:00 – 14:00'));
        await tester.pumpAndSettle();

        expect(
          {for (var h = 8; h < 15; h++) h: stateOf(h)},
          {
            8: 'libre',
            9: 'libre',
            10: 'ocupada',
            11: 'ocupada',
            12: 'elegida',
            13: 'elegida',
            14: 'ocupada',
          },
        );
        semantics.dispose();
      },
    );

    testWidgets(
      'with «No hay horarios disponibles» there is no day timeline @RED-03-ASM-08',
      (tester) async {
        await openSchedule(tester);
        expect(find.byType(DayTimeline), findsOneWidget);

        for (final grid in [
          gridJson(opens: false),
          gridJson(taken: {for (var h = 8; h < 23; h++) h}),
        ]) {
          await openSchedule(tester, grid: grid);

          expect(find.text('No hay horarios disponibles'), findsOneWidget);
          expect(find.byType(DayTimeline), findsNothing);
        }
      },
    );
  });

  group('login', () {
    testWidgets('the login brand has the decorative logo mark @RED-03-S6', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final session = Session(
        repository: SessionRepository(
          credentials: FakeCredentials(),
          api: fakeApi(status: 200, body: profileJson()),
        ),
      );
      final routes = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                LoginScreen(session: session, pending: PendingBooking()),
          ),
        ],
      );
      addTearDown(routes.dispose);
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp.router(theme: darkTheme, routerConfig: routes),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LogoMark), findsOneWidget);
      expect(tester.widget<LogoMark>(find.byType(LogoMark)).decorative, isTrue);
      expect(
        tester.getTopLeft(find.byType(LogoMark)).dy,
        lessThan(tester.getTopLeft(find.text('BIENVENIDO A')).dy),
      );
      expect(find.bySemanticsLabel('Club Nahuel Mosse'), findsOneWidget);
      semantics.dispose();
    });
  });
}

Future<void> _expectDieCutBetweenHeaderAndDetail(WidgetTester tester) async {
  final dieCut = find.descendant(
    of: find.byType(BookingCard),
    matching: find.byType(DieCut),
  );
  expect(dieCut, findsOneWidget);
  expect(tester.widget<DieCut>(dieCut).background, _dark.bgBase);
  final y = tester.getTopLeft(dieCut).dy;
  expect(
    tester.getTopLeft(find.text('Sede Morón · Av. Rivadavia 19850')).dy,
    lessThan(y),
  );
  expect(
    tester.getTopLeft(find.text('Moron_Rivadavia_19850_Futbol_F5_1')).dy,
    greaterThan(y),
  );
}
