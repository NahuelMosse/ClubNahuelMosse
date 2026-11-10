import 'package:clubnahuelmosse/common/date_format.dart';
import 'package:clubnahuelmosse/features/users/domain/registration_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 12);

  test('name required and up to 60 characters', () {
    expect(validateName('  '), FieldProblem.nameRequired);
    expect(validateName('a' * 60), isNull);
    expect(validateName('a' * 61), FieldProblem.nameTooLong);
  });

  test('DNI of 7 or 8 digits, with or without dots', () {
    expect(validateDni(''), FieldProblem.dniRequired);
    expect(validateDni('1234567'), isNull);
    expect(validateDni('42.118.507'), isNull);
    expect(validateDni('123456'), FieldProblem.dniFormat);
    expect(validateDni('123456789'), FieldProblem.dniFormat);
    expect(normalizeDni('42.118.507'), '42118507');
  });

  test('birth date', () {
    expect(validateBirthDate('', today), FieldProblem.birthRequired);
    expect(validateBirthDate('14 / 03 / 2000', today), isNull);
    expect(validateBirthDate('11 / 11 / 2026', today), isNull);
    expect(
      validateBirthDate('12 / 11 / 2026', today),
      FieldProblem.birthNotPast,
    );
    expect(
      validateBirthDate('30 / 02 / 2000', today),
      FieldProblem.birthInvalid,
    );
    expect(validateBirthDate('14 / 03 / 20', today), FieldProblem.birthInvalid);
    expect(isoDate(DateTime(2000, 3, 4)), '2000-03-04');
  });

  test('email', () {
    expect(validateEmail(' '), FieldProblem.emailRequired);
    expect(validateEmail(' NMosse@UniMoron.edu.ar '), isNull);
    for (final bad in ['sinarroba.com', 'a@b', 'a b@c.com', 'a@@c.com']) {
      expect(validateEmail(bad), FieldProblem.emailFormat, reason: bad);
    }
  });

  test('password: 8 characters, an uppercase letter and a digit', () {
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
    expect(passwordProblems('Aa1😀😀😀'), [FieldProblem.passwordLength]);
    expect(validateName('😀' * 31), isNull);
    expect(validateName('😀' * 61), FieldProblem.nameTooLong);
  });

  test('year zero is not a date', () {
    expect(readDate('14 / 03 / 0000'), isNull);
    expect(formatDate(DateTime(2000, 3, 4)), '04 / 03 / 2000');
  });
}
