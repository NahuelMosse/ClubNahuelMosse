import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/usuarios/registro.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'soporte/montar.dart';

void main() {
  test(
    'la pantalla de registro no arma el pedido HTTP: lo hace el servicio de registro @REV-06-S3 @assumption:REV-06-ASM-03',
    () {
      final pantalla = File('lib/usuarios/pantalla_registro.dart')
          .readAsStringSync();
      expect(pantalla, isNot(contains('api.post(')));
      expect(pantalla, isNot(contains("'/registro'")));
      expect(pantalla, contains('RegistroServicio'));
    },
  );

  test(
    'el servicio de registro manda los datos de la persona a /registro @REV-06-S3',
    () async {
      final pedidos = <http.Request>[];
      final servicio = RegistroServicio(
        apiRutas({'POST /registro': (201, '{}')}, pedidos: pedidos),
      );
      final r = await servicio.registrar(
        DatosDeRegistro(
          nombre: 'Ana',
          apellido: 'Pérez',
          dni: '12.345.678',
          fechaNacimiento: DateTime(1990, 5, 7),
          correo: 'ana@correo.com',
          contrasena: 'Clave1234',
        ),
      );
      expect(r.codigo, 201);
      expect(pedidos, hasLength(1));
      expect(pedidos.single.url.path, '/registro');
      expect(jsonDecode(pedidos.single.body), {
        'nombre': 'Ana',
        'apellido': 'Pérez',
        'dni': '12.345.678',
        'fecha_nacimiento': '1990-05-07',
        'correo': 'ana@correo.com',
        'contrasena': 'Clave1234',
      });
    },
  );
}
