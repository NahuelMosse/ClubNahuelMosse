import 'package:clubnahuelmosse/common/date_format.dart';
import 'package:clubnahuelmosse/features/users/domain/registration_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 12);

  test('name required and up to 60 characters', () {
    expect(
      validateName('  ', requiredMessage: 'El nombre es obligatorio'),
      'El nombre es obligatorio',
    );
    expect(validateName('a' * 60, requiredMessage: 'x'), isNull);
    expect(
      validateName('a' * 61, requiredMessage: 'x'),
      'Máximo 60 caracteres',
    );
  });

  test('DNI of 7 or 8 digits, with or without dots', () {
    expect(validateDni(''), 'El DNI es obligatorio');
    expect(validateDni('1234567'), isNull);
    expect(validateDni('42.118.507'), isNull);
    expect(validateDni('123456'), 'El DNI tiene 7 u 8 números');
    expect(validateDni('123456789'), 'El DNI tiene 7 u 8 números');
    expect(normalizeDni('42.118.507'), '42118507');
  });

  test('birth date', () {
    expect(
      validateBirthDate('', today),
      'La fecha de nacimiento es obligatoria',
    );
    expect(validateBirthDate('14 / 03 / 2000', today), isNull);
    expect(validateBirthDate('11 / 11 / 2026', today), isNull);
    expect(
      validateBirthDate('12 / 11 / 2026', today),
      'La fecha tiene que ser anterior a hoy',
    );
    expect(validateBirthDate('30 / 02 / 2000', today), 'La fecha no es válida');
    expect(validateBirthDate('14 / 03 / 20', today), 'La fecha no es válida');
    expect(isoDate(DateTime(2000, 3, 4)), '2000-03-04');
  });

  test('email', () {
    expect(validateEmail(' '), 'El correo es obligatorio');
    expect(validateEmail(' NMosse@UniMoron.edu.ar '), isNull);
    for (final bad in ['sinarroba.com', 'a@b', 'a b@c.com', 'a@@c.com']) {
      expect(validateEmail(bad), 'Revisá el formato del correo', reason: bad);
    }
  });

  test('password: 8 characters, an uppercase letter and a digit', () {
    expect(validatePassword(''), 'La contraseña es obligatoria');
    expect(passwordProblems('club'), [
      'Al menos 8 caracteres',
      'Una letra mayúscula',
      'Al menos un número',
    ]);
    expect(passwordProblems('clubnahuel1'), ['Una letra mayúscula']);
    expect(passwordProblems('ClubNahuel'), ['Al menos un número']);
    expect(passwordProblems('Ñandúes123'), isEmpty);
  });

  test('the date is built while typing', () {
    const formatter = DateInputFormatter();
    TextEditingValue type(String text) => formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text),
    );
    expect(type('14').text, '14');
    expect(type('1403').text, '14 / 03');
    expect(type('14032000').text, '14 / 03 / 2000');
    expect(type('1403200099').text, '14 / 03 / 2000');
    expect(type('14/03/2000').text, '14 / 03 / 2000');
  });

  test('counts characters, not UTF-16 units, like the API', () {
    expect(passwordProblems('Aa1😀😀😀'), ['Al menos 8 caracteres']);
    expect(validateName('😀' * 31, requiredMessage: 'x'), isNull);
    expect(
      validateName('😀' * 61, requiredMessage: 'x'),
      'Máximo 60 caracteres',
    );
  });

  test('year zero is not a date', () {
    expect(readDate('14 / 03 / 0000'), isNull);
    expect(formatDate(DateTime(2000, 3, 4)), '04 / 03 / 2000');
  });
}
