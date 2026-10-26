// ignore_for_file: unawaited_futures
import 'dart:io';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/comun/errores_no_manejados.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _fuente(String ruta) => File(ruta).readAsStringSync();

void main() {
  testWidgets(
    'la app no avisa que el servidor despierta ni captura errores no manejados @SIM-01-S1',
    (tester) async {
      expect(File('lib/comun/aviso_despertando.dart').existsSync(), isFalse);
      final errores = _fuente('lib/comun/errores_no_manejados.dart');
      expect(errores, isNot(contains('instalarCapturaDeErrores')));
      expect(errores, isNot(contains('correrProtegido')));
      expect(errores, isNot(contains('registroDeErrores')));
      final cliente = _fuente('lib/api/cliente_api.dart');
      expect(cliente, isNot(contains('despertando')));
      expect(cliente, isNot(contains('referencia')));
      final main = _fuente('lib/main.dart');
      expect(main, isNot(contains('correrProtegido')));
      expect(main, isNot(contains('AvisoDespertando')));
    },
  );

  testWidgets(
    'a los 30 s sin respuesta la app avisa que el servidor no responde @SIM-01-S4 @assumption:SIM-01-ASM-04',
    (tester) async {
      final api = ClienteApi(
        'http://api.falsa',
        cliente: MockClient(
          (_) => Future.delayed(
            const Duration(seconds: 90),
            () => http.Response('{}', 200),
          ),
        ),
      );
      Object? error;
      api.get('/espacios').then((_) {}, onError: (Object e) => error = e);
      await tester.pump(const Duration(seconds: 29));
      expect(error, isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(error, isA<ServidorSinRespuesta>());
      await tester.pump(const Duration(seconds: 90));
    },
  );

  testWidgets('sin conexión la app lo avisa @SIM-01-S4', (tester) async {
    final api = ClienteApi(
      'http://api.falsa',
      cliente: MockClient((_) async => throw http.ClientException('sin red')),
    );
    await expectLater(api.get('/espacios'), throwsA(isA<SinConexion>()));
  });

  test(
    'registrarError escribe en la consola de desarrollo @assumption:SIM-01-ASM-06',
    () {
      final original = debugPrint;
      final lineas = <String>[];
      debugPrint = (mensaje, {wrapWidth}) => lineas.add(mensaje ?? '');
      addTearDown(() => debugPrint = original);
      registrarError(StateError('falla'), StackTrace.empty);
      expect(lineas.join(), contains('falla'));
    },
  );

  test('la app arranca sin pantalla de error de arranque @SIM-01-S1', () {
    expect(File('lib/comun/pantalla_error_de_arranque.dart').existsSync(), isFalse);
    expect(_fuente('lib/main.dart'), isNot(contains('PantallaErrorDeArranque')));
  });

  test(
    'al arrancar sin conexión la app muestra el diálogo de error con Reintentar @SIM-01-S4 @assumption:SIM-01-ASM-08',
    () {
      final main = _fuente('lib/main.dart');
      expect(main, contains('atenderErrorDeRed'));
    },
  );

  test(
    'mis reservas trae la lista entera de una vez @SIM-01-S1 @assumption:SIM-01-ASM-01',
    () {
      final reservas = _fuente('lib/reservas/reservas.dart');
      expect(reservas, isNot(contains('TandaDeReservas')));
      expect(reservas, isNot(contains('despues')));
      final pantalla = _fuente('lib/reservas/pantalla_mis_reservas.dart');
      expect(pantalla, isNot(contains('_cargarMas')));
      expect(pantalla, isNot(contains('_siguiente')));
    },
  );
}
