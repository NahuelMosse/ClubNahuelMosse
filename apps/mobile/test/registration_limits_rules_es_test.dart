import 'package:clubnahuelmosse/features/users/domain/registration_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the name ignores leading spaces when measuring its length', () {
    final sixtyLetters = 'a' * maxNameLength;

    expect(validateName('  $sixtyLetters'), isNull);
  });

  test('a password of exactly 8 characters meets the minimum length', () {
    expect(passwordProblems('Abcdef12'), isEmpty);
    expect(passwordProblems('Abcde12'), [FieldProblem.passwordLength]);
  });
}
