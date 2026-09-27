import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/montar.dart';

void main() {
  group('retomar la sesión guardada', () {
    test('sin cuenta en el dispositivo no consulta nada', () async {
      final sesion = Sesion(
        credenciales: CredencialesFalsas(),
        api: apiFalsa(codigo: 500),
      );
      expect(await sesion.retomar(), isNull);
    });

    test('con la cuenta vigente entra con su rol', () async {
      final sesion = Sesion(
        credenciales: CredencialesFalsas(conCuenta: true),
        api: apiFalsa(codigo: 200, cuerpo: perfilJson(rol: 'admin')),
      );
      final perfil = await sesion.retomar();
      expect(perfil?.rol, Rol.admin);
      expect(perfil?.inicio, '/admin');
      expect(sesion.perfil, same(perfil));
    });

    test('si la API ya no la reconoce, la cierra', () async {
      final credenciales = CredencialesFalsas(conCuenta: true);
      final sesion = Sesion(
        credenciales: credenciales,
        api: apiFalsa(codigo: 401, cuerpo: '{}'),
      );
      expect(await sesion.retomar(), isNull);
      expect(credenciales.salidas, 1);
    });

    test('sin red o con la API caída la conserva para la próxima', () async {
      final credenciales = CredencialesFalsas(conCuenta: true);
      final sesion = Sesion(
        credenciales: credenciales,
        api: apiFalsa(codigo: 503),
      );
      expect(await sesion.retomar(), isNull);
      expect(credenciales.salidas, 0);
    });
  });

  test(
    'una API que no contesta no traba el arranque ni cierra la sesión',
    () async {
      final credenciales = CredencialesFalsas(conCuenta: true);
      final sesion = Sesion(
        credenciales: credenciales,
        api: ClienteApi(
          'http://api.lenta',
          cliente: MockClient((_) async {
            await Future<void>.delayed(const Duration(seconds: 5));
            return http.Response('{}', 200);
          }),
        ),
        limiteAlRetomar: const Duration(milliseconds: 50),
      );
      final antes = DateTime.now();
      expect(await sesion.retomar(), isNull);
      expect(
        DateTime.now().difference(antes),
        lessThan(const Duration(seconds: 2)),
      );
      expect(credenciales.salidas, 0);
    },
  );

  test('avisa a quien escucha cuando cambia el perfil', () async {
    final sesion = Sesion(
      credenciales: CredencialesFalsas(),
      api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
    );
    var avisos = 0;
    sesion.addListener(() => avisos++);
    await sesion.iniciar('a@b.com', 'Clave1234');
    await sesion.cerrar();
    expect(avisos, 2);
  });

  test('un perfil con un rol desconocido es un error del servidor', () async {
    final credenciales = CredencialesFalsas();
    final sesion = Sesion(
      credenciales: credenciales,
      api: apiFalsa(codigo: 200, cuerpo: perfilJson(rol: 'dueño')),
    );
    await expectLater(
      sesion.iniciar('a@b.com', 'Clave1234'),
      throwsA(isA<ErrorDelServidor>()),
    );
    expect(credenciales.hayCuenta, isFalse);
  });

  test('cerrar la sesión olvida el perfil', () async {
    final credenciales = CredencialesFalsas();
    final sesion = Sesion(
      credenciales: credenciales,
      api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
    );
    await sesion.iniciar('a@b.com', 'Clave1234');
    await sesion.cerrar();
    expect(sesion.perfil, isNull);
    expect(credenciales.hayCuenta, isFalse);
  });
}
