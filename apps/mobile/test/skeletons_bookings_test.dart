import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/clock.dart';
import 'package:clubnahuelmosse/common/day_timeline.dart';
import 'package:clubnahuelmosse/common/selector.dart';
import 'package:clubnahuelmosse/common/text_field.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/availability_cover.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/availability_skeleton.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/booking_card.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/booking_card_skeleton.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/date_strip.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/search_time_range.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/selectable_frame.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/slot_card.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/space_search_skeleton.dart';
import 'package:clubnahuelmosse/features/venues/presentation/space_card.dart';
import 'package:clubnahuelmosse/features/venues/presentation/space_card_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mis_reservas_test.dart' show reservaJson;
import 'soporte/admin.dart';
import 'soporte/held_api.dart';
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

const _moron = '00000000-0000-7000-8000-000000000001';
const _f5 = '00000000-0000-7000-8000-000000000009';
const _f5Techada =
    '{"id": "00000000-0000-7000-8000-000000000011", "name": "Moron_Rivadavia_19850_Futbol_F5_2", "venue_id": "$_moron", '
    '"venue": "Sede Morón", "sport": "Futbol", "kind": "F5", "number": 2, '
    '"covered": true, "lit": true, "price_per_hour": 43000}';
const _gridBlocks = 12;

/// Mounts the app in 393x852 on [route] with every request held.
Future<HeldApi> _mount(
  WidgetTester tester,
  String route, {
  Map<String, (int, String)> extra = const {},
}) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await cargarFuentes();
  final held = HeldApi({
    ...rutasDeSedes(espacios: '[$espacioF5Json, $_f5Techada]'),
    ...extra,
  });
  await tester.pumpWidget(
    App(
      api: held.client,
      session: SesionFalsa(perfilUsuario),
      appearance: Appearance.inMemory(dark: true),
      initialLocation: route,
    ),
  );
  await tester.pump();
  await tester.pump();
  return held;
}

Rect _rect(Finder finder) {
  final box = finder.evaluate().first.renderObject! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// The block nearest to [real] by its top left corner, checked against it.
void _expectBlockAt(List<Rect> blocks, Rect real, String reason) {
  final nearest = blocks.reduce(
    (a, b) =>
        (a.left - real.left).abs() + (a.top - real.top).abs() <=
            (b.left - real.left).abs() + (b.top - real.top).abs()
        ? a
        : b,
  );
  expectSameBox(nearest, real, reason: reason);
}

/// A block that ends where the real field does, with the same horizontal edges.
void _expectBoxEndsAt(
  List<Rect> blocks,
  Rect real,
  String reason, {
  bool left = true,
  bool right = true,
}) {
  final ends = blocks.where((b) => (b.bottom - real.bottom).abs() <= 1);
  expect(
    ends.any(
      (b) =>
          (!left || (b.left - real.left).abs() <= 1) &&
          (!right || (b.right - real.right).abs() <= 1),
    ),
    isTrue,
    reason:
        '$reason: a block ends at ${real.bottom} between ${real.left} '
        'and ${real.right}; blocks: $blocks',
  );
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 2));
}

Future<void> _choose(WidgetTester tester, String field, String option) async {
  await tester.ensureVisible(find.bySemanticsLabel(field));
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel(field));
  await tester.pumpAndSettle();
  final button = find.descendant(
    of: find.byType(Dialog),
    matching: find.text(option),
  );
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

String _nextWorkingDay() {
  var d = clubNow().add(const Duration(days: 1));
  while (d.weekday == DateTime.sunday) {
    d = d.add(const Duration(days: 1));
  }
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)} / ${two(d.month)} / ${d.year}';
}

void main() {
  testWidgets(
    'Horarios carga con la forma de su portada, días y grilla @VIS-03-S1',
    (tester) async {
      final held = await _mount(tester, '/sedes/$_moron/canchas/$_f5');
      expect(find.byType(AvailabilitySkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final blocks = skeletonRects(tester);

      held.release();
      await tester.pumpAndSettle();
      expect(find.byType(AvailabilitySkeleton), findsNothing);
      expectSameBox(
        blocks.first,
        _rect(find.byType(AvailabilityCover)),
        reason: 'cover',
      );
      final day = find.descendant(
        of: find.byType(DateStrip),
        matching: find.byType(SelectableFrame),
      );
      _expectBlockAt(blocks, _rect(day.first), 'first day');
      final grid = blocks.sublist(blocks.length - _gridBlocks);
      for (final i in [0, 1, 6, 10, 11]) {
        expectSameBox(
          grid[i],
          _rect(find.byType(SlotCard).at(i)),
          reason: 'slot $i',
        );
      }
      await _drain(tester);
    },
  );

  testWidgets(
    'Horarios al cambiar el día carga la grilla alineada con sus columnas y filas @VIS-03-S1 @assumption:VIS-03-ASM-01',
    (tester) async {
      final held = await _mount(tester, '/sedes/$_moron/canchas/$_f5');
      held.release();
      await tester.pumpAndSettle();
      final slots = [
        for (var i = 0; i < _gridBlocks; i++)
          _rect(find.byType(SlotCard).at(i)),
      ];
      final line = _rect(find.byType(DayTimeline));
      held.holdAgain();
      await tester.tap(
        find
            .descendant(
              of: find.byType(DateStrip),
              matching: find.byType(SelectableFrame),
            )
            .at(1),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(SlotCard), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final blocks = skeletonRects(tester);
      expect(blocks, hasLength(_gridBlocks + 1));
      expectSameBox(blocks.first, line, reason: 'day line');
      for (var i = 0; i < _gridBlocks; i++) {
        expectSameBox(blocks[i + 1], slots[i], reason: 'slot $i');
      }

      held.release();
      await tester.pumpAndSettle();
      expect(find.byType(SlotCard), findsWidgets);
      await _drain(tester);
    },
  );

  testWidgets('Buscar cancha carga con la forma de su formulario @VIS-03-S1', (
    tester,
  ) async {
    final held = await _mount(tester, '/inicio/buscar');
    expect(find.byType(SpaceSearchSkeleton), findsOneWidget);
    expect(find.text('Consultar canchas'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final blocks = skeletonRects(tester);

    held.release();
    await tester.pumpAndSettle();
    expect(find.byType(SpaceSearchSkeleton), findsNothing);
    for (var i = 0; i < 3; i++) {
      final field = _rect(find.byType(SelectorField).at(i));
      _expectBoxEndsAt(blocks, field, 'field $i');
      expect(
        blocks.any((b) => (b.top - field.top).abs() <= 1 && b.height <= 20),
        isTrue,
        reason: 'label bar of field $i at ${field.top}; blocks: $blocks',
      );
    }
    _expectBoxEndsAt(blocks, _rect(find.byType(FormTextField)), 'date');
    final range = _rect(find.byType(SearchTimeRange));
    _expectBoxEndsAt(blocks, range, 'from', right: false);
    _expectBoxEndsAt(blocks, range, 'to', left: false);
    await _drain(tester);
  });

  testWidgets(
    'Buscar cancha carga los resultados con la forma de su tarjeta @VIS-03-S1',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final held = await _mount(
        tester,
        '/inicio/buscar',
        extra: {
          'GET /spaces/available': (
            200,
            '{"spaces": [$espacioF5Json, $_f5Techada]}',
          ),
        },
      );
      held.release();
      await tester.pumpAndSettle();
      await _choose(tester, 'Sede', 'Sede Morón');
      await _choose(tester, 'Deporte', 'Fútbol');
      await tester.enterText(
        find.descendant(
          of: find.bySemanticsLabel('Fecha'),
          matching: find.byType(EditableText),
        ),
        _nextWorkingDay(),
      );
      await tester.pumpAndSettle();
      held.holdAgain();
      await tester.tap(find.text('CONSULTAR'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SpaceCardSkeleton), findsWidgets);
      expect(find.byType(SelectorField), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final card = _rect(find.byType(SpaceCardSkeleton).first);

      held.release();
      await tester.pumpAndSettle();
      expect(find.byType(SpaceCardSkeleton), findsNothing);
      expectSameBox(card, _rect(find.byType(SpaceCard).first), reason: 'card');
      await _drain(tester);
      semantics.dispose();
    },
  );

  testWidgets(
    'Mis reservas carga con la forma de la tarjeta de reserva @VIS-03-S1',
    (tester) async {
      final second = reservaJson(id: '00000000-0000-7000-8000-000000000002');
      final held = await _mount(
        tester,
        '/bookings',
        extra: {
          'GET /bookings': (200, '{"bookings": [${reservaJson()}, $second]}'),
        },
      );
      expect(find.byType(BookingCardSkeleton), findsAtLeastNWidgets(2));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final cards = [
        _rect(find.byType(BookingCardSkeleton).at(0)),
        _rect(find.byType(BookingCardSkeleton).at(1)),
      ];

      held.release();
      await tester.pumpAndSettle();
      expect(find.byType(BookingCardSkeleton), findsNothing);
      for (var i = 0; i < 2; i++) {
        expectSameBox(
          cards[i],
          _rect(find.byType(BookingCard).at(i)),
          reason: 'booking $i',
        );
      }
      await _drain(tester);
    },
  );
}
