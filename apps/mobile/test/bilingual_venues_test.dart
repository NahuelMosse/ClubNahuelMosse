import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';
import 'soporte/usuario.dart';

const _english = [Locale('en', 'US')];

void main() {
  setUpAll(cargarFuentes);

  testWidgets('venues and their spaces show English @ENG-19-S1', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = _english;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await montarUsuario(
      tester,
      inicio: '/sedes',
      api: apiRutas(rutasDeSedes()),
    );
    void expectTexts(Iterable<String> texts) {
      for (final text in texts) {
        expect(find.text(text), findsWidgets, reason: text);
      }
    }

    expectTexts([
      'Venues',
      '2 venues · 2 courts · each with its own hours',
      'Monday to Sunday · 08:00 to 23:00',
      'See courts',
    ]);
    expect(find.text('Sedes'), findsNothing);

    // The venue name is drawn in capitals on the cover.
    final venue = find.text('SEDE MORÓN');
    await tester.ensureVisible(venue);
    await tester.pumpAndSettle();
    await tester.tap(venue);
    await tester.pumpAndSettle();
    expectTexts([
      'All venues',
      'SPORT',
      '2 COURTS · ALL SPORTS',
      'Open air',
      'Lit',
      'Unlit',
      '/ HOUR',
      'SEE TIMES / BOOK',
      'Fútbol 5 · Open air · with lighting',
    ]);
    expect(
      find.textContaining('Fútbol 5 · Open air · with lighting'),
      findsOne,
    );
  });
}
