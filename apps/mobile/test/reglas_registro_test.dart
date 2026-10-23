import 'package:clubnahuelmosse/comun/formato_fecha.dart';
import 'package:clubnahuelmosse/comun/reglas_registro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hoy = DateTime(2026, 11, 12);

  test('nombre obligatorio y de hasta 60 caracteres', () {
    expect(
      validarNombre('  ', obligatorio: 'El nombre es obligatorio'),
      'El nombre es obligatorio',
    );
    expect(validarNombre('a' * 60, obligatorio: 'x'), isNull);
    expect(validarNombre('a' * 61, obligatorio: 'x'), 'Máximo 60 caracteres');
  });

  test('DNI de 7 u 8 números, con o sin puntos', () {
    expect(validarDni(''), 'El DNI es obligatorio');
    expect(validarDni('1234567'), isNull);
    expect(validarDni('42.118.507'), isNull);
    expect(validarDni('123456'), 'El DNI tiene 7 u 8 números');
    expect(validarDni('123456789'), 'El DNI tiene 7 u 8 números');
    expect(normalizarDni('42.118.507'), '42118507');
  });

  test('fecha de nacimiento', () {
    expect(
      validarFechaNacimiento('', hoy),
      'La fecha de nacimiento es obligatoria',
    );
    expect(validarFechaNacimiento('14 / 03 / 2000', hoy), isNull);
    expect(validarFechaNacimiento('11 / 11 / 2026', hoy), isNull);
    expect(
      validarFechaNacimiento('12 / 11 / 2026', hoy),
      'La fecha tiene que ser anterior a hoy',
    );
    expect(
      validarFechaNacimiento('30 / 02 / 2000', hoy),
      'La fecha no es válida',
    );
    expect(
      validarFechaNacimiento('14 / 03 / 20', hoy),
      'La fecha no es válida',
    );
    expect(fechaIso(DateTime(2000, 3, 4)), '2000-03-04');
  });

  test('correo', () {
    expect(validarCorreo(' '), 'El correo es obligatorio');
    expect(validarCorreo(' NMosse@UniMoron.edu.ar '), isNull);
    for (final malo in ['sinarroba.com', 'a@b', 'a b@c.com', 'a@@c.com']) {
      expect(validarCorreo(malo), 'Revisá el formato del correo', reason: malo);
    }
  });

  test('contraseña: 8 caracteres, una mayúscula y un número', () {
    expect(validarContrasena(''), 'La contraseña es obligatoria');
    expect(problemasContrasena('club'), [
      'Al menos 8 caracteres',
      'Una letra mayúscula',
      'Al menos un número',
    ]);
    expect(problemasContrasena('clubnahuel1'), ['Una letra mayúscula']);
    expect(problemasContrasena('ClubNahuel'), ['Al menos un número']);
    expect(problemasContrasena('Ñandúes123'), isEmpty);
  });

  test('la fecha se arma mientras se escribe', () {
    const formato = FormatoFecha();
    TextEditingValue escribir(String texto) => formato.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: texto),
    );
    expect(escribir('14').text, '14');
    expect(escribir('1403').text, '14 / 03');
    expect(escribir('14032000').text, '14 / 03 / 2000');
    expect(escribir('1403200099').text, '14 / 03 / 2000');
    expect(escribir('14/03/2000').text, '14 / 03 / 2000');
  });

  test('cuenta caracteres, no unidades UTF-16, igual que la API', () {
    expect(problemasContrasena('Aa1😀😀😀'), ['Al menos 8 caracteres']);
    expect(validarNombre('😀' * 31, obligatorio: 'x'), isNull);
    expect(validarNombre('😀' * 61, obligatorio: 'x'), 'Máximo 60 caracteres');
  });

  test('el año cero no es una fecha', () {
    expect(leerFecha('14 / 03 / 0000'), isNull);
    expect(formatearFecha(DateTime(2000, 3, 4)), '04 / 03 / 2000');
  });
}
