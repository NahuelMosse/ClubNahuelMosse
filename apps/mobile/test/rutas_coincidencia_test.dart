import 'package:clubnahuelmosse/api/rutas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('una ruta sin la barra inicial no coincide con la declarada', () {
    expect(rutaDeclarada('GET', '/yo'), isTrue);
    expect(rutaDeclarada('GET', 'x/yo'), isFalse);
  });

  test('una llave suelta no hace de parámetro: solo `{nombre}` completo', () {
    const ruta = ApiRoute('GET', '/a/x}');
    expect(ruta.coincideCon('GET', ['', 'a', 'x}']), isTrue);
    expect(ruta.coincideCon('GET', ['', 'a', 'y}']), isFalse);
  });

  test(
    'un parámetro `{id}` acepta cualquier valor no vacío y rechaza el vacío',
    () {
      const ruta = ApiRoute('GET', '/a/{id}');
      expect(ruta.coincideCon('GET', ['', 'a', '7']), isTrue);
      expect(ruta.coincideCon('GET', ['', 'a', '']), isFalse);
    },
  );
}
