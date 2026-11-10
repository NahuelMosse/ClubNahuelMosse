import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/features/users/data/registration_service.dart';
import 'package:clubnahuelmosse/features/users/domain/registration_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/mount.dart';

void main() {
  test(
    'the registration screen does not build the HTTP request: the registration service does @REV-06-S3 @assumption:REV-06-ASM-03',
    () {
      final screen = File(
        'lib/features/users/presentation/registration_screen.dart',
      ).readAsStringSync();
      expect(screen, isNot(contains('api.post(')));
      expect(screen, isNot(contains("'/register'")));
      expect(screen, contains('RegistrationService'));
    },
  );

  test(
    'the registration service sends the person data to /registro @REV-06-S3',
    () async {
      final requests = <http.Request>[];
      final service = RegistrationService(
        apiRoutes({'POST /register': (201, '{}')}, requests: requests),
      );
      final r = await service.register(
        RegistrationData(
          firstName: 'Ana',
          lastName: 'Pérez',
          dni: '12.345.678',
          birthDate: DateTime(1990, 5, 7),
          email: 'ana@correo.com',
          password: 'Clave1234',
        ),
      );
      expect(r.code, 201);
      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/register');
      expect(jsonDecode(requests.single.body), {
        'first_name': 'Ana',
        'last_name': 'Pérez',
        'dni': '12.345.678',
        'birth_date': '1990-05-07',
        'email': 'ana@correo.com',
        'password': 'Clave1234',
      });
    },
  );
}
