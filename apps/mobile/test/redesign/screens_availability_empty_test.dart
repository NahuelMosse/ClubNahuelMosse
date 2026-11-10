import 'package:clubnahuelmosse/common/day_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/mount.dart';
import '../support/fixed_clock.dart';
import '../support/user.dart';

/// Cada grilla se monta en su propio test: montar la app dos veces en el mismo test reusa la
/// API del primer montaje.
Future<void> _abrirHorarios(
  WidgetTester tester,
  String grilla,
) => mountUser(
  tester,
  inicio:
      '/sedes/00000000-0000-7000-8000-000000000001/canchas/00000000-0000-7000-8000-000000000009',
  tamano: const Size(393, 2400),
  api: apiRoutes(venueRoutes(grilla: grilla)),
);

void main() {
  testWidgets(
    'con «No hay horarios disponibles» no va la línea del día @RED-03-ASM-08',
    (tester) async {
      await _abrirHorarios(tester, gridJson(abre: false));

      expect(find.text('No hay horarios disponibles'), findsOneWidget);
      expect(find.byType(DayTimeline), findsNothing);
    },
  );

  testWidgets(
    'con todas las franjas ocupadas tampoco va la línea del día @RED-03-ASM-08',
    (tester) async {
      await _abrirHorarios(
        tester,
        gridJson(ocupadas: {for (var h = 8; h < 23; h++) h}),
      );

      expect(find.text('No hay horarios disponibles'), findsOneWidget);
      expect(find.byType(DayTimeline), findsNothing);
    },
  );
}
