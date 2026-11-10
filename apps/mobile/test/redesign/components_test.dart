import 'dart:io';
import 'dart:typed_data';

import 'package:clubnahuelmosse/common/bib.dart';
import 'package:clubnahuelmosse/common/day_timeline.dart';
import 'package:clubnahuelmosse/common/die_cut.dart';
import 'package:clubnahuelmosse/common/logo_mark.dart';
import 'package:clubnahuelmosse/common/marker.dart';
import 'package:clubnahuelmosse/common/member_profile.dart';
import 'package:clubnahuelmosse/common/sport_tile.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mount.dart';

/// A transparent 1×1 PNG: the test photo.
final _photo = MemoryImage(
  Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
);

const _p = Palette.dark;

Future<void> _mount(WidgetTester tester, Widget child) => mountScreen(
  tester,
  Scaffold(body: Center(child: child)),
  theme: darkTheme,
);

const _cells = [
  MarkerCell(figure: '04', label: 'Sedes'),
  MarkerCell(figure: '17', label: 'Canchas'),
  MarkerCell(figure: '23', label: 'Libres hoy', highlighted: true),
];

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets(
    'the logo mark is drawn at its size with the accent and is announced as the club @RED-02-S1',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _mount(tester, const LogoMark(size: 48));

      expect(tester.getSize(find.byType(LogoMark)), const Size(48, 48));
      expect(find.bySemanticsLabel('Club Nahuel Mosse'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'the logo mark is a CustomPainter with the accent stroke @RED-02-ASM-03',
    (tester) async {
      await _mount(tester, const LogoMark(decorative: true));

      final painter = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(LogoMark),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((c) => c.painter)
          .whereType<LogoMarkPainter>()
          .single;
      expect(painter.color, _p.accentBase);
      expect(tester.getSize(find.byType(LogoMark)), const Size(64, 64));
    },
  );

  testWidgets(
    'the marker shows each cell with its figure and its label and highlights the selected one @RED-02-S2',
    (tester) async {
      await _mount(tester, const AppMarker(cells: _cells));

      for (final (figure, label) in [
        ('04', 'SEDES'),
        ('17', 'CANCHAS'),
        ('23', 'LIBRES HOY'),
      ]) {
        expect(find.text(figure), findsOneWidget);
        expect(find.text(label), findsOneWidget);
        final style = tester.widget<Text>(find.text(figure)).style;
        expect(style?.fontFamily, 'Archivo Black');
        expect(style?.fontSize, 28);
      }
      expect(_textColor(tester, '04'), _p.textOnMedia);
      expect(_textColor(tester, '23'), _p.accentOnMedia);

      final frames = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(AppMarker),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .where(
            (d) =>
                d.border is Border &&
                (d.border! as Border).top.color == _p.accentBase,
          );
      expect(frames.single.borderRadius, BorderRadius.circular(16));
    },
  );

  testWidgets(
    'the screen reader reads each marker cell as figure and label @RED-02-S2',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _mount(tester, const AppMarker(cells: _cells));

      for (final label in ['04 sedes', '17 canchas', '23 libres hoy']) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
      semantics.dispose();
    },
  );

  testWidgets(
    'the sport tile shows the photo, the emoji and the name and calls back on tap @RED-02-S3',
    (tester) async {
      var tapped = 0;
      await _mount(
        tester,
        SportTile(
          image: _photo,
          emoji: '⚽',
          name: 'Fútbol',
          onTap: () => tapped++,
        ),
      );

      expect(find.text('⚽'), findsOneWidget);
      expect(find.text('Fútbol'), findsOneWidget);
      expect(_textColor(tester, 'Fútbol'), _p.textOnMedia);
      expect(
        find.descendant(
          of: find.byType(SportTile),
          matching: find.byWidgetPredicate(
            (w) => w is Image && w.image == _photo,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('ELEGIDO'), findsNothing);

      await tester.tap(find.byType(SportTile));
      expect(tapped, 1);
    },
  );

  testWidgets(
    'the selected tile has the accent border and the «ELEGIDO» label @RED-02-S3',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _mount(
        tester,
        SportTile(
          image: _photo,
          emoji: '🎾',
          name: 'Tenis',
          selected: true,
          onTap: () {},
        ),
      );

      expect(find.text('ELEGIDO'), findsOneWidget);
      final borders = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(SportTile),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .where(
            (d) =>
                d.border is Border &&
                (d.border! as Border).top.color == _p.accentBase,
          );
      expect(borders, isNotEmpty);
      expect(
        tester.getSemantics(find.byType(SportTile)),
        matchesSemantics(
          label: 'Tenis',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
        ),
      );
      semantics.dispose();
    },
  );

  test(
    'the common components receive the photo as a parameter and do not import venues @RED-02-ASM-01',
    () {
      for (final file in [
        'logo_mark',
        'marker',
        'sport_tile',
        'member_profile',
        'day_timeline',
        'bib',
        'die_cut',
      ]) {
        final code = File('lib/common/$file.dart').readAsStringSync();
        expect(code, isNot(contains("import '../sedes")), reason: file);
      }
      for (final file in ['sport_tile', 'member_profile']) {
        final code = File('lib/common/$file.dart').readAsStringSync();
        expect(code, contains('ImageProvider'), reason: file);
      }
    },
  );

  testWidgets(
    'the member card shows label, logo mark, initials, name, email and its marker @RED-02-S4',
    (tester) async {
      await _mount(
        tester,
        MemberProfile(
          initials: 'NM',
          name: 'Nahuel Agustín Mosse',
          email: 'nmosse@unimoron.edu.ar',
          image: _photo,
          stats: const [
            MarkerCell(figure: '12', label: 'Partidos'),
            MarkerCell(figure: '3', label: 'Este mes', highlighted: true),
          ],
        ),
      );

      expect(find.text('FICHA DE SOCIO'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MemberProfile),
          matching: find.byType(LogoMark),
        ),
        findsOneWidget,
      );
      expect(find.text('NM'), findsOneWidget);
      expect(_textColor(tester, 'NM'), _p.accentOn);
      expect(find.text('Nahuel Agustín Mosse'), findsOneWidget);
      expect(find.text('nmosse@unimoron.edu.ar'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MemberProfile),
          matching: find.byType(AppMarker),
        ),
        findsOneWidget,
      );
      expect(find.text('PARTIDOS'), findsOneWidget);
    },
  );

  const slots = [
    SlotState.free,
    SlotState.free,
    SlotState.taken,
    SlotState.chosen,
    SlotState.free,
  ];

  testWidgets(
    'the day timeline paints one cell per hour with the color of its state @RED-02-S5',
    (tester) async {
      await _mount(tester, const DayTimeline(slots: slots, from: 8));

      expect(find.text('TU DÍA EN LA CANCHA'), findsOneWidget);
      for (final legend in ['Libre', 'Ocupado', 'Elegido']) {
        expect(find.text(legend), findsOneWidget);
      }
      for (final hour in ['08', '09', '10', '11', '12']) {
        expect(find.byKey(ValueKey('franja-$hour')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('franja-13')), findsNothing);
      expect(find.text('08'), findsOneWidget);
    },
  );

  testWidgets(
    'the screen reader reads each hour of the day timeline with its state @RED-02-S5',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _mount(tester, const DayTimeline(slots: slots, from: 8));

      for (final label in [
        '08 h libre',
        '09 h libre',
        '10 h ocupada',
        '11 h elegida',
        '12 h libre',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
      semantics.dispose();
    },
  );

  testWidgets(
    'free is accentMuted, taken stateDisabled and selected accentBase @RED-02-ASM-02',
    (tester) async {
      await _mount(tester, const DayTimeline(slots: slots, from: 8));

      Color? color(String hour) {
        final box = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byKey(ValueKey('franja-$hour')),
            matching: find.byType(DecoratedBox),
          ),
        );
        return (box.decoration as BoxDecoration).color;
      }

      expect(color('08'), _p.accentMuted);
      expect(color('10'), _p.stateDisabled);
      expect(color('11'), _p.accentBase);
    },
  );

  testWidgets(
    'the bib is drawn with stroke only and the screen reader does not read it @RED-02-S6',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _mount(
        tester,
        GiantBib(text: '07', size: 92, color: _p.textOnMedia),
      );

      expect(find.text('07'), findsNothing);
      expect(find.bySemanticsLabel('07'), findsNothing);
      final painter = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(GiantBib),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((c) => c.painter)
          .whereType<BibPainter>()
          .single;
      expect(painter.text, '07');
      expect(painter.color, _p.textOnMedia);
      expect(painter.size, 92);
      semantics.dispose();
    },
  );

  testWidgets(
    'the die-cut draws the dotted line and the two notches and the screen reader does not read it @RED-02-S7',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _mount(tester, DieCut(background: _p.bgBase));

      final painter = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(DieCut),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((c) => c.painter)
          .whereType<DieCutPainter>()
          .single;
      expect(painter.line, _p.borderControl);
      expect(painter.background, _p.bgBase);
      expect(painter.notchDiameter, 16);
      expect(tester.getSemantics(find.byType(DieCut)).label, isEmpty);
      semantics.dispose();
    },
  );
}
