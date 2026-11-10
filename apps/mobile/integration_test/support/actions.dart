import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/common/config.dart';
import 'package:clubnahuelmosse/features/session/data/firebase.dart';
import 'package:clubnahuelmosse/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A value only this test uses: the scenarios assert on their own data.
String unique() => DateTime.now().microsecondsSinceEpoch.toString();

/// An 8-digit DNI derived from [s], so two tests do not collide.
String dniOf(String s) =>
    (10000000 + int.parse(s.substring(s.length - 7))).toString();

/// The administrator account that `scripts/e2e.sh` seeds in the run's database.
const adminEmail = String.fromEnvironment('ADMIN_CORREO');
const adminPassword = String.fromEnvironment('ADMIN_CONTRASENA');

/// A Firebase Auth emulator and an API where nobody listens: the app without a network.
const offline = '127.0.0.1:9';
const offlineApi = 'http://127.0.0.1:9';

/// Starts the real app, against the run's API and Firebase emulator.
///
/// [apiUrl] and [authEmulator] replace the run's to simulate failures.
Future<void> openApp(
  WidgetTester tester, {
  String? apiUrl,
  String? authEmulator,
}) async {
  final config = AppConfig.fromEnvironment().copyWith(
    apiUrl: apiUrl,
    authEmulator: authEmulator,
  );
  // Each scenario starts without the session or theme the previous one left.
  await (await initFirebase(config)).signOut();
  await (await SharedPreferences.getInstance()).clear();
  await app.bootstrap(config);
  await tester.pumpAndSettle();
}

/// Bootstraps the app again as on reopening it: with the session that was left saved.
Future<void> reopenApp(WidgetTester tester) async {
  await app.bootstrap(AppConfig.fromEnvironment());
  await tester.pumpAndSettle();
}

/// Creates an account, opens the app and signs in with it until reaching the Home.
Future<void> signInAsUser(
  WidgetTester tester, {
  required String email,
  String password = 'ClubNahuel1',
  String name = 'Nahuel',
  String? apiUrl,
}) async {
  try {
    await createAccount(email: email, password: password, name: name);
  } on AccountAlreadyCreated {
    // The scenario already registered it to load data before signing in.
  }
  await openApp(tester, apiUrl: apiUrl);
  await typeInto(tester, 'Correo', email);
  await typeInto(tester, 'Contraseña', password);
  await tapText(tester, 'INICIAR SESIÓN');
  await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
}

/// Opens the app and signs in with the administrator account until reaching the panel.
Future<void> signInAsAdmin(WidgetTester tester, {String? apiUrl}) async {
  await openApp(tester, apiUrl: apiUrl);
  await typeInto(tester, 'Correo', adminEmail);
  await typeInto(tester, 'Contraseña', adminPassword);
  await tapText(tester, 'INICIAR SESIÓN');
  await waitUntil(tester, find.text('PANEL ADMIN'));
}

/// Opens the time selector of [field] and picks [time], for example `08:00`.
Future<void> chooseTime(WidgetTester tester, String field, String time) =>
    choose(tester, field, time);

/// Opens the selector of [field] and taps [option].
Future<void> choose(WidgetTester tester, String field, String option) async {
  final selector = find.bySemanticsLabel(field);
  // When the previous selector closes, a text field can regain focus and open the
  // keyboard, which shifts the screen.
  await _waitForStillScreen(tester);
  await tester.ensureVisible(selector);
  await tester.pumpAndSettle();
  await tester.tap(selector);
  await tester.pumpAndSettle();
  final button = find.descendant(
    of: find.byType(Dialog),
    matching: find.text(option),
  );
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

/// What the simulated operating system of the test device answers when the app asks for
/// the notification permission. It is set after opening the app and before signing in.
Future<void> setNotificationPermission({required bool granted}) async {
  await (await SharedPreferences.getInstance()).setString(
    'permiso_notificaciones_simulado',
    granted ? 'concedido' : 'denegado',
  );
}

/// Registers an account through the API, as if the person had already signed up.
Future<void> createAccount({
  required String email,
  required String password,
  String name = 'Nahuel',
}) async {
  final r = await http.post(
    Uri.parse('${AppConfig.fromEnvironment().apiUrl}/registro'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'name': name,
      'last_name': 'Mosse',
      'dni': dniOf(unique()),
      'birth_date': '2000-03-14',
      'email': email,
      'password': password,
    }),
  );
  if (r.statusCode == 409 && _onlyTheEmailIsRepeated(r.body)) {
    throw const AccountAlreadyCreated();
  }
  if (r.statusCode != 201) {
    throw StateError(
      'could not create the test account: ${r.statusCode} ${r.body}',
    );
  }
}

/// The signup 409 says the only repeated field is the email.
bool _onlyTheEmailIsRepeated(String body) {
  if (jsonDecode(body) case {'campos': ['email']}) return true;
  return false;
}

/// The API already has an account with that email.
class AccountAlreadyCreated implements Exception {
  const AccountAlreadyCreated();

  @override
  String toString() => 'the test account already exists (409)';
}

/// An API that answers 500 to everything, on the same device as the app.
Future<String> failingApi() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) {
    request.response.statusCode = HttpStatus.internalServerError;
    request.response.close();
  });
  addTearDown(() => server.close(force: true));
  return 'http://127.0.0.1:${server.port}';
}

/// Waits for [finder] to appear: the network does not say when it finishes.
Future<void> waitUntil(
  WidgetTester tester,
  Finder finder, {
  Duration limit = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(limit);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}

Future<void> tapText(WidgetTester tester, String text) async {
  final button = find.text(text);
  await _waitForStillScreen(tester);
  await tester.ensureVisible(button);
  // The scroll applies on the next frame: without waiting for it, the tap goes to the old position.
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

/// Waits for the device keyboard to finish opening or closing. Android moves it on its own
/// (for example, when a field regains focus as a notice closes) and `pumpAndSettle` does
/// not wait for it: a tap in between lands where the button no longer is.
Future<void> _waitForStillScreen(WidgetTester tester) async {
  final end = DateTime.now().add(const Duration(seconds: 3));
  var previous = tester.view.viewInsets.bottom;
  var still = 0;
  while (still < 4 && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    final now = tester.view.viewInsets.bottom;
    still = now == previous ? still + 1 : 0;
    previous = now;
  }
}

Future<void> typeInto(WidgetTester tester, String field, String value) async {
  final finder = find.bySemanticsLabel(field);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.showKeyboard(finder);
  // Like real typing and not `enterText`: in the real app `enterText` does not tell
  // Android about the change, and a prefilled field can come back with the old text
  // when the device keyboard sends its state.
  tester
      .state<EditableTextState>(
        find.descendant(of: finder, matching: find.byType(EditableText)),
      )
      .userUpdateTextEditingValue(
        TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        ),
        SelectionChangedCause.keyboard,
      );
  await tester.pumpAndSettle();
  // The device keyboard opens and resizes the screen on its own, without
  // `pumpAndSettle` waiting for it: a following tap would land where the button no longer is.
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  final end = DateTime.now().add(const Duration(seconds: 3));
  while (tester.view.viewInsets.bottom > 0 && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

/// Enters a field and leaves it without typing anything.
Future<void> enterAndLeave(WidgetTester tester, String field) async {
  final finder = find.bySemanticsLabel(field);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

/// Opens the app from the link in the recovery email, as Android would.
Future<void> openRecoveryLink(WidgetTester tester, String code) async {
  await tester.binding.handlePushRoute('/recover?code=$code');
  await tester.pumpAndSettle();
}
