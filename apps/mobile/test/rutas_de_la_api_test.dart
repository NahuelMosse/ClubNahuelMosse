import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/api/rutas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'cada ruta que la app declara está publicada en el contrato de la API @REV-08-S4 '
    '@assumption:REV-08-ASM-04',
    () {
      // El contrato que publica la API (apps/api/openapi.json); los tests corren en apps/mobile.
      final contrato =
          jsonDecode(File('../api/openapi.json').readAsStringSync())
              as Map<String, Object?>;
      final caminos = contrato['paths']! as Map<String, Object?>;
      final publicadas = {
        for (final MapEntry(key: ruta, value: metodos) in caminos.entries)
          for (final metodo in (metodos! as Map<String, Object?>).keys)
            '${metodo.toUpperCase()} $ruta',
      };

      expect(rutasDeLaApi, isNotEmpty);
      expect(
        [
          for (final r in rutasDeLaApi) '${r.metodo} ${r.ruta}',
        ].where((r) => !publicadas.contains(r)),
        isEmpty,
      );
    },
  );

  test(
    'un pedido a una ruta que la app no declara falla en sus propios tests @REV-08-S4 '
    '@assumption:REV-08-ASM-04',
    () async {
      final api = ApiClient(
        'http://api.falsa',
        cliente: MockClient((_) async => http.Response('{}', 200)),
      );

      await expectLater(
        () => api.get('/ruta-inventada'),
        throwsA(isA<AssertionError>()),
      );
      await expectLater(
        () =>
            api.post('/venues/00000000-0000-7000-8000-000000000001/void', {}),
        throwsA(isA<AssertionError>()),
      );
      await expectLater(api.get('/venues', token: 'token'), completes);
      await expectLater(api.get('/bookings?when=upcoming'), completes);
    },
  );

  test('en release un pedido a una ruta no declarada sale como hoy @REV-08-S4 '
      '@assumption:REV-08-ASM-07', () async {
    final pedidos = <http.Request>[];
    final api = ApiClient(
      'http://api.falsa',
      verificarRutas: false,
      cliente: MockClient((p) async {
        pedidos.add(p);
        return http.Response('{}', 200);
      }),
    );

    final r = await api.get('/ruta-inventada');

    expect(r.codigo, 200);
    expect(pedidos.single.url.path, '/ruta-inventada');
  });

  test('el manifiesto se compara por método y por plantilla de ruta @REV-08-S4 '
      '@assumption:REV-08-ASM-12', () {
    expect(
      rutaDeclarada(
        'GET',
        '/bookings/all/00000000-0000-7000-8000-000000000007',
      ),
      isTrue,
    );
    expect(
      rutaDeclarada(
        'POST',
        '/bookings/00000000-0000-7000-8000-000000000007/void',
      ),
      isTrue,
    );
    expect(rutaDeclarada('GET', '/reservas?cuando=historial'), isTrue);
    // El método cuenta: la ruta existe pero con otro método.
    expect(rutaDeclarada('DELETE', '/reservas'), isFalse);
    expect(
      rutaDeclarada(
        'GET',
        '/bookings/00000000-0000-7000-8000-000000000007/void',
      ),
      isFalse,
    );
    // La plantilla cuenta: un segmento de más o de menos no coincide.
    expect(
      rutaDeclarada(
        'POST',
        '/bookings/00000000-0000-7000-8000-000000000007/8/void',
      ),
      isFalse,
    );
    expect(
      rutaDeclarada(
        'GET',
        '/bookings/all/00000000-0000-7000-8000-000000000007/x',
      ),
      isFalse,
    );
    expect(rutaDeclarada('GET', '/ruta-inventada'), isFalse);
  });
}
