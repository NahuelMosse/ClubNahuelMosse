import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/comun/dialogo_error.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/montar.dart';

void main() {
  setUpAll(cargarFuentes);

  testWidgets(
    'la app muestra el 429 con el mensaje del servidor en su diálogo de error @REV-01-S6 @assumption:REV-01-ASM-14',
    (tester) async {
      final api = ClienteApi(
        'http://api.falsa',
        cliente: MockClient(
          (_) async => http.Response(
            '{"mensaje": "Hiciste demasiados intentos. Esperá un minuto y volvé a probar."}',
            429,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      await montar(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  try {
                    await api.post('/recuperacion', {'correo': 'a@b.com'});
                  } on Exception catch (e) {
                    if (context.mounted) await mostrarErrorDeRed(context, e);
                  }
                },
                child: const Text('ABRIR'),
              ),
            ),
          ),
        ),
        tema: temaOscuro,
        tamano: const Size(360, 800),
      );

      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Hiciste demasiados intentos. Esperá un minuto y volvé a probar.',
        ),
        findsOneWidget,
      );
    },
  );
}
