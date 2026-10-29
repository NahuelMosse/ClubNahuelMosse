/// The same registration rules the API validates, to warn while the user types.
/// Each rule returns what it found wrong, never the text: the screen words it.
library;

import '../../../common/date_format.dart';
import '../../../common/dates.dart';
import 'field_problem.dart';

export '../../../common/date_format.dart' show readDate;
export '../../../common/dates.dart'
    show formatDate, isoDate, normalizeDni, readableDni, readableDate;
export 'field_problem.dart';

const maxNameLength = 60;

FieldProblem? validateName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return FieldProblem.nameRequired;
  if (trimmed.runes.length > maxNameLength) return FieldProblem.nameTooLong;
  return null;
}

FieldProblem? validateDni(String value) {
  final dni = normalizeDni(value.trim());
  if (dni.isEmpty) return FieldProblem.dniRequired;
  if (!RegExp(r'^[0-9]{7,8}$').hasMatch(dni)) return FieldProblem.dniFormat;
  return null;
}

FieldProblem? validateBirthDate(String value, DateTime today) {
  if (value.trim().isEmpty) return FieldProblem.birthRequired;
  final date = readDate(value);
  if (date == null) return FieldProblem.birthInvalid;
  if (!date.isBefore(DateTime(today.year, today.month, today.day))) {
    return FieldProblem.birthNotPast;
  }
  return null;
}

FieldProblem? validateEmail(String value) {
  final email = value.trim().toLowerCase();
  if (email.isEmpty) return FieldProblem.emailRequired;
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return FieldProblem.emailFormat;
  }
  return null;
}

/// Code points of the accented capitals of Spanish: A, E, I, O, U with acute and N with tilde.
const _accentedCapitals = [0xC1, 0xC9, 0xCD, 0xD3, 0xDA, 0xD1];
final _uppercase = RegExp('[A-Z${String.fromCharCodes(_accentedCapitals)}]');

/// The rules the password does not meet, in the order the app shows them.
List<FieldProblem> passwordProblems(String password) => [
  if (password.runes.length < 8) FieldProblem.passwordLength,
  // The uppercase letters of Spanish (A, E, I, O, U with acute, and N with tilde) count too.
  if (!_uppercase.hasMatch(password)) FieldProblem.passwordUppercase,
  if (!RegExp(r'[0-9]').hasMatch(password)) FieldProblem.passwordNumber,
];

FieldProblem? validatePassword(String value) {
  if (value.isEmpty) return FieldProblem.passwordRequired;
  return passwordProblems(value).firstOrNull;
}
