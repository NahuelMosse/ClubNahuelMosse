import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final manana = todayAtClub().add(const Duration(days: 1));

  Future<void> tocarEtiqueta(WidgetTester tester, String etiqueta) async {
    final control = find.bySemanticsLabel(etiqueta);
    await waitUntil(tester, control);
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  /// Del panel a la edición de la sede [nombre].
  Future<void> abrirEdicion(WidgetTester tester, String nombre) async {
    await tapText(tester, 'SEDES');
    await waitUntil(tester, find.text('AGREGAR SEDE'));
    await tocarEtiqueta(tester, 'Editar sede $nombre');
    await waitUntil(tester, find.text('Editar sede'));
  }

  /// Desde la edición, hasta el diálogo de confirmación.
  Future<void> pedirLaBaja(WidgetTester tester) async {
    await tapText(tester, 'DAR DE BAJA LA SEDE');
    await waitUntil(tester, find.text('¿Dar de baja la sede?'));
  }

  testWidgets(
    'da de baja una sede sin reservas futuras, ve el éxito y la sede deja de aparecer para los usuarios @CU-19-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unique()}';
      await createVenue(nombre, 'Av. Vergara 1850');
      await createSpace(nombre);
      await signInAsAdmin(tester);
      await abrirEdicion(tester, nombre);
      await pedirLaBaja(tester);

      await tapText(tester, 'DAR DE BAJA');

      // Verifica: el aviso, el listado sin la sede y los usuarios ya no la ven.
      await waitUntil(
        tester,
        find.text('La sede fue dada de baja correctamente'),
      );
      expect(find.text('AGREGAR SEDE'), findsOneWidget);
      expect(find.text(nombre), findsNothing);
      expect(await venueAUserSees(nombre), isNull);
      semantica.dispose();
    },
  );

  testWidgets(
    'después de la baja, los espacios de esa sede no se pueden reservar @CU-19-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unique()}';
      await createVenue(nombre, 'Av. Vergara 1850');
      final cancha = await createSpace(nombre);
      final otra = await createSpace(nombre);
      await signInAsAdmin(tester);
      await abrirEdicion(tester, nombre);
      await pedirLaBaja(tester);

      await tapText(tester, 'DAR DE BAJA');
      await waitUntil(
        tester,
        find.text('La sede fue dada de baja correctamente'),
      );

      // Verifica: ninguna de sus canchas se ofrece para reservar.
      final espacios = await spacesAUserSees();
      expect(espacios, isNot(contains(cancha)));
      expect(espacios, isNot(contains(otra)));
      semantica.dispose();
    },
  );

  testWidgets(
    'inicia la baja desde la tarjeta de la sede en el listado del panel @CU-19-H01-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unique()}';
      await createVenue(nombre, 'Av. Vergara 1850');
      await signInAsAdmin(tester);
      await tapText(tester, 'SEDES');
      await waitUntil(tester, find.text('AGREGAR SEDE'));

      await tocarEtiqueta(tester, 'Dar de baja $nombre');
      await waitUntil(tester, find.text('¿Dar de baja la sede?'));
      expect(find.textContaining('$nombre · Av. Vergara 1850'), findsOneWidget);
      await tapText(tester, 'DAR DE BAJA');

      // Verifica: el aviso y el listado sin la sede.
      await waitUntil(
        tester,
        find.text('La sede fue dada de baja correctamente'),
      );
      expect(find.text(nombre), findsNothing);
      expect(await venueAUserSees(nombre), isNull);
      semantica.dispose();
    },
  );

  testWidgets('cancela en el diálogo y la sede sigue igual @CU-19-H02-01', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final nombre = 'Sede Haedo ${unique()}';
    await createVenue(nombre, 'Av. Vergara 1850');
    await signInAsAdmin(tester);
    await abrirEdicion(tester, nombre);
    await pedirLaBaja(tester);

    await tapText(tester, 'CANCELAR');

    // Verifica: sigue en la edición y la sede sigue activa.
    expect(find.text('¿Dar de baja la sede?'), findsNothing);
    expect(find.text('Editar sede'), findsOneWidget);
    expect(await venueAUserSees(nombre), isNotNull);
    semantica.dispose();
  });

  testWidgets(
    'la sede ya fue dada de baja en otra sesión y se le avisa que no está disponible @CU-19-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unique()}';
      await createVenue(nombre, 'Av. Vergara 1850');
      await signInAsAdmin(tester);
      await abrirEdicion(tester, nombre);
      await pedirLaBaja(tester);

      await deactivateVenueFromAnotherSession(nombre);
      await tapText(tester, 'DAR DE BAJA');

      // Verifica: el aviso y el listado actualizado, sin la sede.
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await waitUntil(tester, find.text('AGREGAR SEDE'));
      expect(find.text(nombre), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'la sede tiene reservas futuras y no se permite la baja @CU-19-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unique()}';
      await createVenue(nombre, 'Av. Vergara 1850');
      final cancha = await createSpace(nombre);
      await occupy(cancha, manana, 21);
      await signInAsAdmin(tester);
      await abrirEdicion(tester, nombre);
      await pedirLaBaja(tester);

      await tapText(tester, 'DAR DE BAJA');

      // Verifica: el aviso, y la sede y su cancha siguen disponibles.
      await waitUntil(tester, find.text('No se puede dar de baja la sede'));
      expect(
        find.text(
          'La sede posee reservas futuras asociadas a sus espacios deportivos. '
          'Gestionalas primero.',
        ),
        findsOneWidget,
      );
      await tapText(tester, 'ACEPTAR');
      expect(find.text('Editar sede'), findsOneWidget);
      expect(await venueAUserSees(nombre), isNotNull);
      expect(await spacesAUserSees(), contains(cancha));
      semantica.dispose();
    },
  );

  testWidgets(
    'falla la baja, ve el error y sigue en la edición con la sede intacta @CU-19-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unique()}';
      await createVenue(nombre, 'Av. Vergara 1850');
      final api = await ApiIntermedia.abrir();
      await signInAsAdmin(tester, apiUrl: api.url);
      await abrirEdicion(tester, nombre);
      await pedirLaBaja(tester);

      api.estado = ApiState.failing;
      await tapText(tester, 'DAR DE BAJA');

      // Verifica: el error, sigue en la edición y la sede está activa.
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      expect(find.text('Editar sede'), findsOneWidget);
      expect(await venueAUserSees(nombre), isNotNull);
      semantica.dispose();
    },
  );
}
