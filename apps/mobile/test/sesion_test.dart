import 'dart:async';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/domain/role.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/montar.dart';

void main() {
  group('retomar la sesión guardada', () {
    test('sin cuenta en el dispositivo no consulta nada', () async {
      final sesion = Session(
        repository: SessionRepository(
          credentials: CredencialesFalsas(),
          api: apiFalsa(codigo: 500),
        ),
      );
      expect(await sesion.resume(), isNull);
    });

    test('con la cuenta vigente entra con su rol', () async {
      final sesion = Session(
        repository: SessionRepository(
          credentials: CredencialesFalsas(conCuenta: true),
          api: apiFalsa(codigo: 200, cuerpo: perfilJson(rol: 'admin')),
        ),
      );
      final perfil = await sesion.resume();
      expect(perfil?.role, Role.admin);
      expect(perfil?.home, '/admin');
      expect(sesion.profile, same(perfil));
    });

    test('si la API ya no la reconoce, la cierra', () async {
      final credenciales = CredencialesFalsas(conCuenta: true);
      final sesion = Session(
        repository: SessionRepository(
          credentials: credenciales,
          api: apiFalsa(codigo: 401, cuerpo: '{}'),
        ),
      );
      expect(await sesion.resume(), isNull);
      expect(credenciales.salidas, 1);
    });

    test('sin red o con la API caída la conserva para la próxima', () async {
      final credenciales = CredencialesFalsas(conCuenta: true);
      final sesion = Session(
        repository: SessionRepository(
          credentials: credenciales,
          api: apiFalsa(codigo: 503),
        ),
      );
      await expectLater(sesion.resume(), throwsA(isA<ErrorDelServidor>()));
      expect(credenciales.salidas, 0);
    });
  });

  test('avisa a quien escucha cuando cambia el perfil', () async {
    final sesion = Session(
      repository: SessionRepository(
        credentials: CredencialesFalsas(),
        api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
      ),
    );
    var avisos = 0;
    sesion.addListener(() => avisos++);
    await sesion.signIn('a@b.com', 'Clave1234');
    await sesion.close();
    expect(avisos, 2);
  });

  test('un perfil con un rol desconocido es un error del servidor', () async {
    final credenciales = CredencialesFalsas();
    final sesion = Session(
      repository: SessionRepository(
        credentials: credenciales,
        api: apiFalsa(codigo: 200, cuerpo: perfilJson(rol: 'dueño')),
      ),
    );
    await expectLater(
      sesion.signIn('a@b.com', 'Clave1234'),
      throwsA(isA<ErrorDelServidor>()),
    );
    expect(credenciales.hasAccount, isFalse);
  });

  test('si Firebase no puede cerrar la sesión, el perfil sigue', () async {
    final sesion = Session(
      repository: SessionRepository(
        credentials: _SalirFalla(),
        api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
      ),
    );
    await sesion.signIn('a@b.com', 'Clave1234');
    await expectLater(sesion.close(), throwsA(isA<StateError>()));
    expect(sesion.profile, isNotNull);
  });

  test(
    'una edición que vuelve después de cerrar la sesión no la revive',
    () async {
      final respuesta = Completer<http.Response>();
      var pedidos = 0;
      final sesion = Session(
        repository: SessionRepository(
          credentials: CredencialesFalsas(),
          api: ClienteApi(
            'http://api.falsa',
            cliente: MockClient((pedido) async {
              pedidos++;
              if (pedido.method == 'PUT') return respuesta.future;
              return http.Response(perfilJson(), 200);
            }),
          ),
        ),
      );
      await sesion.signIn('a@b.com', 'Clave1234');
      final edicion = sesion.updateProfile(
        firstName: 'Agustín',
        lastName: 'Mosse',
        dni: '42118507',
        birthDate: '2000-03-14',
      );
      await sesion.close();
      respuesta.complete(http.Response(perfilJson(), 200));

      await expectLater(edicion, throwsA(isA<SessionExpired>()));
      expect(sesion.profile, isNull);
      expect(pedidos, 2);
    },
  );

  test('un 409 de la edición se marca como dato repetido', () async {
    final sesion = Session(
      repository: SessionRepository(
        credentials: CredencialesFalsas(),
        api: apiRutas({
          'GET /yo': (200, perfilJson()),
          'PUT /yo': (
            409,
            '{"errores": {"dni": "Este DNI ya está registrado"}}',
          ),
        }),
      ),
    );
    await sesion.signIn('a@b.com', 'Clave1234');
    await expectLater(
      sesion.updateProfile(
        firstName: 'N',
        lastName: 'M',
        dni: '30111222',
        birthDate: '2000-03-14',
      ),
      throwsA(
        isA<DataRejected>().having((e) => e.duplicate, 'repetido', isTrue),
      ),
    );
  });

  test('cerrar la sesión olvida el perfil', () async {
    final credenciales = CredencialesFalsas();
    final sesion = Session(
      repository: SessionRepository(
        credentials: credenciales,
        api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
      ),
    );
    await sesion.signIn('a@b.com', 'Clave1234');
    await sesion.close();
    expect(sesion.profile, isNull);
    expect(credenciales.hasAccount, isFalse);
  });
}

class _SalirFalla extends CredencialesFalsas {
  @override
  Future<void> signOut() async => throw StateError('signOut falló');
}
