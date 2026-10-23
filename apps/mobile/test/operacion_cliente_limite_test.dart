// ignore_for_file: unawaited_futures
import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'el límite por defecto se agota justo a los 60 s, no un segundo después @REV-02-S8 @assumption:REV-02-ASM-06',
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
      ).get('/lento').then((_) {}, onError: (Object e) { error = e; });

      await tester.pump(const Duration(milliseconds: 59500));
      expect(error, isNull);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(error, isA<ServidorSinRespuesta>());
      await tester.pump(const Duration(seconds: 40));
    },
  );
}
