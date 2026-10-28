/// The same registration rules the API validates, to warn while the user types.
/// The messages are identical to the ones `POST /registro` returns.
library;

import '../../../common/date_format.dart';
import '../../../common/dates.dart';

export '../../../common/date_format.dart' show readDate;
export '../../../common/dates.dart'
    show formatDate, isoDate, normalizeDni, readableDni, readableDate;

const maxNameLength = 60;

String? validateName(String value, {required String requiredMessage}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return requiredMessage;
  if (trimmed.runes.length > maxNameLength) {
    return 'Máximo $maxNameLength caracteres';
  }
  return null;
}

String? validateDni(String value) {
  final dni = normalizeDni(value.trim());
  if (dni.isEmpty) return 'El DNI es obligatorio';
  if (!RegExp(r'^[0-9]{7,8}$').hasMatch(dni)) {
    return 'El DNI tiene 7 u 8 números';
  }
  return null;
}

String? validateBirthDate(String value, DateTime today) {
  if (value.trim().isEmpty) return 'La fecha de nacimiento es obligatoria';
  final date = readDate(value);
  if (date == null) return 'La fecha no es válida';
  if (!date.isBefore(DateTime(today.year, today.month, today.day))) {
    return 'La fecha tiene que ser anterior a hoy';
  }
  return null;
}

String? validateEmail(String value) {
  final email = value.trim().toLowerCase();
  if (email.isEmpty) return 'El correo es obligatorio';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Revisá el formato del correo';
  }
  return null;
}

/// The rules the password does not meet, in the order the app shows them.
List<String> passwordProblems(String password) => [
  if (password.runes.length < 8) 'Al menos 8 caracteres',
  if (!RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(password)) 'Una letra mayúscula',
  if (!RegExp(r'[0-9]').hasMatch(password)) 'Al menos un número',
];

String? validatePassword(String value) {
  if (value.isEmpty) return 'La contraseña es obligatoria';
  final missing = passwordProblems(value);
  return missing.isEmpty ? null : missing.first;
}
