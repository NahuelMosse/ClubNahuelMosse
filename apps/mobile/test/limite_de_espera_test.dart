// ignore_for_file: unawaited_futures
import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'a los 30 s sin respuesta la app avisa que el servidor no responde @SIM-01-S4 @assumption:SIM-01-ASM-04',
    (tester) async {
      Object? error;
      ClienteApi(
            'http://api.falsa',
            cliente: MockClient(
              (_) => Future.delayed(
                const Duration(seconds: 90),
                () => http.Response('{}', 200),
              ),
            ),
          )
          .get('/espacios')
          .then(
            (_) {},
            onError: (Object e) {
              error = e;
            },
          );

      await tester.pump(const Duration(milliseconds: 29500));
      expect(error, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(error, isA<ServidorSinRespuesta>());
      expect((error! as ServidorSinRespuesta).codigo, 0);
      await tester.pump(const Duration(seconds: 90));
    },
  );
}
