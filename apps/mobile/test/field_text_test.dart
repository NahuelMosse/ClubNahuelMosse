import 'package:clubnahuelmosse/common/text_field.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<TextEditingController> mount(
    WidgetTester tester, {
    String? error,
  }) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        theme: darkTheme,
        home: Scaffold(
          body: FormTextField(
            label: 'NOMBRE',
            semanticLabel: 'Nombre',
            controller: controller,
            placeholder: 'Tu nombre',
            error: error,
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('the field is found and filled by its accessible name', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = await mount(tester);

    expect(find.bySemanticsLabel('Nombre'), findsOneWidget);
    await tester.enterText(find.bySemanticsLabel('Nombre'), 'Ana');
    expect(controller.text, 'Ana');
    expect(find.bySemanticsLabel('Nombre'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the error shows below the field', (tester) async {
    await mount(tester, error: 'El nombre es obligatorio');
    expect(find.text('El nombre es obligatorio'), findsOneWidget);
  });
}
