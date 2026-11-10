import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const duplicado =
      'Ya existe un espacio deportivo con ese nombre en la sede seleccionada.';

  /// Una sede propia del test y la parte del nombre compuesto que le corresponde.
  Future<(String, String)> sedePropia() async {
    final s = unique();
    await createVenue('Sede Haedo $s', 'Av. Vergara 1850');
    return ('Sede Haedo $s', 'Haedo${s}_Vergara_1850');
  }

  Future<void> abrirAlta(WidgetTester tester) async {
    await tapText(tester, 'ESPACIOS');
    await waitUntil(tester, find.text('ALTA ESPACIO'));
    await tapText(tester, 'ALTA ESPACIO');
    await waitUntil(tester, find.text('Nuevo espacio deportivo'));
  }

  Future<void> completar(
    WidgetTester tester,
    String sede, {
    String tipo = 'Fútbol 5',
  }) async {
    await choose(tester, 'Sede', sede);
    await choose(tester, 'Deporte', 'Fútbol');
    await choose(tester, 'Tipo', tipo);
    await choose(tester, 'Condición', 'Al aire libre');
    await choose(tester, 'Iluminación', 'Iluminada');
    await typeInto(tester, 'Precio por hora', '38000');
  }

  testWidgets(
    'da de alta un espacio con sede, deporte, tipo y precio, y los usuarios lo ven en la sede @CU-21-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, prefijo) = await sedePropia();
      await signInAsAdmin(tester);
      await abrirAlta(tester);

      await completar(tester, sede);
      await tapText(tester, 'GUARDAR ESPACIO');

      // Verifica: confirma el alta con el nombre del espacio.
      await waitUntil(tester, find.text('¡Espacio deportivo creado!'));
      expect(find.text('${prefijo}_Futbol_F5_1'), findsOneWidget);

      // Verifica: un usuario ya lo ve entre los espacios disponibles.
      expect(await spacesAUserSees(), contains('${prefijo}_Futbol_F5_1'));
      expect((await venuesAUserSees())[sede], 1);
      semantica.dispose();
    },
  );

  testWidgets(
    'el nombre se arma solo con la sede, la dirección, el deporte, el tipo y el siguiente número libre @CU-21-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, prefijo) = await sedePropia();
      await createSpace(sede);
      await signInAsAdmin(tester);
      await abrirAlta(tester);

      // Verifica: sin sede, deporte y tipo no hay nombre todavía.
      expect(find.text('Completá sede, deporte y tipo'), findsOneWidget);

      // Verifica: con un Fútbol 5 ya cargado en la sede, el siguiente es el 2.
      await completar(tester, sede);
      await waitUntil(tester, find.text('${prefijo}_Futbol_F5_2'));

      // Verifica: otro tipo arranca su propia numeración.
      await choose(tester, 'Tipo', 'Fútbol 7');
      await waitUntil(tester, find.text('${prefijo}_Futbol_F7_1'));
      semantica.dispose();
    },
  );

  testWidgets(
    'desde el éxito vuelve al listado o empieza otra alta con el formulario vacío @CU-21-H01-04',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, prefijo) = await sedePropia();
      await signInAsAdmin(tester);
      await abrirAlta(tester);
      await completar(tester, sede);
      await tapText(tester, 'GUARDAR ESPACIO');
      await waitUntil(tester, find.text('¡Espacio deportivo creado!'));

      // Verifica: «Crear otro» abre el formulario vacío.
      await tapText(tester, 'Crear otro');
      await waitUntil(tester, find.text('Nuevo espacio deportivo'));
      expect(find.text('Completá sede, deporte y tipo'), findsOneWidget);
      expect(find.text(sede), findsNothing);

      await completar(tester, sede, tipo: 'Fútbol 7');
      await tapText(tester, 'GUARDAR ESPACIO');
      await waitUntil(tester, find.text('¡Espacio deportivo creado!'));

      // Verifica: «IR AL LISTADO» vuelve al panel con los dos espacios nuevos.
      await tapText(tester, 'IR AL LISTADO');
      await waitUntil(tester, find.text('${prefijo}_Futbol_F7_1'));
      expect(find.text('${prefijo}_Futbol_F5_1'), findsOneWidget);
      expect(find.text('ALTA ESPACIO'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'el nombre calculado ya existe al guardar: ve el error y el número se recalcula @CU-21-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, prefijo) = await sedePropia();
      await signInAsAdmin(tester);
      await abrirAlta(tester);
      await completar(tester, sede);
      await waitUntil(tester, find.text('${prefijo}_Futbol_F5_1'));

      // Otro administrador carga el mismo tipo en la misma sede mientras tanto.
      await createSpace(sede);
      await tapText(tester, 'GUARDAR ESPACIO');

      // Verifica: avisa del duplicado y el nombre pasa al número siguiente.
      await waitUntil(tester, find.text(duplicado));
      await waitUntil(tester, find.text('${prefijo}_Futbol_F5_2'));
      expect(find.text('¡Espacio deportivo creado!'), findsNothing);

      // Verifica: al volver a guardar, queda con el número nuevo.
      await tapText(tester, 'GUARDAR ESPACIO');
      await waitUntil(tester, find.text('¡Espacio deportivo creado!'));
      expect(find.text('${prefijo}_Futbol_F5_2'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets('falta un campo obligatorio y no puede guardar @CU-21-H03-01', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final (sede, prefijo) = await sedePropia();
    await signInAsAdmin(tester);
    await abrirAlta(tester);
    await choose(tester, 'Sede', sede);
    await choose(tester, 'Deporte', 'Fútbol');
    await choose(tester, 'Condición', 'Al aire libre');
    await choose(tester, 'Iluminación', 'Iluminada');
    await typeInto(tester, 'Precio por hora', '38000');

    await tapText(tester, 'GUARDAR ESPACIO');

    // Verifica: marca el tipo como obligatorio y no se crea nada.
    expect(find.text('Este campo es obligatorio'), findsOneWidget);
    expect(find.text('¡Espacio deportivo creado!'), findsNothing);
    expect(
      (await spacesAUserSees()).where((n) => n.startsWith(prefijo)),
      isEmpty,
    );
    semantica.dispose();
  });

  testWidgets(
    'sin conexión o con el servidor caído al guardar, ve el error y conserva lo cargado @CU-21-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, prefijo) = await sedePropia();
      final api = await ProxyApi.open();
      await signInAsAdmin(tester, apiUrl: api.url);
      await abrirAlta(tester);
      await completar(tester, sede);
      await waitUntil(tester, find.text('${prefijo}_Futbol_F5_1'));

      // Verifica: con el servidor caído avisa y lo cargado sigue en el formulario.
      api.state = ApiState.failing;
      await tapText(tester, 'GUARDAR ESPACIO');
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      expect(find.text(sede), findsOneWidget);
      expect(find.text('${prefijo}_Futbol_F5_1'), findsOneWidget);

      // Verifica: sin conexión avisa, y al reintentar con la red de vuelta lo guarda.
      api.state = ApiState.offline;
      await tapText(tester, 'GUARDAR ESPACIO');
      await waitUntil(tester, find.text('Error de conexión'));
      api.state = ApiState.normal;
      await tapText(tester, 'REINTENTAR');
      await waitUntil(tester, find.text('¡Espacio deportivo creado!'));
      expect(await spacesAUserSees(), contains('${prefijo}_Futbol_F5_1'));
      semantica.dispose();
    },
  );
}
