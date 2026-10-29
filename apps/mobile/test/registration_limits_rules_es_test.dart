import 'package:clubnahuelmosse/features/users/domain/registration_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el nombre ignora los espacios del principio al medir el largo', () {
    final sixtyLetters = 'a' * maxNameLength;

    expect(validateName('  $sixtyLetters'), isNull);
  });

  test('la contraseña de exactamente 8 caracteres alcanza el largo mínimo', () {
    expect(passwordProblems('Abcdef12'), isEmpty);
    expect(passwordProblems('Abcde12'), [FieldProblem.passwordLength]);
  });
}
