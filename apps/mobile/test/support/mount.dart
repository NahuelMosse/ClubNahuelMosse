import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/data/credentials.dart';
import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/bookings.dart';
import 'package:clubnahuelmosse/features/bookings/data/bookings_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:clubnahuelmosse/features/session/domain/profile.dart';
import 'package:clubnahuelmosse/features/session/domain/role.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/common/pending_booking.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

/// The login notice when the credentials are rejected, in Spanish.
const invalidCredentialsMessage =
    'No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.';

/// An API client that always answers [status] with [body], without a network.
ApiClient fakeApi({
  int status = 201,
  String body = '{"id": "00000000-0000-7000-8000-000000000001"}',
}) => ApiClient(
  'http://api.falsa',
  client: MockClient(
    (_) async => http.Response.bytes(
      utf8.encode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ),
  ),
);

/// An API client that answers by `METHOD /path`; what is missing is a 404.
/// Keeps every request in [requests] to assert what was sent.
ApiClient apiRoutes(
  Map<String, (int, String)> responses, {
  List<http.Request>? requests,
}) => ApiClient(
  'http://api.falsa',
  client: MockClient((request) async {
    requests?.add(request);
    final (status, body) =
        responses['${request.method} ${request.url.path}'] ?? (404, '{}');
    return http.Response.bytes(
      utf8.encode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }),
);

const _catalogJson =
    '{"sports": ['
    '{"key": "Futbol", "name": "Fútbol", "kinds": ['
    '{"key": "F5", "name": "Fútbol 5"}, {"key": "F7", "name": "Fútbol 7"}]}, '
    '{"key": "Tenis", "name": "Tenis", "kinds": ['
    '{"key": "PDL", "name": "Polvo de ladrillo"}]}, '
    '{"key": "Padel", "name": "Pádel", "kinds": [{"key": "PAD", "name": "Pádel"}]}, '
    '{"key": "Voley", "name": "Vóley", "kinds": [{"key": "IND", "name": "Indoor"}]}, '
    '{"key": "Basquet", "name": "Básquet", "kinds": [{"key": "B5", "name": "Básquet 5"}]}, '
    '{"key": "Hockey", "name": "Hockey", "kinds": [{"key": "H7", "name": "Hockey 7"}]}, '
    '{"key": "Golf", "name": "Golf", "kinds": [{"key": "DR", "name": "Driving range"}]}'
    ']}';

String _venueJson(String id, String name, String address, int courts) =>
    '{"id": "$id", "name": "$name", "address": "$address", '
    '"opens_at": "08:00", "closes_at": "23:00", "open_days": [1, 2, 3, 4, 5, 6, 7], '
    '"space_count": $courts, "sports": ["Futbol", "Tenis"]}';

const _upcomingJson =
    '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000003", "venue_id": "00000000-0000-7000-8000-000000000002", '
    '"space": "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", '
    '"kind": "F5", "venue": "Sede Morón", "address": "Av. Rivadavia 19850", '
    '"starts_at": "2026-11-13T00:00:00Z", "ends_at": "2026-11-13T01:00:00Z", '
    '"total": 38000, "status": "active", "reason": null, "cancelable": true}';

/// An API with what the Home reads: 4 venues with 17 courts (or, with [oneVenue], one venue
/// with one court), the sports catalog and, with [withBooking], an upcoming booking.
ApiClient homeApi({
  bool withBooking = true,
  bool oneVenue = false,
}) => apiRoutes({
  'GET /bookings': (200, '{"bookings": [${withBooking ? _upcomingJson : ''}]}'),
  'GET /spaces/catalog': (200, _catalogJson),
  'GET /venues': (
    200,
    oneVenue
        ? '{"venues": [${_venueJson('00000000-0000-7000-8000-000000000001', 'Sede Haedo', 'Av. Vergara 1850', 1)}]}'
        : '{"venues": [${_venueJson('00000000-0000-7000-8000-000000000001', 'Sede Haedo', 'Av. Vergara 1850', 6)}, '
              '${_venueJson('00000000-0000-7000-8000-000000000002', 'Sede Morón', 'Av. Rivadavia 19850', 4)}, '
              '${_venueJson('00000000-0000-7000-8000-000000000003', 'Sede Castelar', 'Av. Santa Rosa 1200', 4)}, '
              '${_venueJson('00000000-0000-7000-8000-000000000004', 'Sede Ituzaingó', 'Blas Parera 300', 3)}]}',
  ),
});

/// The Home reading from [homeApi].
Widget fakeHome(
  Session session, {
  bool withBooking = true,
  bool oneVenue = false,
}) {
  final api = homeApi(withBooking: withBooking, oneVenue: oneVenue);
  return HomeScreen(
    session: session,
    bookings: Bookings(BookingsApi(api: api, session: session)),
    spaces: Spaces(
      repository: SpacesRepository(api: api, session: session),
    ),
    venues: Venues(
      repository: VenuesRepository(api: api, session: session),
    ),
  );
}

/// Mounts [screen] with the app's theme and language, on a phone of [size].
Future<void> mountScreen(
  WidgetTester tester,
  Widget screen, {
  required ThemeData theme,
  Size size = const Size(393, 852),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      localeListResolutionCallback: resolveLanguage,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        useLanguage(Localizations.localeOf(context));
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      // A new key makes a second mount in the same test start from a fresh state.
      home: KeyedSubtree(key: UniqueKey(), child: screen),
    ),
  );
  await tester.pumpAndSettle();
}

/// Loads the prototype's fonts and icons: widget tests do not bring them.
Future<void> loadFonts() async {
  const families = {
    'Inter': [
      'assets/fuentes/Inter-Regular.ttf',
      'assets/fuentes/Inter-Medium.ttf',
      'assets/fuentes/Inter-SemiBold.ttf',
      'assets/fuentes/Inter-Bold.ttf',
    ],
    'Archivo': ['assets/fuentes/Archivo-ExtraBold.ttf'],
    'Archivo Black': ['assets/fuentes/ArchivoBlack-Regular.ttf'],
    'JetBrains Mono': ['assets/fuentes/JetBrainsMono-Regular.ttf'],
    'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
  };
  for (final MapEntry(key: family, value: files) in families.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(rootBundle.load(file));
    }
    await loader.load();
  }
}

/// Firebase without a network: [onSignIn] decides what happens with each attempt.
class FakeCredentials implements Credentials {
  FakeCredentials({this.onSignIn, this.withAccount = false});

  final Future<void> Function(String email, String password)? onSignIn;
  bool withAccount;
  final attempts = <(String, String)>[];
  int signOuts = 0;

  @override
  bool get hasAccount => withAccount;

  @override
  Future<void> signIn(String email, String password) async {
    attempts.add((email, password));
    await onSignIn?.call(email, password);
    withAccount = true;
  }

  /// As when Firebase can no longer refresh the session.
  bool tokenFails = false;

  @override
  Future<String?> token() async {
    if (tokenFails) throw const InvalidCredentials();
    return withAccount ? 'token-falso' : null;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    withAccount = false;
  }
}

/// The profile that `GET /yo` returns in the tests.
String profileJson({String role = 'user'}) =>
    '{"first_name": "Nahuel", "last_name": "Mosse", "email": "nahuel@correo.com", '
    '"role": "$role", "dni": "42118507", "birth_date": "2000-03-14"}';

final userProfile = Profile(
  firstName: 'Nahuel',
  lastName: 'Mosse',
  email: 'nmosse@unimoron.edu.ar',
  role: Role.user,
  dni: '42118507',
  birthDate: DateTime(2000, 3, 14),
);

final adminProfile = Profile(
  firstName: 'Ana',
  lastName: 'Díaz',
  email: 'admin@clubnahuelmosse.com',
  role: Role.admin,
  dni: '20000001',
  birthDate: DateTime(1980, 1, 1),
);

/// A session already signed in with the given profile, without Firebase or the API.
class FakeSession extends Session {
  FakeSession(this._fakeProfile)
    : super(
        repository: SessionRepository(
          credentials: FakeCredentials(withAccount: true),
          api: fakeApi(),
        ),
      );

  Profile? _fakeProfile;
  int closes = 0;

  @override
  Profile? get profile => _fakeProfile;

  @override
  Future<Profile> refresh() async {
    final current = _fakeProfile;
    if (current == null) throw const SessionExpired();
    return current;
  }

  @override
  Future<void> close() async {
    closes++;
    _fakeProfile = null;
    notifyListeners();
  }
}

/// The login screen whose credentials are always rejected: the screen as a person first sees it.
Widget loginRejectingCredentials() => LoginScreen(
  pending: PendingBooking(),
  session: Session(
    repository: SessionRepository(
      credentials: FakeCredentials(
        onSignIn: (_, _) async => throw const InvalidCredentials(),
      ),
      api: fakeApi(status: 200, body: profileJson()),
    ),
  ),
);
