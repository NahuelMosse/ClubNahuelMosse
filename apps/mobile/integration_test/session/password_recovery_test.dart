import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const vieja = 'ClubNahuel1';
  const nueva = 'ClubNahuel2';
  const aviso =
      'Si el correo está registrado, te enviamos un enlace para crear una contraseña '
      'nueva. El enlace vence en 30 minutos.';

  Future<void> pedirEnlace(WidgetTester tester, String correo) async {
    await tapText(tester, '¿Olvidaste tu contraseña?');
    await typeInto(tester, 'Correo electrónico', correo);
    await tapText(tester, 'ENVIAR ENLACE');
  }

  Future<void> crearNueva(
    WidgetTester tester, {
    String repetida = nueva,
  }) async {
    await typeInto(tester, 'Contraseña nueva', nueva);
    await typeInto(tester, 'Repetir contraseña', repetida);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  bool habilitado(WidgetTester tester, String boton) =>
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, boton))
          .onPressed !=
      null;

  testWidgets(
    'pide el enlace, crea una contraseña nueva y entra con ella @CU-04b-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unique()}@correo.com';
      await createAccount(email: correo, password: vieja);
      await openApp(tester);

      await pedirEnlace(tester, correo);
      await waitUntil(tester, find.text('Revisá tu correo'));
      expect(find.text(aviso), findsOneWidget);

      // Verifica: el correo trae un enlace que abre la app en la contraseña nueva.
      await openRecoveryLink(tester, await lastCode(correo));
      await waitUntil(tester, find.text('Creá una contraseña nueva'));
      await crearNueva(tester);
      await tapText(tester, 'GUARDAR CONTRASEÑA');
      await waitUntil(tester, find.text('Contraseña actualizada'));

      // Verifica: vuelve al login y la contraseña nueva abre la cuenta.
      await tapText(tester, 'VOLVER AL INICIO DE SESIÓN');
      await typeInto(tester, 'Correo', correo);
      await typeInto(tester, 'Contraseña', nueva);
      await tapText(tester, 'INICIAR SESIÓN');
      await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
      semantica.dispose();
    },
  );

  testWidgets(
    'después de recuperar, la contraseña anterior ya no sirve @CU-04b-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unique()}@correo.com';
      await createAccount(email: correo, password: vieja);
      await openApp(tester);
      await pedirEnlace(tester, correo);
      await waitUntil(tester, find.text('Revisá tu correo'));
      await openRecoveryLink(tester, await lastCode(correo));
      await waitUntil(tester, find.text('Creá una contraseña nueva'));
      await crearNueva(tester);
      await tapText(tester, 'GUARDAR CONTRASEÑA');
      await waitUntil(tester, find.text('Contraseña actualizada'));

      // Verifica: la contraseña olvidada deja de abrir la cuenta.
      expect(await canSignIn(correo, vieja), isFalse);
      expect(await canSignIn(correo, nueva), isTrue);
      semantica.dispose();
    },
  );

  testWidgets(
    'pide el enlace con un correo sin cuenta y ve el mismo mensaje, sin que se envíe mail @CU-04b-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'nadie.${unique()}@correo.com';
      await openApp(tester);

      await pedirEnlace(tester, correo);

      // Verifica: la respuesta no dice si el correo tiene cuenta, y no sale ningún mail.
      await waitUntil(tester, find.text('Revisá tu correo'));
      expect(find.text(aviso), findsOneWidget);
      expect(await emailsFor(correo), isEmpty);
      semantica.dispose();
    },
  );

  testWidgets(
    'escribe un correo con formato inválido y el botón sigue deshabilitado @CU-04b-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await openApp(tester);
      await tapText(tester, '¿Olvidaste tu contraseña?');

      await typeInto(tester, 'Correo electrónico', 'nmosse@unimoron');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      // Verifica: marca el formato y no deja enviar.
      expect(find.text('Revisá el formato del correo'), findsOneWidget);
      expect(habilitado(tester, 'ENVIAR ENLACE'), isFalse);
      semantica.dispose();
    },
  );

  testWidgets(
    'abre un enlace vencido y ve «El enlace no es válido» @CU-04b-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unique()}@correo.com';
      await createAccount(email: correo, password: vieja);
      await openApp(tester);
      await pedirEnlace(tester, correo);
      await waitUntil(tester, find.text('Revisá tu correo'));
      final codigo = await lastCode(correo);
      await expireLink(codigo);

      await openRecoveryLink(tester, codigo);

      // Verifica: el enlace vencido no deja cambiar la contraseña y ofrece pedir otro.
      await waitUntil(tester, find.text('El enlace no es válido'));
      expect(find.text('PEDIR UN ENLACE NUEVO'), findsOneWidget);
      expect(find.text('Creá una contraseña nueva'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'abre un enlace ya usado y ve «El enlace no es válido» @CU-04b-H04-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unique()}@correo.com';
      await createAccount(email: correo, password: vieja);
      await openApp(tester);
      await pedirEnlace(tester, correo);
      await waitUntil(tester, find.text('Revisá tu correo'));
      final codigo = await lastCode(correo);
      await openRecoveryLink(tester, codigo);
      await waitUntil(tester, find.text('Creá una contraseña nueva'));
      await crearNueva(tester);
      await tapText(tester, 'GUARDAR CONTRASEÑA');
      await waitUntil(tester, find.text('Contraseña actualizada'));
      await tapText(tester, 'VOLVER AL INICIO DE SESIÓN');

      await openRecoveryLink(tester, codigo);

      // Verifica: el enlace sirve una sola vez.
      await waitUntil(tester, find.text('El enlace no es válido'));
      expect(await canSignIn(correo, nueva), isTrue);
      semantica.dispose();
    },
  );

  testWidgets(
    'la repetición no coincide y el botón sigue deshabilitado @CU-04b-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unique()}@correo.com';
      await createAccount(email: correo, password: vieja);
      await openApp(tester);
      await pedirEnlace(tester, correo);
      await waitUntil(tester, find.text('Revisá tu correo'));
      await openRecoveryLink(tester, await lastCode(correo));
      await waitUntil(tester, find.text('Creá una contraseña nueva'));

      await crearNueva(tester, repetida: 'ClubNahuel3');

      // Verifica: marca la repetición y no deja guardar.
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(habilitado(tester, 'GUARDAR CONTRASEÑA'), isFalse);
      semantica.dispose();
    },
  );

  testWidgets(
    'reenvía el correo y el enlace anterior deja de servir @CU-04b-H06-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unique()}@correo.com';
      await createAccount(email: correo, password: vieja);
      await openApp(tester);
      await pedirEnlace(tester, correo);
      await waitUntil(tester, find.text('Revisá tu correo'));
      final primero = await lastCode(correo);

      await tapText(tester, 'Reenviar el correo');
      await waitUntil(tester, find.text('Revisá tu correo'));

      // Verifica: llega un segundo correo y el primer enlace ya no vale.
      final correos = await emailsFor(correo);
      expect(correos, hasLength(2));
      expect(await lastCode(correo), isNot(primero));
      await openRecoveryLink(tester, primero);
      await waitUntil(tester, find.text('El enlace no es válido'));
      semantica.dispose();
    },
  );

  testWidgets(
    'sin conexión o con el servidor caído al pedir el enlace, ve el overlay y no cambia nada @CU-04b-H07-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unique()}@correo.com';
      await createAccount(email: correo, password: vieja);
      final api = await ProxyApi.open();
      await openApp(tester, apiUrl: api.url);

      api.state = ApiState.offline;
      await pedirEnlace(tester, correo);
      // Verifica: sin conexión se ve el aviso de conexión y no sale ningún correo.
      await waitUntil(tester, find.text('Error de conexión'));
      await tapText(tester, 'Volver');
      expect(find.text('Revisá tu correo'), findsNothing);

      api.state = ApiState.failing;
      await tapText(tester, 'ENVIAR ENLACE');
      // Verifica: con el servidor caído se ve su aviso, y la contraseña sigue igual.
      await waitUntil(tester, find.text('Error del servidor'));
      expect(await emailsFor(correo), isEmpty);
      expect(await canSignIn(correo, vieja), isTrue);
      semantica.dispose();
    },
  );
}
