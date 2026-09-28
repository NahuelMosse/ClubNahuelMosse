import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> abrirAlta(WidgetTester tester) async {
    await tocar(tester, 'SEDES');
    await esperarA(tester, find.text('AGREGAR SEDE'));
    await tocar(tester, 'AGREGAR SEDE');
    await esperarA(tester, find.text('Nueva sede'));
  }

  Future<void> completar(
    WidgetTester tester, {
    required String nombre,
    String direccion = 'Av. Vergara 1850',
  }) async {
    await escribir(tester, 'Nombre de la sede', nombre);
    await escribir(tester, 'Dirección', direccion);
    await elegirHora(tester, 'Horario de apertura', '08:00');
    await elegirHora(tester, 'Horario de cierre', '23:00');
  }

  testWidgets(
    'da de alta una sede con nombre, dirección y horario, y aparece en el listado de sedes de los usuarios @CU-17-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await entrarComoAdmin(tester);
      await abrirAlta(tester);

      await completar(tester, nombre: nombre);
      await tocar(tester, 'GUARDAR SEDE');

      // Verifica: confirma el alta con los datos de la sede.
      await esperarA(tester, find.text('¡Sede creada!'));
      expect(find.text('$nombre · Av. Vergara 1850'), findsOneWidget);

      // Verifica: el listado del panel la muestra con su horario.
      await tocar(tester, 'IR AL LISTADO');
      await esperarA(tester, find.text(nombre));
      expect(
        find.bySemanticsLabel(
          RegExp(
            '^${RegExp.escape(nombre)}, Av\\. Vergara 1850, .*'
            'Lunes a domingo de 08:00 a 23:00',
          ),
        ),
        findsOneWidget,
      );

      // Verifica: un usuario ya la ve en su listado de sedes.
      expect((await sedesQueVeUnUsuario()).keys, contains(nombre));
      semantica.dispose();
    },
  );

  testWidgets(
    'la sede recién creada aparece sin canchas hasta que se le cargan espacios @CU-17-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Castelar ${unico()}';
      await entrarComoAdmin(tester);
      await abrirAlta(tester);
      await completar(tester, nombre: nombre, direccion: 'Av. Rivadavia 23500');
      await tocar(tester, 'GUARDAR SEDE');
      await esperarA(tester, find.text('¡Sede creada!'));
      await tocar(tester, 'IR AL LISTADO');
      await esperarA(tester, find.text(nombre));

      // Verifica: en el panel figura con cero canchas.
      expect(
        find.bySemanticsLabel(
          RegExp('^${RegExp.escape(nombre)}, Av\\. Rivadavia 23500, 0 canchas'),
        ),
        findsOneWidget,
      );
      // Verifica: los usuarios también la ven sin canchas.
      expect((await sedesQueVeUnUsuario())[nombre], 0);
      semantica.dispose();
    },
  );

  testWidgets(
    'desde el éxito vuelve al listado o empieza otra alta con el formulario vacío @CU-17-H01-04',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final primera = 'Sede Morón ${unico()}';
      final segunda = 'Sede Ituzaingó ${unico()}';
      await entrarComoAdmin(tester);
      await abrirAlta(tester);
      await completar(
        tester,
        nombre: primera,
        direccion: 'Av. Rivadavia 19850',
      );
      await tocar(tester, 'GUARDAR SEDE');
      await esperarA(tester, find.text('¡Sede creada!'));

      // Verifica: «Crear otra sede» abre el formulario vacío.
      await tocar(tester, 'Crear otra sede');
      await esperarA(tester, find.text('Nueva sede'));
      expect(find.text(primera), findsNothing);
      expect(find.text('Av. Rivadavia 19850'), findsNothing);

      await completar(tester, nombre: segunda, direccion: 'Ratti 1400');
      await tocar(tester, 'GUARDAR SEDE');
      await esperarA(tester, find.text('¡Sede creada!'));

      // Verifica: «IR AL LISTADO» vuelve al panel con las dos sedes nuevas.
      await tocar(tester, 'IR AL LISTADO');
      await esperarA(tester, find.text(segunda));
      expect(find.text(primera), findsOneWidget);
      expect(find.text('AGREGAR SEDE'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'vuelve atrás desde el formulario y no se crea nada @CU-17-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await entrarComoAdmin(tester);
      await abrirAlta(tester);
      await completar(tester, nombre: nombre);

      await tester.tap(find.bySemanticsLabel('Volver'));
      await tester.pumpAndSettle();

      // Verifica: vuelve al listado sin la sede y no quedó guardada.
      await esperarA(tester, find.text('AGREGAR SEDE'));
      expect(find.text('Nueva sede'), findsNothing);
      expect(find.text(nombre), findsNothing);
      expect((await sedesQueVeUnUsuario()).keys, isNot(contains(nombre)));
      semantica.dispose();
    },
  );

  testWidgets(
    'intenta guardar sin dirección o sin horario y se le marcan los campos obligatorios @CU-17-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await entrarComoAdmin(tester);
      await abrirAlta(tester);
      await escribir(tester, 'Nombre de la sede', nombre);
      await elegirHora(tester, 'Horario de apertura', '08:00');

      await tocar(tester, 'GUARDAR SEDE');

      // Verifica: no envía y marca cada campo que falta.
      expect(find.text('La dirección es obligatoria'), findsOneWidget);
      expect(find.text('El horario de cierre es obligatorio'), findsOneWidget);
      expect(find.text('¡Sede creada!'), findsNothing);
      expect((await sedesQueVeUnUsuario()).keys, isNot(contains(nombre)));
      semantica.dispose();
    },
  );

  testWidgets(
    'sin conexión o con el servidor caído al guardar, ve el error y conserva lo cargado @CU-17-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      final api = await ApiIntermedia.abrir();
      await entrarComoAdmin(tester, apiUrl: api.url);
      await abrirAlta(tester);
      await completar(tester, nombre: nombre);

      // Verifica: con el servidor caído avisa y lo cargado sigue en el formulario.
      api.estado = EstadoApi.falla;
      await tocar(tester, 'GUARDAR SEDE');
      await esperarA(tester, find.text('Error del servidor'));
      await tocar(tester, 'ACEPTAR');
      expect(find.text(nombre), findsOneWidget);
      expect(find.text('Av. Vergara 1850'), findsOneWidget);

      // Verifica: sin conexión avisa, y al reintentar con la red de vuelta la guarda.
      api.estado = EstadoApi.sinRed;
      await tocar(tester, 'GUARDAR SEDE');
      await esperarA(tester, find.text('Error de conexión'));
      api.estado = EstadoApi.normal;
      await tocar(tester, 'REINTENTAR');
      await esperarA(tester, find.text('¡Sede creada!'));
      expect((await sedesQueVeUnUsuario()).keys, contains(nombre));
      semantica.dispose();
    },
  );
}
