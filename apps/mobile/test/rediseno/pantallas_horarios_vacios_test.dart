import 'package:clubnahuelmosse/comun/linea_del_dia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';
import '../soporte/usuario.dart';

/// Cada grilla se monta en su propio test: montar la app dos veces en el mismo test reusa la
/// API del primer montaje.
Future<void> _abrirHorarios(WidgetTester tester, String grilla) =>
    montarUsuario(
      tester,
      inicio: '/sedes/1/canchas/9',
      tamano: const Size(393, 2400),
      api: apiRutas(rutasDeSedes(grilla: grilla)),
    );

void main() {
  testWidgets(
    'con «No hay horarios disponibles» no va la línea del día @RED-03-ASM-08',
    (tester) async {
      await _abrirHorarios(tester, grillaJson(abre: false));

      expect(find.text('No hay horarios disponibles'), findsOneWidget);
      expect(find.byType(LineaDelDia), findsNothing);
    },
  );

  testWidgets(
    'con todas las franjas ocupadas tampoco va la línea del día @RED-03-ASM-08',
    (tester) async {
      await _abrirHorarios(
        tester,
        grillaJson(ocupadas: {for (var h = 8; h < 23; h++) h}),
      );

      expect(find.text('No hay horarios disponibles'), findsOneWidget);
      expect(find.byType(LineaDelDia), findsNothing);
    },
  );
}
