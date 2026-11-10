import 'dart:async';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/domain/role.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/mount.dart';

void main() {
  group('resume the saved session', () {
    test('without an account on the device it queries nothing', () async {
      final session = Session(
        repository: SessionRepository(
          credentials: FakeCredentials(),
          api: fakeApi(status: 500),
        ),
      );
      expect(await session.resume(), isNull);
    });

    test('with a valid account it signs in with its role', () async {
      final session = Session(
        repository: SessionRepository(
          credentials: FakeCredentials(withAccount: true),
          api: fakeApi(status: 200, body: profileJson(role: 'admin')),
        ),
      );
      final profile = await session.resume();
      expect(profile?.role, Role.admin);
      expect(profile?.home, '/admin');
      expect(session.profile, same(profile));
    });

    test('if the API no longer recognizes it, it closes it', () async {
      final credentials = FakeCredentials(withAccount: true);
      final session = Session(
        repository: SessionRepository(
          credentials: credentials,
          api: fakeApi(status: 401, body: '{}'),
        ),
      );
      expect(await session.resume(), isNull);
      expect(credentials.signOuts, 1);
    });

    test('with no network or the API down it keeps it for next time', () async {
      final credentials = FakeCredentials(withAccount: true);
      final session = Session(
        repository: SessionRepository(
          credentials: credentials,
          api: fakeApi(status: 503),
        ),
      );
      await expectLater(session.resume(), throwsA(isA<ServerError>()));
      expect(credentials.signOuts, 0);
    });
  });

  test('notifies whoever listens when the profile changes', () async {
    final session = Session(
      repository: SessionRepository(
        credentials: FakeCredentials(),
        api: fakeApi(status: 200, body: profileJson()),
      ),
    );
    var notices = 0;
    session.addListener(() => notices++);
    await session.signIn('a@b.com', 'Clave1234');
    await session.close();
    expect(notices, 2);
  });

  test('a profile with an unknown role is a server error', () async {
    final credentials = FakeCredentials();
    final session = Session(
      repository: SessionRepository(
        credentials: credentials,
        api: fakeApi(status: 200, body: profileJson(role: 'dueño')),
      ),
    );
    await expectLater(
      session.signIn('a@b.com', 'Clave1234'),
      throwsA(isA<ServerError>()),
    );
    expect(credentials.hasAccount, isFalse);
  });

  test('if Firebase cannot sign out, the profile stays', () async {
    final session = Session(
      repository: SessionRepository(
        credentials: _SignOutFails(),
        api: fakeApi(status: 200, body: profileJson()),
      ),
    );
    await session.signIn('a@b.com', 'Clave1234');
    await expectLater(session.close(), throwsA(isA<StateError>()));
    expect(session.profile, isNotNull);
  });

  test(
    'an edit that returns after the session was closed does not revive it',
    () async {
      final response = Completer<http.Response>();
      var requests = 0;
      final session = Session(
        repository: SessionRepository(
          credentials: FakeCredentials(),
          api: ApiClient(
            'http://api.falsa',
            client: MockClient((request) async {
              requests++;
              if (request.method == 'PUT') return response.future;
              return http.Response(profileJson(), 200);
            }),
          ),
        ),
      );
      await session.signIn('a@b.com', 'Clave1234');
      final edit = session.updateProfile(
        firstName: 'Agustín',
        lastName: 'Mosse',
        dni: '42118507',
        birthDate: '2000-03-14',
      );
      await session.close();
      response.complete(http.Response(profileJson(), 200));

      await expectLater(edit, throwsA(isA<SessionExpired>()));
      expect(session.profile, isNull);
      expect(requests, 2);
    },
  );

  test('a 409 on the edit is flagged as a duplicate value', () async {
    final session = Session(
      repository: SessionRepository(
        credentials: FakeCredentials(),
        api: apiRoutes({
          'GET /me': (200, profileJson()),
          'PUT /me': (
            409,
            '{"errors": {"dni": "Este DNI ya está registrado"}}',
          ),
        }),
      ),
    );
    await session.signIn('a@b.com', 'Clave1234');
    await expectLater(
      session.updateProfile(
        firstName: 'N',
        lastName: 'M',
        dni: '30111222',
        birthDate: '2000-03-14',
      ),
      throwsA(
        isA<DataRejected>().having((e) => e.duplicate, 'duplicate', isTrue),
      ),
    );
  });

  test('closing the session forgets the profile', () async {
    final credentials = FakeCredentials();
    final session = Session(
      repository: SessionRepository(
        credentials: credentials,
        api: fakeApi(status: 200, body: profileJson()),
      ),
    );
    await session.signIn('a@b.com', 'Clave1234');
    await session.close();
    expect(session.profile, isNull);
    expect(credentials.hasAccount, isFalse);
  });
}

class _SignOutFails extends FakeCredentials {
  @override
  Future<void> signOut() async => throw StateError('signOut failed');
}
