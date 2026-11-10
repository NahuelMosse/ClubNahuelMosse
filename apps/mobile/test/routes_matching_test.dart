import 'package:clubnahuelmosse/api/rutas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a route without the leading slash does not match the declared one', () {
    expect(rutaDeclarada('GET', '/me'), isTrue);
    expect(rutaDeclarada('GET', 'x/me'), isFalse);
  });

  test('a stray brace is not a parameter: only a complete `{name}` is', () {
    const route = ApiRoute('GET', '/a/x}');
    expect(route.coincideCon('GET', ['', 'a', 'x}']), isTrue);
    expect(route.coincideCon('GET', ['', 'a', 'y}']), isFalse);
  });

  test(
    'an `{id}` parameter accepts any non-empty value and rejects the empty one',
    () {
      const route = ApiRoute('GET', '/a/{id}');
      expect(route.coincideCon('GET', ['', 'a', '7']), isTrue);
      expect(route.coincideCon('GET', ['', 'a', '']), isFalse);
    },
  );
}
