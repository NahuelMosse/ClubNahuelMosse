import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> abrirSedes(WidgetTester tester) async {
    await tocar(tester, 'SEDES');
    await esperarA(tester, find.text('Sedes'));
  }

  /// La tarjeta de la sede [nombre] en el listado, por su etiqueta accesible.
  Finder tarjeta(String nombre) =>
      find.bySemanticsLabel(RegExp('^${RegExp.escape(nombre)},'));

  Future<void> entrarA(WidgetTester tester, String nombre) async {
    await esperarA(tester, tarjeta(nombre));
    await tester.ensureVisible(tarjeta(nombre));
    await tester.pumpAndSettle();
    await tester.tap(tarjeta(nombre));
    await tester.pumpAndSettle();
  }

  testWidgets(
    've el listado de sedes con nombre, dirección, horario, cantidad de canchas y deportes @CU-16-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Ituzaingó ${unico()}';
      await crearSede(nombre, 'Av. Ratti 1400');
      await crearEspacio(nombre);
      await crearEspacio(nombre, deporte: 'Tenis', tipo: 'PDL');
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');

      await abrirSedes(tester);

      // Verifica: la tarjeta muestra la sede con su horario, sus canchas y sus deportes.
      await esperarA(
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
      final nombre = 'Sede Ituzaingó ${unico()}';
      await crearSede(nombre, 'Av. Ratti 1400');
      final futbol = await crearEspacio(nombre);
      final tenis = await crearEspacio(nombre, deporte: 'Tenis', tipo: 'PDL');
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');
      await abrirSedes(tester);

      await entrarA(tester, nombre);

      // Verifica: la sede muestra su portada con el contador y cada cancha con sus datos.
      await esperarA(tester, find.text('2 CANCHAS · TODOS LOS DEPORTES'));
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
      final nombre = 'Sede Ituzaingó ${unico()}';
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');
      await abrirSedes(tester);
      expect(tarjeta(nombre), findsNothing);

      // El administrador la carga mientras el usuario ya tiene la app abierta.
      await crearSede(nombre, 'Av. Ratti 1400');
      final cancha = await crearEspacio(nombre);
      await tocar(tester, 'INICIO');
      await abrirSedes(tester);

      // Verifica: aparece con su cancha, y adentro está esa cancha.
      await esperarA(
        tester,
        find.bySemanticsLabel(
          '$nombre, Av. Ratti 1400, Lunes a domingo de 08:00 a 23:00, '
          '1 cancha: Fútbol',
        ),
      );
      await entrarA(tester, nombre);
      await esperarA(tester, find.text('1 CANCHA · TODOS LOS DEPORTES'));
      expect(find.text(cancha), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets('desde una cancha pasa a consultar sus horarios @CU-16-H01-04', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final nombre = 'Sede Ituzaingó ${unico()}';
    await crearSede(nombre, 'Av. Ratti 1400');
    final cancha = await crearEspacio(nombre);
    await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');
    await abrirSedes(tester);
    await entrarA(tester, nombre);
    await esperarA(tester, find.text('1 CANCHA · TODOS LOS DEPORTES'));

    await tocar(tester, 'VER HORARIOS / RESERVAR');

    // Verifica: llega a los horarios de esa sede con esa cancha elegida.
    await esperarA(tester, find.text('SELECCIONÁ CANCHA'));
    expect(find.text(nombre.toUpperCase()), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('^${RegExp.escape(cancha)}.*elegida')),
      findsOneWidget,
    );
    semantica.dispose();
  });

  testWidgets(
    'entra a una sede sin canchas y ve el aviso con el contador en cero @CU-16-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');
      await abrirSedes(tester);

      await entrarA(tester, nombre);

      // Verifica: la portada con el contador en cero y el aviso en lugar del listado.
      await esperarA(tester, find.text('0 CANCHAS'));
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
    final nombre = 'Sede Haedo ${unico()}';
    await crearSede(nombre, 'Av. Vergara 1850');
    await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');
    await abrirSedes(tester);
    await entrarA(tester, nombre);
    await esperarA(tester, find.text('0 CANCHAS'));

    await tocar(tester, 'Todas las sedes');

    // Verifica: vuelve al listado, con la sede que estaba mirando.
    await esperarA(tester, find.text('Sedes'));
    expect(find.text('0 CANCHAS'), findsNothing);
    expect(tarjeta(nombre), findsOneWidget);
    semantica.dispose();
  });

  testWidgets(
    'sin conexión, ve el error con opción de reintentar y sigue en la misma pantalla @CU-16-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      final cancha = await crearEspacio(nombre);
      final api = await ApiIntermedia.abrir();
      await entrarComoUsuario(
        tester,
        correo: 'socio.${unico()}@correo.com',
        apiUrl: api.url,
      );
      await abrirSedes(tester);
      await esperarA(tester, tarjeta(nombre));

      api.estado = EstadoApi.sinRed;
      await entrarA(tester, nombre);

      // Verifica: avisa sin conexión, y al reintentar con la red de vuelta muestra la sede.
      await esperarA(tester, find.text('Error de conexión'));
      api.estado = EstadoApi.normal;
      await tocar(tester, 'REINTENTAR');
      await esperarA(tester, find.text('1 CANCHA · TODOS LOS DEPORTES'));
      expect(find.text(cancha), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'el servidor falla y no se muestran datos parciales @CU-16-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      final api = await ApiIntermedia.abrir();
      await entrarComoUsuario(
        tester,
        correo: 'socio.${unico()}@correo.com',
        apiUrl: api.url,
      );

      api.estado = EstadoApi.falla;
      await tocar(tester, 'SEDES');

      // Verifica: avisa del servidor y no queda ninguna sede a la vista.
      await esperarA(tester, find.text('Error del servidor'));
      await tocar(tester, 'ACEPTAR');
      expect(tarjeta(nombre), findsNothing);
      expect(find.text('Ver canchas'), findsNothing);
      semantica.dispose();
    },
  );
}
