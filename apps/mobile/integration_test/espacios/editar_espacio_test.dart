import 'dart:ui' show SemanticsFlags;

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

  SemanticsFlags banderas(WidgetTester tester, String etiqueta) =>
      tester.getSemantics(find.bySemanticsLabel(etiqueta)).flagsCollection;

  /// Una sede con una Fútbol 5 techada e iluminada a $ 43.000 la hora.
  Future<String> unEspacio() async {
    final sede = 'Sede Haedo ${unico()}';
    await crearSede(sede, 'Av. Vergara 1850');
    return crearEspacio(sede);
  }

  /// Del panel a la edición del espacio [nombre].
  Future<void> abrirEdicion(WidgetTester tester, String nombre) async {
    await tocar(tester, 'ESPACIOS');
    await esperarA(tester, find.text('ALTA ESPACIO'));
    await tocarEtiqueta(tester, 'Editar $nombre');
    await esperarA(tester, find.text('Editar espacio deportivo'));
  }

  testWidgets(
    'cambia el precio de un espacio y el listado y la sede muestran el nuevo @CU-22-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final cancha = await unEspacio();
      await entrarComoAdmin(tester);
      await abrirEdicion(tester, cancha);

      await escribir(tester, 'Precio por hora', '45000');
      await tocar(tester, 'GUARDAR ESPACIO');

      // Verifica: el aviso, el listado con el precio nuevo y los usuarios lo ven.
      await esperarA(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );
      await esperarA(
        tester,
        find.bySemanticsLabel(
          RegExp('45\\.000 por hora, .*${RegExp.escape(cancha)}\$'),
        ),
      );
      expect((await espacioQueVeUnUsuario(cancha))?['precio_por_hora'], 45000);
      semantica.dispose();
    },
  );

  testWidgets(
    'una reserva hecha antes del cambio conserva su precio y una nueva usa el nuevo @CU-22-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final cancha = await unEspacio();
      final correo = 'socio.${unico()}@correo.com';
      await crearCuenta(correo: correo, contrasena: 'ClubNahuel1');
      expect(await reservarPorLaApi(correo, cancha, manana, 20), 43000);
      await entrarComoAdmin(tester);
      await abrirEdicion(tester, cancha);

      await escribir(tester, 'Precio por hora', '45000');
      await tocar(tester, 'GUARDAR ESPACIO');
      await esperarA(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );

      // Verifica: la de antes sigue a $ 43.000 y la nueva sale a $ 45.000.
      expect(await reservarPorLaApi(correo, cancha, manana, 21), 45000);
      expect(await totalesDeReservas(correo), {'20:00': 43000, '21:00': 45000});
      semantica.dispose();
    },
  );

  testWidgets('sede, deporte y tipo no se pueden editar @CU-22-H01-03', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final cancha = await unEspacio();
    await entrarComoAdmin(tester);

    await abrirEdicion(tester, cancha);

    // Verifica: los tres deshabilitados, con sus valores, y el nombre confirmado.
    expect(banderas(tester, 'Sede').isEnabled, isFalse);
    expect(banderas(tester, 'Deporte').isEnabled, isFalse);
    expect(banderas(tester, 'Tipo').isEnabled, isFalse);
    expect(find.text('Fútbol 5'), findsWidgets);
    expect(find.text(cancha), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('cancela y el precio no cambia @CU-22-H02-01', (tester) async {
    final semantica = tester.ensureSemantics();
    final cancha = await unEspacio();
    await entrarComoAdmin(tester);
    await abrirEdicion(tester, cancha);
    await escribir(tester, 'Precio por hora', '45000');

    await tocar(tester, 'CANCELAR');

    // Verifica: vuelve al listado y el precio sigue siendo el de antes.
    await esperarA(tester, find.text('ALTA ESPACIO'));
    expect((await espacioQueVeUnUsuario(cancha))?['precio_por_hora'], 43000);
    semantica.dispose();
  });

  testWidgets(
    'deja el precio vacío, en cero o con letras y no puede guardar @CU-22-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final cancha = await unEspacio();
      await entrarComoAdmin(tester);
      await abrirEdicion(tester, cancha);

      // Verifica: vacío, el aviso de obligatorio y sin poder guardar.
      await escribir(tester, 'Precio por hora', '');
      expect(find.text('Este campo es obligatorio'), findsOneWidget);
      expect(banderas(tester, 'GUARDAR ESPACIO').isEnabled, isFalse);

      // Verifica: en cero, el aviso del rango.
      await escribir(tester, 'Precio por hora', '0');
      expect(
        find.text('Ingresá un precio entre \$ 1 y \$ 9.999.999'),
        findsOneWidget,
      );
      expect(banderas(tester, 'GUARDAR ESPACIO').isEnabled, isFalse);

      // Verifica: las letras no se escriben.
      await escribir(tester, 'Precio por hora', 'abc');
      expect(find.text('abc'), findsNothing);
      expect(banderas(tester, 'GUARDAR ESPACIO').isEnabled, isFalse);
      expect((await espacioQueVeUnUsuario(cancha))?['precio_por_hora'], 43000);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin modificar nada, el botón de guardar sigue deshabilitado @CU-22-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final cancha = await unEspacio();
      await entrarComoAdmin(tester);

      await abrirEdicion(tester, cancha);

      // Verifica: sin cambios no se puede guardar; con un cambio, sí.
      expect(banderas(tester, 'GUARDAR ESPACIO').isEnabled, isFalse);
      await elegir(tester, 'Condición', 'Al aire libre');
      expect(banderas(tester, 'GUARDAR ESPACIO').isEnabled, isTrue);
      semantica.dispose();
    },
  );

  testWidgets(
    'el espacio fue dado de baja en otra sesión y se le avisa al guardar @CU-22-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final cancha = await unEspacio();
      await entrarComoAdmin(tester);
      await abrirEdicion(tester, cancha);
      await escribir(tester, 'Precio por hora', '45000');

      await darDeBajaEspacioDesdeOtraSesion(cancha);
      await tocar(tester, 'GUARDAR ESPACIO');

      // Verifica: el aviso y el listado sin ese espacio.
      await esperarA(tester, find.text('Esto cambió mientras tanto'));
      await tocar(tester, 'VER LO ACTUALIZADO');
      await esperarA(tester, find.text('ALTA ESPACIO'));
      expect(find.text(cancha), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin conexión al guardar, ve el error y conserva el precio escrito @CU-22-H06-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final cancha = await unEspacio();
      final api = await ApiIntermedia.abrir();
      await entrarComoAdmin(tester, apiUrl: api.url);
      await abrirEdicion(tester, cancha);
      await escribir(tester, 'Precio por hora', '45000');

      api.estado = EstadoApi.sinRed;
      await tocar(tester, 'GUARDAR ESPACIO');

      // Verifica: el aviso, el precio escrito sigue y el espacio no cambió.
      await esperarA(tester, find.text('Error de conexión'));
      await tocar(tester, 'Volver');
      expect(find.textContaining('45.000'), findsOneWidget);
      expect((await espacioQueVeUnUsuario(cancha))?['precio_por_hora'], 43000);

      // Verifica: con la red de vuelta, guardar funciona.
      api.estado = EstadoApi.normal;
      await tocar(tester, 'GUARDAR ESPACIO');
      await esperarA(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );
      expect((await espacioQueVeUnUsuario(cancha))?['precio_por_hora'], 45000);
      semantica.dispose();
    },
  );

  testWidgets('desde la edición pasa a dar de baja el espacio @CU-22-H07-01', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final cancha = await unEspacio();
    await entrarComoAdmin(tester);
    await abrirEdicion(tester, cancha);

    await tocar(tester, 'DAR DE BAJA EL ESPACIO');

    // Verifica: la confirmación de la baja, con el espacio que se está editando.
    await esperarA(tester, find.text('¿Dar de baja el espacio?'));
    expect(find.text('$cancha. La acción es permanente.'), findsOneWidget);
    semantica.dispose();
  });
}
