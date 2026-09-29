import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tocarEtiqueta(WidgetTester tester, String etiqueta) async {
    final control = find.bySemanticsLabel(etiqueta);
    await esperarA(tester, control);
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  /// Una sede con dos Fútbol 5: devuelve la sede y las dos canchas.
  Future<(String, String, String)> sedeConDos() async {
    final sede = 'Sede Haedo ${unico()}';
    await crearSede(sede, 'Av. Vergara 1850');
    return (sede, await crearEspacio(sede), await crearEspacio(sede));
  }

  /// Del panel a la confirmación de la baja de [nombre].
  Future<void> pedirLaBaja(WidgetTester tester, String nombre) async {
    await tocar(tester, 'ESPACIOS');
    await esperarA(tester, find.text('ALTA ESPACIO'));
    await tocarEtiqueta(tester, 'Baja $nombre');
    await esperarA(tester, find.text('¿Dar de baja el espacio?'));
  }

  testWidgets(
    'da de baja un espacio y deja de aparecer en el panel y en la sede para los usuarios @CU-23-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (_, cancha, _) = await sedeConDos();
      await entrarComoAdmin(tester);
      await pedirLaBaja(tester, cancha);
      expect(find.text('$cancha. La acción es permanente.'), findsOneWidget);

      await tocar(tester, 'CONFIRMAR BAJA');

      // Verifica: el aviso, el panel sin el espacio y los usuarios ya no lo ven.
      await esperarA(
        tester,
        find.text('El espacio fue dado de baja correctamente'),
      );
      expect(find.text('ALTA ESPACIO'), findsOneWidget);
      expect(find.text(cancha), findsNothing);
      expect(await espacioQueVeUnUsuario(cancha), isNull);
      semantica.dispose();
    },
  );

  testWidgets(
    'después de la baja, la sede muestra un espacio menos @CU-23-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, cancha, _) = await sedeConDos();
      expect((await sedeQueVeUnUsuario(sede))?['canchas'], 2);
      await entrarComoAdmin(tester);
      await pedirLaBaja(tester, cancha);

      await tocar(tester, 'CONFIRMAR BAJA');
      await esperarA(
        tester,
        find.text('El espacio fue dado de baja correctamente'),
      );

      // Verifica: la sede queda con una cancha.
      expect((await sedeQueVeUnUsuario(sede))?['canchas'], 1);
      semantica.dispose();
    },
  );

  testWidgets(
    'después de la baja, el espacio no se puede reservar @CU-23-H01-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (_, cancha, otra) = await sedeConDos();
      await entrarComoAdmin(tester);
      await pedirLaBaja(tester, cancha);

      await tocar(tester, 'CONFIRMAR BAJA');
      await esperarA(
        tester,
        find.text('El espacio fue dado de baja correctamente'),
      );

      // Verifica: no se ofrece para reservar; la otra cancha de la sede sí.
      final espacios = await espaciosQueVeUnUsuario();
      expect(espacios, isNot(contains(cancha)));
      expect(espacios, contains(otra));
      semantica.dispose();
    },
  );

  testWidgets(
    'cancela en la confirmación y el espacio sigue igual @CU-23-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (_, cancha, _) = await sedeConDos();
      await entrarComoAdmin(tester);
      await pedirLaBaja(tester, cancha);

      await tocar(tester, 'CANCELAR');

      // Verifica: sigue en el panel y el espacio sigue activo.
      expect(find.text('¿Dar de baja el espacio?'), findsNothing);
      expect(find.text(cancha), findsOneWidget);
      expect(await espacioQueVeUnUsuario(cancha), isNotNull);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin conexión o con el servidor caído al confirmar, el espacio no se da de baja @CU-23-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (_, cancha, _) = await sedeConDos();
      final api = await ApiIntermedia.abrir();
      await entrarComoAdmin(tester, apiUrl: api.url);
      await pedirLaBaja(tester, cancha);

      api.estado = EstadoApi.sinRed;
      await tocar(tester, 'CONFIRMAR BAJA');

      // Verifica: sin conexión, el aviso y el espacio sigue.
      await esperarA(tester, find.text('Error de conexión'));
      await tocar(tester, 'Volver');
      expect(find.text(cancha), findsOneWidget);
      expect(await espacioQueVeUnUsuario(cancha), isNotNull);

      api.estado = EstadoApi.falla;
      await pedirLaBaja(tester, cancha);
      await tocar(tester, 'CONFIRMAR BAJA');

      // Verifica: con el servidor caído, lo mismo.
      await esperarA(tester, find.text('Error del servidor'));
      await tocar(tester, 'ACEPTAR');
      expect(find.text(cancha), findsOneWidget);
      expect(await espacioQueVeUnUsuario(cancha), isNotNull);
      semantica.dispose();
    },
  );
}
