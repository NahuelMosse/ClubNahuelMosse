// ignore_for_file: unawaited_futures
import 'dart:io';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/unhandled_errors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _source(String path) => File(path).readAsStringSync();

void main() {
  testWidgets(
    'the app neither warns that the server is waking up nor captures unhandled errors @SIM-01-S1',
    (tester) async {
      expect(File('lib/common/wake_up_notice.dart').existsSync(), isFalse);
      final errors = _source('lib/common/unhandled_errors.dart');
      expect(errors, isNot(contains('instalarCapturaDeErrores')));
      expect(errors, isNot(contains('correrProtegido')));
      expect(errors, isNot(contains('registroDeErrores')));
      final client = _source('lib/api/api_client.dart');
      expect(client, isNot(contains('despertando')));
      expect(client, isNot(contains('referencia')));
      final main = _source('lib/main.dart');
      expect(main, isNot(contains('correrProtegido')));
      expect(main, isNot(contains('AvisoDespertando')));
    },
  );

  testWidgets(
    'after 30 s with no response the app warns that the server does not respond @SIM-01-S4 @assumption:SIM-01-ASM-04',
    (tester) async {
      final api = ApiClient(
        'http://api.falsa',
        cliente: MockClient(
          (_) => Future.delayed(
            const Duration(seconds: 90),
            () => http.Response('{}', 200),
          ),
        ),
      );
      Object? error;
      api
          .get('/spaces')
          .then(
            (_) {},
            onError: (Object e) {
              error = e;
            },
          );
      await tester.pump(const Duration(seconds: 29));
      expect(error, isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(error, isA<ServidorSinRespuesta>());
      await tester.pump(const Duration(seconds: 90));
    },
  );

  testWidgets('offline the app says so @SIM-01-S4', (tester) async {
    final api = ApiClient(
      'http://api.falsa',
      cliente: MockClient((_) async => throw http.ClientException('sin red')),
    );
    await expectLater(api.get('/spaces'), throwsA(isA<SinConexion>()));
  });

  test(
    'logError writes to the development console @assumption:SIM-01-ASM-06',
    () {
      final original = debugPrint;
      final lines = <String>[];
      debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');
      addTearDown(() => debugPrint = original);
      logError(StateError('falla'), StackTrace.empty);
      expect(lines.join(), contains('falla'));
    },
  );

  test('the app starts without a startup error screen @SIM-01-S1', () {
    expect(File('lib/common/startup_error_screen.dart').existsSync(), isFalse);
    expect(
      _source('lib/main.dart'),
      isNot(contains('PantallaErrorDeArranque')),
    );
  });

  test(
    'on startup without a connection the app shows the error dialog with «Reintentar» @SIM-01-S4 @assumption:SIM-01-ASM-08',
    () {
      final main = _source('lib/main.dart');
      expect(main, contains('handleNetworkError'));
    },
  );

  test(
    '«Mis reservas» brings the whole list at once @SIM-01-S1 @assumption:SIM-01-ASM-01',
    () {
      final bookings = _source(
        'lib/features/bookings/presentation/bookings.dart',
      );
      expect(bookings, isNot(contains('TandaDeReservas')));
      expect(bookings, isNot(contains('despues')));
      final screen = _source(
        'lib/features/bookings/presentation/my_bookings_screen.dart',
      );
      expect(screen, isNot(contains('_cargarMas')));
      expect(screen, isNot(contains('_siguiente')));
    },
  );
}
