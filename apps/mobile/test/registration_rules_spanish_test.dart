import 'package:clubnahuelmosse/common/date_format.dart';
import 'package:clubnahuelmosse/features/users/domain/registration_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hoy = DateTime(2026, 11, 12);

  test('nombre obligatorio y de hasta 60 caracteres', () {
    expect(validateName('  '), FieldProblem.nameRequired);
    expect(validateName('a' * 60), isNull);
    expect(validateName('a' * 61), FieldProblem.nameTooLong);
  });

  test('DNI de 7 u 8 números, con o sin puntos', () {
    expect(validateDni(''), FieldProblem.dniRequired);
    expect(validateDni('1234567'), isNull);
    expect(validateDni('42.118.507'), isNull);
    expect(validateDni('123456'), FieldProblem.dniFormat);
    expect(validateDni('123456789'), FieldProblem.dniFormat);
    expect(normalizeDni('42.118.507'), '42118507');
  });

  test('fecha de nacimiento', () {
    expect(validateBirthDate('', hoy), FieldProblem.birthRequired);
    expect(validateBirthDate('14 / 03 / 2000', hoy), isNull);
    expect(validateBirthDate('11 / 11 / 2026', hoy), isNull);
    expect(validateBirthDate('12 / 11 / 2026', hoy), FieldProblem.birthNotPast);
    expect(validateBirthDate('30 / 02 / 2000', hoy), FieldProblem.birthInvalid);
    expect(validateBirthDate('14 / 03 / 20', hoy), FieldProblem.birthInvalid);
    expect(isoDate(DateTime(2000, 3, 4)), '2000-03-04');
  });

  test('correo', () {
    expect(validateEmail(' '), FieldProblem.emailRequired);
    expect(validateEmail(' NMosse@UniMoron.edu.ar '), isNull);
    for (final malo in ['sinarroba.com', 'a@b', 'a b@c.com', 'a@@c.com']) {
      expect(validateEmail(malo), FieldProblem.emailFormat, reason: malo);
    }
  });

  test('contraseña: 8 caracteres, una mayúscula y un número', () {
    expect(validatePassword(''), FieldProblem.passwordRequired);
    expect(passwordProblems('club'), [
      FieldProblem.passwordLength,
      FieldProblem.passwordUppercase,
      FieldProblem.passwordNumber,
    ]);
    expect(passwordProblems('clubnahuel1'), [FieldProblem.passwordUppercase]);
    expect(passwordProblems('ClubNahuel'), [FieldProblem.passwordNumber]);
    expect(passwordProblems('Ñandúes123'), isEmpty);
  });

  test('la fecha se arma mientras se escribe', () {
    const formato = DateInputFormatter();
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
    expect(passwordProblems('Aa1😀😀😀'), [FieldProblem.passwordLength]);
    expect(validateName('😀' * 31), isNull);
    expect(validateName('😀' * 61), FieldProblem.nameTooLong);
  });

  test('el año cero no es una fecha', () {
    expect(readDate('14 / 03 / 0000'), isNull);
    expect(formatDate(DateTime(2000, 3, 4)), '04 / 03 / 2000');
  });
}
