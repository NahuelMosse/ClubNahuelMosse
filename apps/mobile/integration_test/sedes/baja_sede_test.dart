import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final manana = hoyEnElClub().add(const Duration(days: 1));

  Future<void> tocarEtiqueta(WidgetTester tester, String etiqueta) async {
    final control = find.bySemanticsLabel(etiqueta);
    await esperarA(tester, control);
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  /// Del panel a la edición de la sede [nombre].
  Future<void> abrirEdicion(WidgetTester tester, String nombre) async {
    await tocar(tester, 'SEDES');
    await esperarA(tester, find.text('AGREGAR SEDE'));
    await tocarEtiqueta(tester, 'Editar sede $nombre');
    await esperarA(tester, find.text('Editar sede'));
  }

  /// Desde la edición, hasta el diálogo de confirmación.
  Future<void> pedirLaBaja(WidgetTester tester) async {
    await tocar(tester, 'DAR DE BAJA LA SEDE');
    await esperarA(tester, find.text('¿Dar de baja la sede?'));
  }

  testWidgets(
    'da de baja una sede sin reservas futuras, ve el éxito y la sede deja de aparecer para los usuarios @CU-19-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      await crearEspacio(nombre);
      await entrarComoAdmin(tester);
      await abrirEdicion(tester, nombre);
      await pedirLaBaja(tester);

      await tocar(tester, 'DAR DE BAJA');

      // Verifica: el aviso, el listado sin la sede y los usuarios ya no la ven.
      await esperarA(
        tester,
        find.text('La sede fue dada de baja correctamente'),
      );
      expect(find.text('AGREGAR SEDE'), findsOneWidget);
      expect(find.text(nombre), findsNothing);
      expect(await sedeQueVeUnUsuario(nombre), isNull);
      semantica.dispose();
    },
  );

  testWidgets(
    'después de la baja, los espacios de esa sede no se pueden reservar @CU-19-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      final cancha = await crearEspacio(nombre);
      final otra = await crearEspacio(nombre);
      await entrarComoAdmin(tester);
      await abrirEdicion(tester, nombre);
      await pedirLaBaja(tester);

      await tocar(tester, 'DAR DE BAJA');
      await esperarA(
        tester,
        find.text('La sede fue dada de baja correctamente'),
      );

      // Verifica: ninguna de sus canchas se ofrece para reservar.
      final espacios = await espaciosQueVeUnUsuario();
      expect(espacios, isNot(contains(cancha)));
      expect(espacios, isNot(contains(otra)));
      semantica.dispose();
    },
  );

  testWidgets(
    'inicia la baja desde la tarjeta de la sede en el listado del panel @CU-19-H01-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      await entrarComoAdmin(tester);
      await tocar(tester, 'SEDES');
      await esperarA(tester, find.text('AGREGAR SEDE'));

      await tocarEtiqueta(tester, 'Dar de baja $nombre');
      await esperarA(tester, find.text('¿Dar de baja la sede?'));
      expect(find.textContaining('$nombre · Av. Vergara 1850'), findsOneWidget);
      await tocar(tester, 'DAR DE BAJA');

      // Verifica: el aviso y el listado sin la sede.
      await esperarA(
        tester,
        find.text('La sede fue dada de baja correctamente'),
      );
      expect(find.text(nombre), findsNothing);
      expect(await sedeQueVeUnUsuario(nombre), isNull);
      semantica.dispose();
    },
  );

  testWidgets('cancela en el diálogo y la sede sigue igual @CU-19-H02-01', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final nombre = 'Sede Haedo ${unico()}';
    await crearSede(nombre, 'Av. Vergara 1850');
    await entrarComoAdmin(tester);
    await abrirEdicion(tester, nombre);
    await pedirLaBaja(tester);

    await tocar(tester, 'CANCELAR');

    // Verifica: sigue en la edición y la sede sigue activa.
    expect(find.text('¿Dar de baja la sede?'), findsNothing);
    expect(find.text('Editar sede'), findsOneWidget);
    expect(await sedeQueVeUnUsuario(nombre), isNotNull);
    semantica.dispose();
  });

  testWidgets(
    'la sede ya fue dada de baja en otra sesión y se le avisa que no está disponible @CU-19-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      await entrarComoAdmin(tester);
      await abrirEdicion(tester, nombre);
      await pedirLaBaja(tester);

      await darDeBajaSedeDesdeOtraSesion(nombre);
      await tocar(tester, 'DAR DE BAJA');

      // Verifica: el aviso y el listado actualizado, sin la sede.
      await esperarA(tester, find.text('Esto cambió mientras tanto'));
      await tocar(tester, 'VER LO ACTUALIZADO');
      await esperarA(tester, find.text('AGREGAR SEDE'));
      expect(find.text(nombre), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'la sede tiene reservas futuras y no se permite la baja @CU-19-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      final cancha = await crearEspacio(nombre);
      await ocupar(cancha, manana, 21);
      await entrarComoAdmin(tester);
      await abrirEdicion(tester, nombre);
      await pedirLaBaja(tester);

      await tocar(tester, 'DAR DE BAJA');

      // Verifica: el aviso, y la sede y su cancha siguen disponibles.
      await esperarA(tester, find.text('No se puede dar de baja la sede'));
      expect(
        find.text(
          'La sede posee reservas futuras asociadas a sus espacios deportivos. '
          'Gestionalas primero.',
        ),
        findsOneWidget,
      );
      await tocar(tester, 'ACEPTAR');
      expect(find.text('Editar sede'), findsOneWidget);
      expect(await sedeQueVeUnUsuario(nombre), isNotNull);
      expect(await espaciosQueVeUnUsuario(), contains(cancha));
      semantica.dispose();
    },
  );

  testWidgets(
    'falla la baja, ve el error y sigue en la edición con la sede intacta @CU-19-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      final api = await ApiIntermedia.abrir();
      await entrarComoAdmin(tester, apiUrl: api.url);
      await abrirEdicion(tester, nombre);
      await pedirLaBaja(tester);

      api.estado = EstadoApi.falla;
      await tocar(tester, 'DAR DE BAJA');

      // Verifica: el error, sigue en la edición y la sede está activa.
      await esperarA(tester, find.text('Error del servidor'));
      await tocar(tester, 'ACEPTAR');
      expect(find.text('Editar sede'), findsOneWidget);
      expect(await sedeQueVeUnUsuario(nombre), isNotNull);
      semantica.dispose();
    },
  );
}
