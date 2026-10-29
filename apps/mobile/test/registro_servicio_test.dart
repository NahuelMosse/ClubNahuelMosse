import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/features/users/data/registration_service.dart';
import 'package:clubnahuelmosse/features/users/domain/registration_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'soporte/montar.dart';

void main() {
  test(
    'la pantalla de registro no arma el pedido HTTP: lo hace el servicio de registro @REV-06-S3 @assumption:REV-06-ASM-03',
    () {
      final pantalla = File(
        'lib/features/users/presentation/registration_screen.dart',
      ).readAsStringSync();
      expect(pantalla, isNot(contains('api.post(')));
      expect(pantalla, isNot(contains("'/register'")));
      expect(pantalla, contains('RegistrationService'));
    },
  );

  test(
    'el servicio de registro manda los datos de la persona a /registro @REV-06-S3',
    () async {
      final pedidos = <http.Request>[];
      final servicio = RegistrationService(
        apiRutas({'POST /register': (201, '{}')}, pedidos: pedidos),
      );
      final r = await servicio.register(
        RegistrationData(
          firstName: 'Ana',
          lastName: 'Pérez',
          dni: '12.345.678',
          birthDate: DateTime(1990, 5, 7),
          email: 'ana@correo.com',
          password: 'Clave1234',
        ),
      );
      expect(r.codigo, 201);
      expect(pedidos, hasLength(1));
      expect(pedidos.single.url.path, '/register');
      expect(jsonDecode(pedidos.single.body), {
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
