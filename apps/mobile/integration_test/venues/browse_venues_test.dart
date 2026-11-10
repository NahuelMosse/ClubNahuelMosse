import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> abrirSedes(WidgetTester tester) async {
    await tapText(tester, 'SEDES');
    await waitUntil(tester, find.text('Sedes'));
  }

  /// La tarjeta de la sede [nombre] en el listado, por su etiqueta accesible.
  Finder tarjeta(String nombre) =>
      find.bySemanticsLabel(RegExp('^${RegExp.escape(nombre)},'));

  Future<void> entrarA(WidgetTester tester, String nombre) async {
    await waitUntil(tester, tarjeta(nombre));
    await tester.ensureVisible(tarjeta(nombre));
    await tester.pumpAndSettle();
    await tester.tap(tarjeta(nombre));
    await tester.pumpAndSettle();
  }

  testWidgets(
    've el listado de sedes con nombre, dirección, horario, cantidad de canchas y deportes @CU-16-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Ituzaingó ${unique()}';
      await createVenue(nombre, 'Av. Ratti 1400');
      await createSpace(nombre);
      await createSpace(nombre, deporte: 'Tenis', tipo: 'PDL');
      await signInAsUser(tester, correo: 'socio.${unique()}@correo.com');

      await abrirSedes(tester);

      // Verifica: la tarjeta muestra la sede con su horario, sus canchas y sus deportes.
      await waitUntil(
        tester,
        find.bySemanticsLabel(
          '$nombre, Av. Ratti 1400, Lunes a domingo de 08:00 a 23:00, '
          '2 canchas: Fútbol, Tenis',
        ),
      );
      expect(find.text(nombre.toUpperCase()), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'entra a una sede y ve todas sus canchas con el contador total y los datos de cada una @CU-16-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Ituzaingó ${unique()}';
      await createVenue(nombre, 'Av. Ratti 1400');
      final futbol = await createSpace(nombre);
      final tenis = await createSpace(nombre, deporte: 'Tenis', tipo: 'PDL');
      await signInAsUser(tester, correo: 'socio.${unique()}@correo.com');
      await abrirSedes(tester);

      await entrarA(tester, nombre);

      // Verifica: la sede muestra su portada con el contador y cada cancha con sus datos.
      await waitUntil(tester, find.text('2 CANCHAS · TODOS LOS DEPORTES'));
      expect(find.text(nombre.toUpperCase()), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Fútbol 5, $futbol, Techada, Iluminada, 43.000 pesos por hora',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Tenis, $tenis, Techada, Iluminada, 43.000 pesos por hora',
        ),
        findsOneWidget,
      );
      expect(find.text('VER HORARIOS / RESERVAR'), findsNWidgets(2));
      semantica.dispose();
    },
  );

  testWidgets(
    'una sede recién cargada con su cancha aparece en el listado con esa cancha @CU-16-H01-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Ituzaingó ${unique()}';
      await signInAsUser(tester, correo: 'socio.${unique()}@correo.com');
      await abrirSedes(tester);
      expect(tarjeta(nombre), findsNothing);

      // El administrador la carga mientras el usuario ya tiene la app abierta.
      await createVenue(nombre, 'Av. Ratti 1400');
      final cancha = await createSpace(nombre);
      await tapText(tester, 'INICIO');
      await abrirSedes(tester);

      // Verifica: aparece con su cancha, y adentro está esa cancha.
      await waitUntil(
        tester,
        find.bySemanticsLabel(
          '$nombre, Av. Ratti 1400, Lunes a domingo de 08:00 a 23:00, '
          '1 cancha: Fútbol',
        ),
      );
      await entrarA(tester, nombre);
      await waitUntil(tester, find.text('1 CANCHA · TODOS LOS DEPORTES'));
      expect(find.text(cancha), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets('desde una cancha pasa a consultar sus horarios @CU-16-H01-04', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final nombre = 'Sede Ituzaingó ${unique()}';
    await createVenue(nombre, 'Av. Ratti 1400');
    await createSpace(nombre);
    await signInAsUser(tester, correo: 'socio.${unique()}@correo.com');
    await abrirSedes(tester);
    await entrarA(tester, nombre);
    await waitUntil(tester, find.text('1 CANCHA · TODOS LOS DEPORTES'));

    await tapText(tester, 'VER HORARIOS / RESERVAR');

    // Verifica: llega a los horarios de esa sede con esa cancha elegida.
    await waitUntil(tester, find.text('SELECCIONÁ CANCHA'));
    expect(find.text(nombre.toUpperCase()), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Cancha 1, Techada'))
          .flagsCollection
          .isSelected,
      isTrue,
    );
    semantica.dispose();
  });

  testWidgets(
    'entra a una sede sin canchas y ve el aviso con el contador en cero @CU-16-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unique()}';
      await createVenue(nombre, 'Av. Vergara 1850');
      await signInAsUser(tester, correo: 'socio.${unique()}@correo.com');
      await abrirSedes(tester);

      await entrarA(tester, nombre);

      // Verifica: la portada con el contador en cero y el aviso en lugar del listado.
      await waitUntil(tester, find.text('0 CANCHAS'));
      expect(find.text(nombre.toUpperCase()), findsOneWidget);
      expect(find.text('Todavía no hay canchas'), findsOneWidget);
      expect(
        find.text('Esta sede no tiene canchas disponibles por el momento.'),
        findsOneWidget,
      );
      expect(find.text('VER HORARIOS / RESERVAR'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets('vuelve a «Todas las sedes» desde una sede @CU-16-H03-01', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final nombre = 'Sede Haedo ${unique()}';
    await createVenue(nombre, 'Av. Vergara 1850');
    await signInAsUser(tester, correo: 'socio.${unique()}@correo.com');
    await abrirSedes(tester);
    await entrarA(tester, nombre);
    await waitUntil(tester, find.text('0 CANCHAS'));

    await tapText(tester, 'Todas las sedes');

    // Verifica: vuelve al listado, con la sede que estaba mirando.
    await waitUntil(tester, find.text('Sedes'));
    expect(find.text('0 CANCHAS'), findsNothing);
    expect(tarjeta(nombre), findsOneWidget);
    semantica.dispose();
  });

  testWidgets(
    'sin conexión, ve el error con opción de reintentar y sigue en la misma pantalla @CU-16-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unique()}';
      await createVenue(nombre, 'Av. Vergara 1850');
      final cancha = await createSpace(nombre);
      final api = await ApiIntermedia.abrir();
      await signInAsUser(
        tester,
        correo: 'socio.${unique()}@correo.com',
        apiUrl: api.url,
      );
      await abrirSedes(tester);
      await waitUntil(tester, tarjeta(nombre));

      api.estado = ApiState.offline;
      await entrarA(tester, nombre);

      // Verifica: avisa sin conexión, y al reintentar con la red de vuelta muestra la sede.
      await waitUntil(tester, find.text('Error de conexión'));
      api.estado = ApiState.normal;
      await tapText(tester, 'REINTENTAR');
      await waitUntil(tester, find.text('1 CANCHA · TODOS LOS DEPORTES'));
      expect(find.text(cancha), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'el servidor falla y no se muestran datos parciales @CU-16-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unique()}';
      await createVenue(nombre, 'Av. Vergara 1850');
      final api = await ApiIntermedia.abrir();
      await signInAsUser(
        tester,
        correo: 'socio.${unique()}@correo.com',
        apiUrl: api.url,
      );

      api.estado = ApiState.failing;
      await tapText(tester, 'SEDES');

      // Verifica: avisa del servidor y no queda ninguna sede a la vista.
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      expect(tarjeta(nombre), findsNothing);
      expect(find.text('Ver canchas'), findsNothing);
      semantica.dispose();
    },
  );
}
