// ignore_for_file: unawaited_futures
import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  ClienteApi con(Map<String, Duration> demoras) => ClienteApi(
    'http://api.falsa',
    cliente: MockClient(
      (pedido) => Future.delayed(
        demoras[pedido.url.path]!,
        () => http.Response('{}', 200),
      ),
    ),
  );

  testWidgets(
    'el límite por defecto es de 60 s y se agota con ServidorSinRespuesta @REV-02-S8 @assumption:REV-02-ASM-06',
    (tester) async {
      Object? error;
      con({'/lento': const Duration(seconds: 90)})
          .get('/lento')
          .then((_) {}, onError: (Object e) { error = e; });

      await tester.pump(const Duration(seconds: 59));
      expect(error, isNull);

      await tester.pump(const Duration(seconds: 2));
      expect(error, isA<ServidorSinRespuesta>());
      expect((error! as ServidorSinRespuesta).codigo, 0);
      await tester.pump(const Duration(seconds: 40));
    },
  );

  testWidgets(
    'despertando se enciende pasados 5 s y se apaga al terminar el pedido @REV-02-S8 @assumption:REV-02-ASM-11',
    (tester) async {
      final api = con({'/lento': const Duration(seconds: 30)});
      expect(api.despertando.value, isFalse);
      api.get('/lento');

      await tester.pump(const Duration(milliseconds: 4900));
      expect(api.despertando.value, isFalse);
      await tester.pump(const Duration(milliseconds: 200));
      expect(api.despertando.value, isTrue);

      await tester.pump(const Duration(seconds: 30));
      expect(api.despertando.value, isFalse);
    },
  );

  testWidgets(
    'despertando sigue encendido mientras quede un pedido lento @REV-02-S8 @assumption:REV-02-ASM-11',
    (tester) async {
      final api = con({
        '/a': const Duration(seconds: 20),
        '/b': const Duration(seconds: 40),
      });
      api.get('/a');
      api.get('/b');

      await tester.pump(const Duration(seconds: 25));
      expect(api.despertando.value, isTrue);

      await tester.pump(const Duration(seconds: 20));
      expect(api.despertando.value, isFalse);
    },
  );

  testWidgets(
    'un pedido rápido no cuenta como lento para despertando @REV-02-S8 @assumption:REV-02-ASM-11',
    (tester) async {
      final api = con({
        '/rapido': const Duration(seconds: 1),
        '/lento': const Duration(seconds: 30),
      });
      api.get('/rapido');
      await tester.pump(const Duration(seconds: 2));
      expect(api.despertando.value, isFalse);

      api.get('/lento');
      await tester.pump(const Duration(seconds: 6));
      expect(api.despertando.value, isTrue);
      await tester.pump(const Duration(seconds: 30));
      expect(api.despertando.value, isFalse);
    },
  );
}
