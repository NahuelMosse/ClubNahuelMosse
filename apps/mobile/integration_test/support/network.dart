import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/common/config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

enum ApiState {
  normal,
  offline,
  failing,

  /// Forwards like [normal], but three seconds later: shows what the app displays
  /// while it waits.
  slow,

  /// The API answers as if the session were no longer valid (401), without reaching the
  /// real API: simulates an expired session without waiting for Firebase to expire it.
  sessionExpired,
}

/// An intermediate API on the same device as the app: forwards to the run's API until the
/// scenario cuts it or makes it fail. It simulates the network or the server going down
/// after signing in.
class ProxyApi {
  ProxyApi._(this._server, this._target) {
    _server.listen(_serve);
  }

  static Future<ProxyApi> open() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final api = ProxyApi._(
      server,
      Uri.parse(AppConfig.fromEnvironment().apiUrl),
    );
    addTearDown(() => server.close(force: true));
    return api;
  }

  final HttpServer _server;
  final Uri _target;
  // An idle connection is dropped before the API closes it on its own
  // (its keep-alive is five seconds): so a connection that is already closed is not reused.
  final _client = HttpClient()..idleTimeout = const Duration(seconds: 1);
  ApiState state = ApiState.normal;

  String get url => 'http://127.0.0.1:${_server.port}';

  /// A forward cut halfway (the API closes the connection) reaches the app
  /// as a network that went down, and not as an error of the running scenario.
  Future<void> _serve(HttpRequest request) async {
    try {
      await _forward(request);
    } on Object {
      try {
        (await request.response.detachSocket(writeHeaders: false)).destroy();
      } on Object {
        // The response had already started going out: the connection closes with it.
      }
    }
  }

  Future<void> _forward(HttpRequest request) async {
    switch (state) {
      case ApiState.offline:
        // The connection is cut without a response, as when the signal is lost.
        final socket = await request.response.detachSocket(writeHeaders: false);
        socket.destroy();
      case ApiState.failing:
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      case ApiState.sessionExpired:
        request.response.statusCode = HttpStatus.unauthorized;
        await request.response.close();
      case ApiState.normal:
      case ApiState.slow:
        if (state == ApiState.slow) {
          await Future<void>.delayed(const Duration(seconds: 3));
        }
        final body = await request.fold<List<int>>(
          [],
          (bytes, part) => bytes..addAll(part),
        );
        final (status, headers, response) = await _requestFromApi(
          request,
          body,
        );
        request.response.statusCode = status;
        headers.forEach((name, values) {
          // The length and the connection belong to this hop, not to the API's.
          if (name != HttpHeaders.transferEncodingHeader &&
              name != HttpHeaders.connectionHeader &&
              name != HttpHeaders.contentLengthHeader) {
            for (final value in values) {
              request.response.headers.add(name, value);
            }
          }
        });
        request.response.contentLength = response.length;
        request.response.add(response);
        await request.response.close();
    }
  }

  /// Forwards the whole request to the API and brings back the whole response. If the
  /// connection arrives closed, it tries once more with another.
  Future<(int, HttpHeaders, List<int>)> _requestFromApi(
    HttpRequest request,
    List<int> body,
  ) async {
    for (var attempt = 1; ; attempt++) {
      try {
        final forwarded = await _client.openUrl(
          request.method,
          _target.replace(
            path: request.uri.path,
            query: request.uri.hasQuery ? request.uri.query : null,
          ),
        );
        request.headers.forEach((name, values) {
          if (name != HttpHeaders.hostHeader &&
              name != HttpHeaders.connectionHeader &&
              name != HttpHeaders.contentLengthHeader) {
            for (final value in values) {
              forwarded.headers.add(name, value);
            }
          }
        });
        forwarded.contentLength = body.length;
        forwarded.add(body);
        final response = await forwarded.close();
        final bytes = await response.fold<List<int>>(
          [],
          (all, part) => all..addAll(part),
        );
        return (response.statusCode, response.headers, bytes);
      } on HttpException {
        if (attempt == 2) rethrow;
      }
    }
  }
}

Uri _identity(String method) {
  const emulator = String.fromEnvironment('AUTH_EMULADOR');
  return Uri.parse(
    'http://$emulator/identitytoolkit.googleapis.com/v1/accounts:$method'
    '?key=clave-del-emulador',
  );
}

Future<String?> _token(String email, String password) async {
  final r = await http.post(
    _identity('signInWithPassword'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
      'returnSecureToken': true,
    }),
  );
  if (r.statusCode != 200) return null;
  if (jsonDecode(r.body) case {'idToken': final String token}) return token;
  return null;
}

/// Whether that password works today to sign in, asked to Firebase and not to the app.
Future<bool> canSignIn(String email, String password) async =>
    await _token(email, password) != null;

/// Changes the password from another device: Firebase invalidates the open sessions.
Future<void> changeFromAnotherDevice(
  String email,
  String current,
  String next,
) async {
  // Firebase counts the revocation in seconds: the app's token has to be from a
  // second before the change for it to end up expired.
  await Future<void>.delayed(const Duration(milliseconds: 1100));
  final token = await _token(email, current);
  if (token == null) throw StateError('the current password does not work');
  final r = await http.post(
    _identity('update'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'idToken': token,
      'password': next,
      'returnSecureToken': true,
    }),
  );
  if (r.statusCode != 200) {
    throw StateError('could not change the password: ${r.statusCode}');
  }
}

/// The venues a person with a user account sees today, asked to the run's API
/// and not to the app: name and number of courts of each one.
Future<Map<String, int>> venuesAUserSees() async {
  final email = 'mirada.${DateTime.now().microsecondsSinceEpoch}@correo.com';
  const password = 'ClubNahuel1';
  final api = AppConfig.fromEnvironment().apiUrl;
  final signup = await http.post(
    Uri.parse('$api/registro'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'name': 'Mirada',
      'last_name': 'Externa',
      'dni': (10000000 + DateTime.now().microsecondsSinceEpoch % 89999999)
          .toString(),
      'birth_date': '1995-05-20',
      'email': email,
      'password': password,
    }),
  );
  if (signup.statusCode != 201) {
    throw StateError('signup: ${signup.statusCode}');
  }
  final token = await _token(email, password);
  if (token == null) throw StateError('the new account cannot sign in');
  final r = await http.get(
    Uri.parse('$api/sedes'),
    headers: {'authorization': 'Bearer $token'},
  );
  if (r.statusCode != 200) throw StateError('venues: ${r.statusCode}');
  return {
    if (jsonDecode(utf8.decode(r.bodyBytes)) case {
      'venues': final List<Object?> venues,
    })
      for (final venue in venues)
        if (venue case {'name': final String name, 'space_count': final int n})
          name: n,
  };
}

/// The names of the active spaces a person with a user account sees today.
Future<List<String>> spacesAUserSees() async {
  final email = 'mira.${DateTime.now().microsecondsSinceEpoch}@correo.com';
  const password = 'ClubNahuel1';
  final api = AppConfig.fromEnvironment().apiUrl;
  final signup = await http.post(
    Uri.parse('$api/registro'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'name': 'Mirada',
      'last_name': 'Externa',
      'dni': (10000000 + DateTime.now().microsecondsSinceEpoch % 89999999)
          .toString(),
      'birth_date': '1995-05-20',
      'email': email,
      'password': password,
    }),
  );
  if (signup.statusCode != 201) {
    throw StateError('signup: ${signup.statusCode}');
  }
  final token = await _token(email, password);
  if (token == null) throw StateError('the new account cannot sign in');
  final r = await http.get(
    Uri.parse('$api/espacios'),
    headers: {'authorization': 'Bearer $token'},
  );
  if (r.statusCode != 200) throw StateError('spaces: ${r.statusCode}');
  return [
    if (jsonDecode(utf8.decode(r.bodyBytes)) case {
      'spaces': final List<Object?> spaces,
    })
      for (final space in spaces)
        if (space case {'name': final String name}) name,
  ];
}

/// The session of the administrator that `scripts/e2e.sh` seeds, like that of another phone.
Future<String> _adminToken() async {
  final token = await _token(
    const String.fromEnvironment('ADMIN_CORREO'),
    const String.fromEnvironment('ADMIN_CONTRASENA'),
  );
  if (token == null) throw StateError('the administrator cannot sign in');
  return token;
}

/// A creation in the run's API made by the administrator from another phone.
Future<Map<String, Object?>> _asAdmin(
  String route,
  Map<String, Object?> body,
) async {
  final token = await _adminToken();
  final r = await http.post(
    Uri.parse('${AppConfig.fromEnvironment().apiUrl}$route'),
    headers: {
      'content-type': 'application/json',
      'authorization': 'Bearer $token',
    },
    body: jsonEncode(body),
  );
  if (r.statusCode != 201) throw StateError('$route: ${r.statusCode}');
  final data = jsonDecode(utf8.decode(r.bodyBytes));
  if (data is! Map<String, Object?>) {
    throw StateError('$route: unexpected response');
  }
  return data;
}

/// Creates a venue through the API, open from 08:00 to 23:00 on the given [days] of the week
/// (1 is Monday): every day by default.
Future<void> createVenue(
  String name,
  String address, {
  List<int> days = const [1, 2, 3, 4, 5, 6, 7],
}) async {
  await _asAdmin('/venues', {
    'name': name,
    'address': address,
    'opens_at': '08:00',
    'closes_at': '23:00',
    'open_days': days,
  });
}

/// Today at the club, which is on Argentina time (UTC−3, no daylight saving),
/// whatever the time zone of the test phone.
DateTime todayAtClub() {
  final now = DateTime.now().toUtc().subtract(const Duration(hours: 3));
  return DateTime.utc(now.year, now.month, now.day);
}

/// The o'clock hour that is running now at the club.
int hourAtClub() =>
    DateTime.now().toUtc().subtract(const Duration(hours: 3)).hour;

/// A booking of the space [spaceName] on [day] at [hour] o'clock, for [hours] hours,
/// loaded outside the app: from the account [email] or, if absent, from another
/// person. [status] is `active`, `canceled` or `voided` (with [reason]).
Future<void> occupy(
  String spaceName,
  DateTime day,
  int hour, {
  int hours = 1,
  String? email,
  String status = 'active',
  String? reason,
}) async {
  final date =
      '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
  final r = await http.post(
    _testRoute('reservas'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'space': spaceName,
      'date': date,
      'hora': hour,
      'hours': hours,
      'email': ?email,
      'status': status,
      'reason': ?reason,
    }),
  );
  if (r.statusCode != 204) throw StateError('occupy: ${r.statusCode}');
}

/// Creates through the API the next space of [sport] and [kind] in the venue [venueName],
/// and returns its composed name.
Future<String> createSpace(
  String venueName, {
  String sport = 'Futbol',
  String kind = 'F5',
}) async {
  final api = AppConfig.fromEnvironment().apiUrl;
  final r = await http.get(
    Uri.parse('$api/sedes'),
    headers: {'authorization': 'Bearer ${await _adminToken()}'},
  );
  final venues = jsonDecode(utf8.decode(r.bodyBytes));
  final id = switch (venues) {
    {'venues': final List<Object?> list} => [
      for (final v in list)
        if (v case {'id': final String id, 'name': final String n})
          if (n == venueName) id,
    ].firstOrNull,
    _ => null,
  };
  if (id == null) throw StateError('venue $venueName not found');
  final space = await _asAdmin('/spaces', {
    'venue_id': id,
    'sport': sport,
    'kind': kind,
    // A different court from the one the scenario creates on screen: with the same data and the
    // same account, the API would take it for the same request repeated after a cut.
    'covered': true,
    'lit': true,
    'price_per_hour': 43000,
  });
  final name = space['name'];
  if (name is! String) throw StateError('the creation did not return the name');
  return name;
}

Uri _testRoute(String route) =>
    Uri.parse('${AppConfig.fromEnvironment().apiUrl}/_pruebas/$route');

/// The emails the run's API left in its mailbox for [to], from oldest to
/// newest. In the run emails are not sent: they stay in the mailbox.
Future<List<String>> emailsFor(String to) async {
  final r = await http.get(
    _testRoute('correos?para=${Uri.encodeQueryComponent(to)}'),
  );
  if (r.statusCode != 200) throw StateError('mailbox: ${r.statusCode}');
  final data = jsonDecode(utf8.decode(r.bodyBytes));
  return [
    if (data case {'correos': final List<Object?> emails})
      for (final email in emails)
        if (email case {'body': final String body}) body,
  ];
}

/// The recovery link code of the last email [email] received.
Future<String> lastCode(String email) async {
  final emails = await emailsFor(email);
  if (emails.isEmpty) throw StateError('no email arrived at $email');
  final link = RegExp(r'codigo=([A-Za-z0-9_-]+)').firstMatch(emails.last);
  final code = link?.group(1);
  if (code == null) throw StateError('the email has no link');
  return code;
}

/// Expires the link right now, without waiting the 30 minutes.
Future<void> expireLink(String code) async {
  final r = await http.post(_testRoute('recuperacion/$code/vencer'));
  if (r.statusCode != 204) throw StateError('expire: ${r.statusCode}');
}

/// The upcoming bookings of the account [email], asked to the API and not to the app: the
/// space and the start hour (`HH:MM`, on club time) of each one.
Future<List<(String, String)>> bookingsOf(
  String email, {
  String password = 'ClubNahuel1',
}) async {
  final token = await _token(email, password);
  if (token == null) throw StateError('the account $email cannot sign in');
  final r = await http.get(
    Uri.parse('${AppConfig.fromEnvironment().apiUrl}/reservas?cuando=proximas'),
    headers: {'authorization': 'Bearer $token'},
  );
  if (r.statusCode != 200) throw StateError('bookings: ${r.statusCode}');
  return [
    if (jsonDecode(utf8.decode(r.bodyBytes)) case {
      'bookings': final List<Object?> bookings,
    })
      for (final booking in bookings)
        if (booking case {
          'space': final String space,
          'starts_at': final String start,
        })
          (
            space,
            DateTime.parse(start)
                .toUtc()
                .subtract(const Duration(hours: 3))
                .toIso8601String()
                .substring(11, 16),
          ),
  ];
}

/// The active bookings of [spaceName] become started at the club's current hour,
/// as if time ran while the app is open.
Future<void> startBookingsOf(String spaceName) async {
  final r = await http.post(
    _testRoute('reservas/empezar'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({'space': spaceName}),
  );
  if (r.statusCode != 204) throw StateError('start: ${r.statusCode}');
}

/// The system is left without any booking (nor the notices that mention them).
Future<void> clearBookings() async {
  final r = await http.post(_testRoute('reservas/vaciar'));
  if (r.statusCode != 204) throw StateError('clear: ${r.statusCode}');
}

/// The club voids the active bookings of [spaceName], as an administrator would.
Future<void> voidBookingsOf(String spaceName) async {
  final r = await http.post(
    _testRoute('reservas/anular'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({'space': spaceName}),
  );
  if (r.statusCode != 204) throw StateError('void: ${r.statusCode}');
}

/// The API's reminder sweep runs as if it were [hour]:[minute] at the club
/// on [day], only for the bookings of the account [email], and returns how many notices
/// it registered.
Future<int> dispatchReminders({
  required String email,
  required DateTime day,
  required int hour,
  int minute = 0,
}) async {
  String two(int n) => n.toString().padLeft(2, '0');
  final now =
      '${day.year}-${two(day.month)}-${two(day.day)}T${two(hour)}:${two(minute)}:00-03:00';
  final r = await http.post(
    _testRoute('recordatorios'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({'email': email, 'ahora': now}),
  );
  if (r.statusCode != 200) throw StateError('reminders: ${r.statusCode}');
  if (jsonDecode(utf8.decode(r.bodyBytes)) case {'registrados': final int n}) {
    return n;
  }
  throw StateError('reminders: response without a count');
}

/// Whether the permission of each active device of the account [email] is granted, according
/// to the API and not to the app.
Future<List<bool>> devicesOf(String email) async {
  final r = await http.get(
    _testRoute('dispositivos?correo=${Uri.encodeQueryComponent(email)}'),
  );
  if (r.statusCode != 200) throw StateError('devices: ${r.statusCode}');
  return [
    if (jsonDecode(utf8.decode(r.bodyBytes)) case {
      'dispositivos': final List<Object?> devices,
    })
      for (final d in devices)
        if (d case {'permission_granted': final bool granted}) granted,
  ];
}

/// The numbers of the upcoming bookings of the account [email], according to the API.
Future<List<String>> bookingNumbers(
  String email, {
  String password = 'ClubNahuel1',
}) async {
  final token = await _token(email, password);
  if (token == null) throw StateError('the account $email cannot sign in');
  final r = await http.get(
    Uri.parse('${AppConfig.fromEnvironment().apiUrl}/reservas?cuando=proximas'),
    headers: {'authorization': 'Bearer $token'},
  );
  if (r.statusCode != 200) throw StateError('bookings: ${r.statusCode}');
  return [
    if (jsonDecode(utf8.decode(r.bodyBytes)) case {
      'bookings': final List<Object?> bookings,
    })
      for (final booking in bookings)
        if (booking case {'id': final String id}) id,
  ];
}

/// Another administrator deactivates the venue [name] while the app keeps showing it.
Future<void> deactivateVenueFromAnotherSession(String name) async {
  final r = await http.post(
    _testRoute('sedes/baja'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({'name': name}),
  );
  if (r.statusCode != 204) {
    throw StateError('venue deactivation: ${r.statusCode}');
  }
}

/// The session of a new user account, like that of another person looking at the app.
Future<String> _otherPersonToken() async {
  final email = 'otra.${DateTime.now().microsecondsSinceEpoch}@correo.com';
  const password = 'ClubNahuel1';
  final signup = await http.post(
    Uri.parse('${AppConfig.fromEnvironment().apiUrl}/registro'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'name': 'Mirada',
      'last_name': 'Externa',
      'dni': (10000000 + DateTime.now().microsecondsSinceEpoch % 89999999)
          .toString(),
      'birth_date': '1995-05-20',
      'email': email,
      'password': password,
    }),
  );
  if (signup.statusCode != 201) {
    throw StateError('signup: ${signup.statusCode}');
  }
  final token = await _token(email, password);
  if (token == null) throw StateError('the new account cannot sign in');
  return token;
}

Future<Object?> _read(String route, String token) async {
  final r = await http.get(
    Uri.parse('${AppConfig.fromEnvironment().apiUrl}$route'),
    headers: {'authorization': 'Bearer $token'},
  );
  if (r.statusCode != 200) throw StateError('$route: ${r.statusCode}');
  return jsonDecode(utf8.decode(r.bodyBytes));
}

/// The active venue [name] as a user sees it (address, opening, closing, days), or
/// `null` if they do not see it.
Future<Map<String, Object?>?> venueAUserSees(String name) async {
  final data = await _read('/venues', await _otherPersonToken());
  if (data case {'venues': final List<Object?> venues}) {
    for (final venue in venues) {
      if (venue case final Map<String, Object?> v when v['name'] == name) {
        return v;
      }
    }
  }
  return null;
}

/// The start hours (`HH:MM`) a user can choose on [day] in [spaceName].
Future<List<String>> freeStarts(String spaceName, DateTime day) async {
  final token = await _otherPersonToken();
  final spaces = await _read('/spaces', token);
  final id = switch (spaces) {
    {'spaces': final List<Object?> list} => [
      for (final e in list)
        if (e case {'id': final String id, 'name': final String n})
          if (n == spaceName) id,
    ].firstOrNull,
    _ => null,
  };
  if (id == null) throw StateError('space $spaceName not found');
  final date =
      '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
  final grid = await _read('/spaces/$id/slots?date=$date', token);
  return [
    if (grid case {'slots': final List<Object?> slots})
      for (final f in slots)
        if (f case {'starts_at': final String start, 'available': true}) start,
  ];
}

/// Another administrator deactivates the space [name] while the app keeps showing it.
Future<void> deactivateSpaceFromAnotherSession(String name) async {
  final r = await http.post(
    _testRoute('espacios/baja'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({'space': name}),
  );
  if (r.statusCode != 204) {
    throw StateError('space deactivation: ${r.statusCode}');
  }
}

/// The active space [name] as a user sees it (price, condition, lighting), or
/// `null` if they do not see it.
Future<Map<String, Object?>?> spaceAUserSees(String name) async {
  final data = await _read('/spaces', await _otherPersonToken());
  if (data case {'spaces': final List<Object?> spaces}) {
    for (final space in spaces) {
      if (space case final Map<String, Object?> e when e['name'] == name) {
        return e;
      }
    }
  }
  return null;
}

/// The account [email] books through the API one hour of [spaceName] on [day] at [hour]
/// o'clock, and returns the total that was saved.
Future<int> bookThroughApi(
  String email,
  String spaceName,
  DateTime day,
  int hour, {
  String password = 'ClubNahuel1',
}) async {
  final token = await _token(email, password);
  if (token == null) throw StateError('the account $email cannot sign in');
  final spaces = await _read('/spaces', token);
  final id = switch (spaces) {
    {'spaces': final List<Object?> list} => [
      for (final e in list)
        if (e case {'id': final String id, 'name': final String n})
          if (n == spaceName) id,
    ].firstOrNull,
    _ => null,
  };
  if (id == null) throw StateError('space $spaceName not found');
  final r = await http.post(
    Uri.parse('${AppConfig.fromEnvironment().apiUrl}/reservas'),
    headers: {
      'content-type': 'application/json',
      'authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'space_id': id,
      'date':
          '${day.year}-${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}',
      'start_hour': '${hour.toString().padLeft(2, '0')}:00',
      'hours': 1,
    }),
  );
  if (r.statusCode != 201) throw StateError('book: ${r.statusCode}');
  return switch (jsonDecode(utf8.decode(r.bodyBytes))) {
    {'total': final int total} => total,
    _ => throw StateError('the booking has no total'),
  };
}

/// The totals of the upcoming bookings of the account [email], by start hour
/// (`HH:MM`, on club time).
Future<Map<String, int>> bookingTotals(
  String email, {
  String password = 'ClubNahuel1',
}) async {
  final token = await _token(email, password);
  if (token == null) throw StateError('the account $email cannot sign in');
  final data = await _read('/bookings?when=upcoming', token);
  return {
    if (data case {'bookings': final List<Object?> bookings})
      for (final booking in bookings)
        if (booking case {
          'starts_at': final String start,
          'total': final int total,
        })
          DateTime.parse(start)
                  .toUtc()
                  .subtract(const Duration(hours: 3))
                  .toIso8601String()
                  .substring(11, 16):
              total,
  };
}

/// The account [email] cancels through the API all its upcoming bookings, as if doing it from
/// another phone while the administrator looks at the confirmation.
Future<void> cancelUpcomingOf(
  String email, {
  String password = 'ClubNahuel1',
}) async {
  final token = await _token(email, password);
  if (token == null) throw StateError('the account $email cannot sign in');
  for (final id in await bookingNumbers(email, password: password)) {
    final r = await http.post(
      Uri.parse('${AppConfig.fromEnvironment().apiUrl}/reservas/$id/cancelar'),
      headers: {'authorization': 'Bearer $token'},
    );
    if (r.statusCode != 200) throw StateError('cancel: ${r.statusCode}');
  }
}

/// The booking of [spaceName] as the administrator sees it in the API (status, reason,
/// who voided it and when), or `null` if the space has none.
Future<Map<String, Object?>?> bookingAdminSees(String spaceName) async {
  final data = await _read(
    '/bookings/all?q=${Uri.encodeQueryComponent(spaceName)}',
    await _adminToken(),
  );
  if (data case {'bookings': final List<Object?> bookings}) {
    for (final booking in bookings) {
      if (booking is Map<String, Object?> && booking['space'] == spaceName) {
        return booking;
      }
    }
  }
  return null;
}

/// The history bookings of the account [email] according to the API: the space, the status and
/// the reason of each one.
Future<List<(String, String, String?)>> historyOf(
  String email, {
  String password = 'ClubNahuel1',
}) async {
  final token = await _token(email, password);
  if (token == null) throw StateError('the account $email cannot sign in');
  final data = await _read('/bookings?when=history', token);
  return [
    if (data case {'bookings': final List<Object?> bookings})
      for (final booking in bookings)
        if (booking case {
          'space': final String space,
          'status': final String status,
          'reason': final Object? reason,
        })
          (space, status, reason is String ? reason : null),
  ];
}

/// The account [email] cancels through the API its only upcoming booking, as if doing it from
/// another phone.
Future<void> cancelFromAnotherPhone(
  String email, {
  String password = 'ClubNahuel1',
}) async {
  final token = await _token(email, password);
  if (token == null) throw StateError('the account $email cannot sign in');
  final numbers = await bookingNumbers(email, password: password);
  if (numbers.length != 1) {
    throw StateError('cancel: there are ${numbers.length}');
  }
  final r = await http.post(
    Uri.parse(
      '${AppConfig.fromEnvironment().apiUrl}/reservas/${numbers.single}/cancelar',
    ),
    headers: {'authorization': 'Bearer $token'},
  );
  if (r.statusCode != 200) throw StateError('cancel: ${r.statusCode}');
}

/// An upcoming booking as the person who made it sees it: what the administrator needs to void it.
typedef VoidableBooking = ({String id, String spaceId, String start});

/// The upcoming bookings of the account [email], according to the API, from nearest to farthest.
Future<List<VoidableBooking>> upcomingOf(
  String email, {
  String password = 'ClubNahuel1',
}) async {
  final token = await _token(email, password);
  if (token == null) throw StateError('the account $email cannot sign in');
  final data = await _read('/bookings?when=upcoming', token);
  return [
    if (data case {'bookings': final List<Object?> bookings})
      for (final booking in bookings)
        if (booking case {
          'id': final String id,
          'space_id': final String spaceId,
          'starts_at': final String start,
        })
          (id: id, spaceId: spaceId, start: start),
  ];
}

/// The administrator voids [booking] with [reason] from another phone, through the API, and returns the
/// response status.
Future<int> voidFromAdmin(
  VoidableBooking booking, {
  String reason = 'mantenimiento de la cancha',
}) async {
  final r = await http.post(
    Uri.parse(
      '${AppConfig.fromEnvironment().apiUrl}/reservas/${booking.id}/anular',
    ),
    headers: {
      'content-type': 'application/json',
      'authorization': 'Bearer ${await _adminToken()}',
    },
    body: jsonEncode({
      'reason': reason,
      'space_id': booking.spaceId,
      'starts_at': booking.start,
    }),
  );
  return r.statusCode;
}

/// Waits for the API to register the delivery of the notice of the booking of [spaceName], which goes out
/// after answering the voiding, and returns how it went.
Future<String> waitForNoticeDelivery(String spaceName) async {
  for (var i = 0; i < 40; i++) {
    final booking = await bookingAdminSees(spaceName);
    if (booking?['notice_delivery'] case final String delivery) return delivery;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  throw StateError('the notice of $spaceName was not sent out');
}
