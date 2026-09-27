import 'package:clubnahuelmosse/comun/campo_texto.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<TextEditingController> montar(
    WidgetTester tester, {
    String? error,
  }) async {
    final controlador = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        theme: temaOscuro,
        home: Scaffold(
          body: CampoTexto(
            etiqueta: 'NOMBRE',
            etiquetaAccesible: 'Nombre',
            controlador: controlador,
            placeholder: 'Tu nombre',
            error: error,
          ),
        ),
      ),
    );
    return controlador;
  }

  testWidgets('el campo se encuentra y se completa por su nombre accesible', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final controlador = await montar(tester);

    expect(find.bySemanticsLabel('Nombre'), findsOneWidget);
    await tester.enterText(find.bySemanticsLabel('Nombre'), 'Ana');
    expect(controlador.text, 'Ana');
    expect(find.bySemanticsLabel('Nombre'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('el error se muestra debajo del campo', (tester) async {
    await montar(tester, error: 'El nombre es obligatorio');
    expect(find.text('El nombre es obligatorio'), findsOneWidget);
  });
}
