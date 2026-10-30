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

  /// Del panel a la edición de la sede [nombre].
  Future<void> abrirEdicion(WidgetTester tester, String nombre) async {
    await tocar(tester, 'SEDES');
    await esperarA(tester, find.text('AGREGAR SEDE'));
    await tocarEtiqueta(tester, 'Editar sede $nombre');
    await esperarA(tester, find.text('Editar sede'));
  }

  testWidgets(
    'cambia la dirección de una sede y el listado de usuarios muestra la nueva @CU-18-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      await entrarComoAdmin(tester);
      await abrirEdicion(tester, nombre);

      await escribir(tester, 'Dirección', 'Av. Vergara 1900');
      await tocar(tester, 'GUARDAR CAMBIOS');

      // Verifica: el aviso, y el listado del panel con la dirección nueva.
      await esperarA(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );
      await esperarA(
        tester,
        find.bySemanticsLabel(
          RegExp('^${RegExp.escape(nombre)}, Av\\. Vergara 1900, '),
        ),
      );
      // Verifica: un usuario ve la sede con la dirección nueva.
      expect(
        (await sedeQueVeUnUsuario(nombre))?['address'],
        'Av. Vergara 1900',
      );
      semantica.dispose();
    },
  );

  testWidgets(
    'después de editar, las reservas existentes siguen asociadas a la sede @CU-18-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      final cancha = await crearEspacio(nombre);
      final correo = 'socio.${unico()}@correo.com';
      await crearCuenta(correo: correo, contrasena: 'ClubNahuel1');
      await ocupar(cancha, manana, 21, correo: correo);
      await entrarComoAdmin(tester);
      await abrirEdicion(tester, nombre);

      await escribir(tester, 'Nombre de la sede', '$nombre Norte');
      await escribir(tester, 'Dirección', 'Av. Vergara 1900');
      await tocar(tester, 'GUARDAR CAMBIOS');
      await esperarA(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );

      // Verifica: la reserva sigue, en la misma cancha, con su nombre de siempre.
      expect(await reservasDe(correo), [(cancha, '21:00')]);
      expect((await sedeQueVeUnUsuario('$nombre Norte'))?['space_count'], 1);
      semantica.dispose();
    },
  );

  testWidgets('vuelve atrás sin guardar y nada cambia @CU-18-H02-01', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final nombre = 'Sede Haedo ${unico()}';
    await crearSede(nombre, 'Av. Vergara 1850');
    await entrarComoAdmin(tester);
    await abrirEdicion(tester, nombre);
    await escribir(tester, 'Dirección', 'Av. Vergara 1900');

    await tester.tap(find.bySemanticsLabel('Volver'));
    await tester.pumpAndSettle();

    // Verifica: el listado y la API siguen con la dirección de antes.
    await esperarA(tester, find.text('AGREGAR SEDE'));
    expect(
      find.bySemanticsLabel(
        RegExp('^${RegExp.escape(nombre)}, Av\\. Vergara 1850, '),
      ),
      findsOneWidget,
    );
    expect(
      (await sedeQueVeUnUsuario(nombre))?['address'],
      'Av. Vergara 1850',
    );
    semantica.dispose();
  });

  testWidgets(
    'vacía la dirección, ve el aviso de obligatorio y no puede guardar @CU-18-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      await entrarComoAdmin(tester);
      await abrirEdicion(tester, nombre);

      await escribir(tester, 'Dirección', '');

      // Verifica: el aviso en el campo y GUARDAR CAMBIOS deshabilitado.
      expect(find.text('La dirección es obligatoria'), findsOneWidget);
      expect(banderas(tester, 'GUARDAR CAMBIOS').isEnabled, isFalse);
      expect(
        (await sedeQueVeUnUsuario(nombre))?['address'],
        'Av. Vergara 1850',
      );
      semantica.dispose();
    },
  );

  testWidgets(
    'achica el horario con reservas afuera, ve cuántas son, confirma, y esas reservas se mantienen @CU-18-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Morón ${unico()}';
      await crearSede(nombre, 'Av. Rivadavia 19850');
      final una = await crearEspacio(nombre);
      final otra = await crearEspacio(nombre);
      final correo = 'socio.${unico()}@correo.com';
      await crearCuenta(correo: correo, contrasena: 'ClubNahuel1');
      await ocupar(una, manana, 8, correo: correo);
      await ocupar(otra, manana, 8, correo: correo);
      await entrarComoAdmin(tester);
      await abrirEdicion(tester, nombre);

      await elegirHora(tester, 'Horario de apertura', '09:00');
      await tocar(tester, 'GUARDAR CAMBIOS');

      // Verifica: el aviso dice cuántas reservas quedan afuera.
      await esperarA(tester, find.text('¿Guardar el horario nuevo?'));
      expect(
        find.textContaining(
          '2 reservas futuras de $nombre empiezan antes de las 09:00',
        ),
        findsOneWidget,
      );
      await tocar(tester, 'GUARDAR IGUAL');

      // Verifica: se guardó el horario y las dos reservas siguen como estaban.
      await esperarA(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );
      expect((await sedeQueVeUnUsuario(nombre))?['opens_at'], '09:00');
      expect((await reservasDe(correo)).toSet(), {
        (una, '08:00'),
        (otra, '08:00'),
      });
      semantica.dispose();
    },
  );

  testWidgets(
    'después de achicar el horario, ya no se puede reservar fuera del rango nuevo @CU-18-H04-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Morón ${unico()}';
      await crearSede(nombre, 'Av. Rivadavia 19850');
      final cancha = await crearEspacio(nombre);
      await entrarComoAdmin(tester);
      await abrirEdicion(tester, nombre);

      await elegirHora(tester, 'Horario de apertura', '10:00');
      await elegirHora(tester, 'Horario de cierre', '20:00');
      await tocar(tester, 'GUARDAR CAMBIOS');
      await esperarA(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );

      // Verifica: la grilla de mañana va de las 10 a las 19, nada antes ni después.
      final libres = await iniciosLibres(cancha, manana);
      expect(libres.first, '10:00');
      expect(libres.last, '19:00');
      expect(libres, isNot(contains('08:00')));
      expect(libres, isNot(contains('20:00')));
      semantica.dispose();
    },
  );

  testWidgets('elige revisar el horario y no se guarda nada @CU-18-H04-03', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final nombre = 'Sede Morón ${unico()}';
    await crearSede(nombre, 'Av. Rivadavia 19850');
    final cancha = await crearEspacio(nombre);
    await ocupar(cancha, manana, 22);
    await entrarComoAdmin(tester);
    await abrirEdicion(tester, nombre);

    await elegirHora(tester, 'Horario de cierre', '22:00');
    await tocar(tester, 'GUARDAR CAMBIOS');
    await esperarA(tester, find.text('¿Guardar el horario nuevo?'));
    expect(
      find.textContaining(
        '1 reserva futura de $nombre termina después de las 22:00',
      ),
      findsOneWidget,
    );

    await tocar(tester, 'REVISAR EL HORARIO');

    // Verifica: sigue en la edición con lo elegido y la sede no cambió.
    expect(find.text('Editar sede'), findsOneWidget);
    expect(find.text('22:00'), findsOneWidget);
    expect((await sedeQueVeUnUsuario(nombre))?['closes_at'], '23:00');
    semantica.dispose();
  });

  testWidgets(
    'la sede fue dada de baja en otra sesión y se le avisa al guardar @CU-18-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      await entrarComoAdmin(tester);
      await abrirEdicion(tester, nombre);
      await escribir(tester, 'Dirección', 'Av. Vergara 1900');

      await darDeBajaSedeDesdeOtraSesion(nombre);
      await tocar(tester, 'GUARDAR CAMBIOS');

      // Verifica: el aviso y el listado sin esa sede.
      await esperarA(tester, find.text('Esto cambió mientras tanto'));
      await tocar(tester, 'VER LO ACTUALIZADO');
      await esperarA(tester, find.text('AGREGAR SEDE'));
      expect(find.text(nombre), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin conexión al guardar, ve el error y conserva lo escrito @CU-18-H06-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      final api = await ApiIntermedia.abrir();
      await entrarComoAdmin(tester, apiUrl: api.url);
      await abrirEdicion(tester, nombre);
      await escribir(tester, 'Dirección', 'Av. Vergara 1900');

      api.estado = EstadoApi.sinRed;
      await tocar(tester, 'GUARDAR CAMBIOS');

      // Verifica: el aviso, lo escrito sigue y la sede no cambió.
      await esperarA(tester, find.text('Error de conexión'));
      await tocar(tester, 'Volver');
      expect(find.text('Av. Vergara 1900'), findsOneWidget);
      expect(
        (await sedeQueVeUnUsuario(nombre))?['address'],
        'Av. Vergara 1850',
      );

      // Verifica: con la red de vuelta, guardar funciona.
      api.estado = EstadoApi.normal;
      await tocar(tester, 'GUARDAR CAMBIOS');
      await esperarA(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );
      expect(
        (await sedeQueVeUnUsuario(nombre))?['address'],
        'Av. Vergara 1900',
      );
      semantica.dispose();
    },
  );

  testWidgets('desde la edición pasa a dar de baja la sede @CU-18-H07-01', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final nombre = 'Sede Haedo ${unico()}';
    await crearSede(nombre, 'Av. Vergara 1850');
    await entrarComoAdmin(tester);
    await abrirEdicion(tester, nombre);

    await tocar(tester, 'DAR DE BAJA LA SEDE');

    // Verifica: la confirmación de la baja, con la sede que se está editando.
    await esperarA(tester, find.text('¿Dar de baja la sede?'));
    expect(find.textContaining('$nombre · Av. Vergara 1850'), findsOneWidget);
    semantica.dispose();
  });
}
