import 'role.dart';

class Profile {
  const Profile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.dni,
    required this.birthDate,
  });

  final String firstName;
  final String lastName;
  final String email;
  final Role role;
  final String dni;
  final DateTime birthDate;

  /// The route each role enters after signing in.
  String get home => role == Role.admin ? '/admin' : '/home';
}
