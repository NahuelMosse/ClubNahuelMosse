import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/api/api_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('every route the app declares is published in the API contract @REV-08-S4 '
      '@assumption:REV-08-ASM-04', () {
    // The contract the API publishes (apps/api/openapi.json); the tests run in apps/mobile.
    final contract =
        jsonDecode(File('../api/openapi.json').readAsStringSync())
            as Map<String, Object?>;
    final paths = contract['paths']! as Map<String, Object?>;
    final published = {
      for (final MapEntry(key: route, value: methods) in paths.entries)
        for (final method in (methods! as Map<String, Object?>).keys)
          '${method.toUpperCase()} $route',
    };

    expect(apiRoutes, isNotEmpty);
    expect(
      [
        for (final r in apiRoutes) '${r.method} ${r.route}',
      ].where((r) => !published.contains(r)),
      isEmpty,
    );
  });

  test(
    'a request to a route the app does not declare fails in its own tests @REV-08-S4 '
    '@assumption:REV-08-ASM-04',
    () async {
      final api = ApiClient(
        'http://api.falsa',
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      await expectLater(
        () => api.get('/ruta-inventada'),
        throwsA(isA<AssertionError>()),
      );
      await expectLater(
        () => api.post('/venues/00000000-0000-7000-8000-000000000001/void', {}),
        throwsA(isA<AssertionError>()),
      );
      await expectLater(api.get('/venues', token: 'token'), completes);
      await expectLater(api.get('/bookings?when=upcoming'), completes);
    },
  );

  test(
    'in release a request to an undeclared route goes out as before @REV-08-S4 '
    '@assumption:REV-08-ASM-07',
    () async {
      final requests = <http.Request>[];
      final api = ApiClient(
        'http://api.falsa',
        verifyRoutes: false,
        client: MockClient((p) async {
          requests.add(p);
          return http.Response('{}', 200);
        }),
      );

      final r = await api.get('/ruta-inventada');

      expect(r.code, 200);
      expect(requests.single.url.path, '/ruta-inventada');
    },
  );

  test('the manifest is compared by method and by route template @REV-08-S4 '
      '@assumption:REV-08-ASM-12', () {
    expect(
      isRouteDeclared(
        'GET',
        '/bookings/all/00000000-0000-7000-8000-000000000007',
      ),
      isTrue,
    );
    expect(
      isRouteDeclared(
        'POST',
        '/bookings/00000000-0000-7000-8000-000000000007/void',
      ),
      isTrue,
    );
    expect(isRouteDeclared('GET', '/bookings?when=history'), isTrue);
    // The method counts: the route exists but with another method.
    expect(isRouteDeclared('DELETE', '/bookings'), isFalse);
    expect(
      isRouteDeclared(
        'GET',
        '/bookings/00000000-0000-7000-8000-000000000007/void',
      ),
      isFalse,
    );
    // The template counts: one segment more or less does not match.
    expect(
      isRouteDeclared(
        'POST',
        '/bookings/00000000-0000-7000-8000-000000000007/8/void',
      ),
      isFalse,
    );
    expect(
      isRouteDeclared(
        'GET',
        '/bookings/all/00000000-0000-7000-8000-000000000007/x',
      ),
      isFalse,
    );
    expect(isRouteDeclared('GET', '/ruta-inventada'), isFalse);
  });
}
