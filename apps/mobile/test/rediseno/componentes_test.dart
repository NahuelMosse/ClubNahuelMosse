import 'dart:io';
import 'dart:typed_data';

import 'package:clubnahuelmosse/comun/dorsal.dart';
import 'package:clubnahuelmosse/comun/ficha_socio.dart';
import 'package:clubnahuelmosse/comun/isotipo.dart';
import 'package:clubnahuelmosse/comun/linea_del_dia.dart';
import 'package:clubnahuelmosse/comun/marcador.dart';
import 'package:clubnahuelmosse/comun/tile_deporte.dart';
import 'package:clubnahuelmosse/comun/troquel.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:clubnahuelmosse/tema/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soporte/montar.dart';

/// Un PNG de 1×1 transparente: la foto de prueba.
final _foto = MemoryImage(
  Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
);

const _p = Paleta.oscura;

Future<void> _montar(WidgetTester tester, Widget hijo) => montar(
  tester,
  Scaffold(body: Center(child: hijo)),
  tema: temaOscuro,
);

const _celdas = [
  CeldaMarcador(cifra: '04', rotulo: 'Sedes'),
  CeldaMarcador(cifra: '17', rotulo: 'Canchas'),
  CeldaMarcador(cifra: '23', rotulo: 'Libres hoy', destacada: true),
];

Color? _colorDeTexto(WidgetTester tester, String texto) =>
    tester.widget<Text>(find.text(texto)).style?.color;

void main() {
  testWidgets(
    'el isotipo se dibuja en su tamaño con el acento y se anuncia como el club @RED-02-S1',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await _montar(tester, const Isotipo(tamano: 48));

      expect(tester.getSize(find.byType(Isotipo)), const Size(48, 48));
      expect(find.bySemanticsLabel('Club Nahuel Mosse'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'el isotipo es un CustomPainter con el trazo del acento @RED-02-ASM-03',
    (tester) async {
      await _montar(tester, const Isotipo(decorativo: true));

      final pintor = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(Isotipo),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((c) => c.painter)
          .whereType<PintorIsotipo>()
          .single;
      expect(pintor.color, _p.accentBase);
      expect(tester.getSize(find.byType(Isotipo)), const Size(64, 64));
    },
  );

  testWidgets(
    'el marcador muestra cada celda con su cifra y su rótulo y destaca la elegida @RED-02-S2',
    (tester) async {
      await _montar(tester, const Marcador(celdas: _celdas));

      for (final (cifra, rotulo) in [
        ('04', 'SEDES'),
        ('17', 'CANCHAS'),
        ('23', 'LIBRES HOY'),
      ]) {
        expect(find.text(cifra), findsOneWidget);
        expect(find.text(rotulo), findsOneWidget);
        final estilo = tester.widget<Text>(find.text(cifra)).style;
        expect(estilo?.fontFamily, 'Archivo Black');
        expect(estilo?.fontSize, 28);
      }
      expect(_colorDeTexto(tester, '04'), _p.textOnMedia);
      expect(_colorDeTexto(tester, '23'), _p.accentOnMedia);

      final marcos = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(Marcador),
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
      expect(marcos.single.borderRadius, BorderRadius.circular(16));
    },
  );

  testWidgets(
    'el lector lee cada celda del marcador como cifra y rótulo @RED-02-S2',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await _montar(tester, const Marcador(celdas: _celdas));

      for (final etiqueta in ['04 sedes', '17 canchas', '23 libres hoy']) {
        expect(find.bySemanticsLabel(etiqueta), findsOneWidget);
      }
      semantica.dispose();
    },
  );

  testWidgets(
    'el tile de deporte muestra la foto, el emoji y el nombre y llama al tocarlo @RED-02-S3',
    (tester) async {
      var tocado = 0;
      await _montar(
        tester,
        TileDeporte(
          imagen: _foto,
          emoji: '⚽',
          nombre: 'Fútbol',
          alTocar: () => tocado++,
        ),
      );

      expect(find.text('⚽'), findsOneWidget);
      expect(find.text('Fútbol'), findsOneWidget);
      expect(_colorDeTexto(tester, 'Fútbol'), _p.textOnMedia);
      expect(
        find.descendant(
          of: find.byType(TileDeporte),
          matching: find.byWidgetPredicate(
            (w) => w is Image && w.image == _foto,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('ELEGIDO'), findsNothing);

      await tester.tap(find.byType(TileDeporte));
      expect(tocado, 1);
    },
  );

  testWidgets(
    'el tile elegido lleva el borde del acento y la etiqueta ELEGIDO @RED-02-S3',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await _montar(
        tester,
        TileDeporte(
          imagen: _foto,
          emoji: '🎾',
          nombre: 'Tenis',
          elegido: true,
          alTocar: () {},
        ),
      );

      expect(find.text('ELEGIDO'), findsOneWidget);
      final bordes = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(TileDeporte),
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
      expect(bordes, isNotEmpty);
      expect(
        tester.getSemantics(find.byType(TileDeporte)),
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
      semantica.dispose();
    },
  );

  test(
    'los componentes de comun reciben la foto por parámetro y no importan sedes @RED-02-ASM-01',
    () {
      for (final archivo in [
        'isotipo',
        'marcador',
        'tile_deporte',
        'ficha_socio',
        'linea_del_dia',
        'dorsal',
        'troquel',
      ]) {
        final codigo = File('lib/comun/$archivo.dart').readAsStringSync();
        expect(codigo, isNot(contains("import '../sedes")), reason: archivo);
      }
      for (final archivo in ['tile_deporte', 'ficha_socio']) {
        final codigo = File('lib/comun/$archivo.dart').readAsStringSync();
        expect(codigo, contains('ImageProvider'), reason: archivo);
      }
    },
  );

  testWidgets(
    'la ficha de socio muestra rótulo, isotipo, iniciales, nombre, correo y su marcador @RED-02-S4',
    (tester) async {
      await _montar(
        tester,
        FichaSocio(
          iniciales: 'NM',
          nombre: 'Nahuel Agustín Mosse',
          correo: 'nmosse@unimoron.edu.ar',
          imagen: _foto,
          estadisticas: const [
            CeldaMarcador(cifra: '12', rotulo: 'Partidos'),
            CeldaMarcador(cifra: '3', rotulo: 'Este mes', destacada: true),
          ],
        ),
      );

      expect(find.text('FICHA DE SOCIO'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FichaSocio),
          matching: find.byType(Isotipo),
        ),
        findsOneWidget,
      );
      expect(find.text('NM'), findsOneWidget);
      expect(_colorDeTexto(tester, 'NM'), _p.accentOn);
      expect(find.text('Nahuel Agustín Mosse'), findsOneWidget);
      expect(find.text('nmosse@unimoron.edu.ar'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FichaSocio),
          matching: find.byType(Marcador),
        ),
        findsOneWidget,
      );
      expect(find.text('PARTIDOS'), findsOneWidget);
    },
  );

  const franjas = [
    EstadoFranja.libre,
    EstadoFranja.libre,
    EstadoFranja.ocupada,
    EstadoFranja.elegida,
    EstadoFranja.libre,
  ];

  testWidgets(
    'la línea del día pinta una celda por hora con el color de su estado @RED-02-S5',
    (tester) async {
      await _montar(tester, const LineaDelDia(franjas: franjas, desde: 8));

      expect(find.text('TU DÍA EN LA CANCHA'), findsOneWidget);
      for (final leyenda in ['Libre', 'Ocupado', 'Elegido']) {
        expect(find.text(leyenda), findsOneWidget);
      }
      for (final hora in ['08', '09', '10', '11', '12']) {
        expect(find.byKey(ValueKey('franja-$hora')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('franja-13')), findsNothing);
      expect(find.text('08'), findsOneWidget);
    },
  );

  testWidgets(
    'el lector lee cada hora de la línea del día con su estado @RED-02-S5',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await _montar(tester, const LineaDelDia(franjas: franjas, desde: 8));

      for (final etiqueta in [
        '08 h libre',
        '09 h libre',
        '10 h ocupada',
        '11 h elegida',
        '12 h libre',
      ]) {
        expect(find.bySemanticsLabel(etiqueta), findsOneWidget);
      }
      semantica.dispose();
    },
  );

  testWidgets(
    'libre es accentMuted, ocupado stateDisabled y elegido accentBase @RED-02-ASM-02',
    (tester) async {
      await _montar(tester, const LineaDelDia(franjas: franjas, desde: 8));

      Color? color(String hora) {
        final caja = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byKey(ValueKey('franja-$hora')),
            matching: find.byType(DecoratedBox),
          ),
        );
        return (caja.decoration as BoxDecoration).color;
      }

      expect(color('08'), _p.accentMuted);
      expect(color('10'), _p.stateDisabled);
      expect(color('11'), _p.accentBase);
    },
  );

  testWidgets(
    'el dorsal se dibuja sólo con trazo y el lector no lo lee @RED-02-S6',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await _montar(
        tester,
        DorsalGigante(texto: '07', tamano: 92, color: _p.textOnMedia),
      );

      expect(find.text('07'), findsNothing);
      expect(find.bySemanticsLabel('07'), findsNothing);
      final pintor = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(DorsalGigante),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((c) => c.painter)
          .whereType<PintorDorsal>()
          .single;
      expect(pintor.texto, '07');
      expect(pintor.color, _p.textOnMedia);
      expect(pintor.tamano, 92);
      semantica.dispose();
    },
  );

  testWidgets(
    'el troquel dibuja la línea punteada y las dos muescas y el lector no lo lee @RED-02-S7',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await _montar(tester, Troquel(fondo: _p.bgBase));

      final pintor = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(Troquel),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((c) => c.painter)
          .whereType<PintorTroquel>()
          .single;
      expect(pintor.linea, _p.borderControl);
      expect(pintor.fondo, _p.bgBase);
      expect(pintor.diametroMuesca, 16);
      expect(tester.getSemantics(find.byType(Troquel)).label, isEmpty);
      semantica.dispose();
    },
  );
}
