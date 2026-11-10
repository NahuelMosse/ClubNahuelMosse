import 'registration_rules.dart';

/// What the person filled in on the registration form.
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

  /// The fields with the name the API uses.
  Map<String, Object?> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'dni': dni,
    'birth_date': isoDate(birthDate),
    'email': email,
    'password': password,
  };
}
