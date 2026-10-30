import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/admin.dart';
import 'soporte/montar.dart';

const _english = [Locale('en', 'US')];
const _spanish = [Locale('es', 'AR')];

void main() {
  setUpAll(cargarFuentes);

  void device(WidgetTester tester, List<Locale> locales) {
    tester.platformDispatcher.localesTestValue = locales;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'the admin form validations the domain decides show in English and in Spanish @ENG-19-ASM-05',
    (tester) async {
      final semantics = tester.ensureSemantics();
      for (final (locales, save, messages, address) in [
        (
          _english,
          'SAVE VENUE',
          [
            'The name is required',
            'The address is required',
            'The opening time is required',
            'The closing time is required',
          ],
          'Write the street and number',
        ),
        (
          _spanish,
          'GUARDAR SEDE',
          [
            'El nombre es obligatorio',
            'La dirección es obligatoria',
            'El horario de apertura es obligatorio',
            'El horario de cierre es obligatorio',
          ],
          'Escribí la calle y la altura',
        ),
      ]) {
        device(tester, locales);
        await tester.pumpWidget(const SizedBox());
        await montarAdmin(
          tester,
          inicio: '/admin/sedes/nueva',
          api: apiRutas({'GET /venues': (200, '{"venues": []}')}),
        );
        await tap(tester, save);
        for (final message in messages) {
          expect(find.text(message), findsOneWidget, reason: message);
        }

        await tester.enterText(find.byType(EditableText).at(1), 'Calle');
        await tester.pumpAndSettle();
        await tap(tester, save);
        expect(find.text(address), findsOneWidget, reason: address);
      }
      semantics.dispose();
    },
  );
}
