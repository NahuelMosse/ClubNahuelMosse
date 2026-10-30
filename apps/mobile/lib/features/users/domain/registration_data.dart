import 'registration_rules.dart';

/// Lo que la persona completó en el formulario de registro.
class RegistrationData {
  const RegistrationData({
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.birthDate,
    required this.email,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String dni;
  final DateTime birthDate;
  final String email;
  final String password;

  /// Los campos con el nombre que usa la API.
  Map<String, Object?> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'dni': dni,
    'birth_date': isoDate(birthDate),
    'email': email,
    'password': password,
  };
}
