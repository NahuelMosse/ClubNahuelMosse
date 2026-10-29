import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/error_dialog.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
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
      final api = ApiClient(
        'http://api.falsa',
        cliente: MockClient(
          (_) async => http.Response(
            '{"message": "Hiciste demasiados intentos. Esperá un minuto y volvé a probar."}',
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
                    await api.post('/password-recovery', {'email': 'a@b.com'});
                  } on Exception catch (e) {
                    if (context.mounted) await showNetworkError(context, e);
                  }
                },
                child: const Text('ABRIR'),
              ),
            ),
          ),
        ),
        tema: darkTheme,
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
