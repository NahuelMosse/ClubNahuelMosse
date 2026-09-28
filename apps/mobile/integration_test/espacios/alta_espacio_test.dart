import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const duplicado =
      'Ya existe un espacio deportivo con ese nombre en la sede seleccionada.';

  /// Una sede propia del test y la parte del nombre compuesto que le corresponde.
  Future<(String, String)> sedePropia() async {
    final s = unico();
    await crearSede('Sede Haedo $s', 'Av. Vergara 1850');
    return ('Sede Haedo $s', 'Haedo${s}_Vergara_1850');
  }

  Future<void> abrirAlta(WidgetTester tester) async {
    await tocar(tester, 'ESPACIOS');
    await esperarA(tester, find.text('ALTA ESPACIO'));
    await tocar(tester, 'ALTA ESPACIO');
    await esperarA(tester, find.text('Nuevo espacio deportivo'));
  }

  Future<void> completar(
    WidgetTester tester,
    String sede, {
    String tipo = 'Fútbol 5',
  }) async {
    await elegir(tester, 'Sede', sede);
    await elegir(tester, 'Deporte', 'Fútbol');
    await elegir(tester, 'Tipo', tipo);
    await elegir(tester, 'Condición', 'Al aire libre');
    await elegir(tester, 'Iluminación', 'Iluminada');
    await escribir(tester, 'Precio por hora', '38000');
  }

  testWidgets(
    'da de alta un espacio con sede, deporte, tipo y precio, y los usuarios lo ven en la sede @CU-21-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, prefijo) = await sedePropia();
      await entrarComoAdmin(tester);
      await abrirAlta(tester);

      await completar(tester, sede);
      await tocar(tester, 'GUARDAR ESPACIO');

      // Verifica: confirma el alta con el nombre del espacio.
      await esperarA(tester, find.text('¡Espacio deportivo creado!'));
      expect(find.text('${prefijo}_Futbol_F5_1'), findsOneWidget);

      // Verifica: un usuario ya lo ve entre los espacios disponibles.
      expect(
        await espaciosQueVeUnUsuario(),
        contains('${prefijo}_Futbol_F5_1'),
      );
      expect((await sedesQueVeUnUsuario())[sede], 1);
      semantica.dispose();
    },
  );

  testWidgets(
    'el nombre se arma solo con la sede, la dirección, el deporte, el tipo y el siguiente número libre @CU-21-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, prefijo) = await sedePropia();
      await crearEspacio(sede);
      await entrarComoAdmin(tester);
      await abrirAlta(tester);

      // Verifica: sin sede, deporte y tipo no hay nombre todavía.
      expect(find.text('Completá sede, deporte y tipo'), findsOneWidget);

      // Verifica: con un Fútbol 5 ya cargado en la sede, el siguiente es el 2.
      await completar(tester, sede);
      await esperarA(tester, find.text('${prefijo}_Futbol_F5_2'));

      // Verifica: otro tipo arranca su propia numeración.
      await elegir(tester, 'Tipo', 'Fútbol 7');
      await esperarA(tester, find.text('${prefijo}_Futbol_F7_1'));
      semantica.dispose();
    },
  );

  testWidgets(
    'desde el éxito vuelve al listado o empieza otra alta con el formulario vacío @CU-21-H01-04',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, prefijo) = await sedePropia();
      await entrarComoAdmin(tester);
      await abrirAlta(tester);
      await completar(tester, sede);
      await tocar(tester, 'GUARDAR ESPACIO');
      await esperarA(tester, find.text('¡Espacio deportivo creado!'));

      // Verifica: «Crear otro» abre el formulario vacío.
      await tocar(tester, 'Crear otro');
      await esperarA(tester, find.text('Nuevo espacio deportivo'));
      expect(find.text('Completá sede, deporte y tipo'), findsOneWidget);
      expect(find.text(sede), findsNothing);

      await completar(tester, sede, tipo: 'Fútbol 7');
      await tocar(tester, 'GUARDAR ESPACIO');
      await esperarA(tester, find.text('¡Espacio deportivo creado!'));

      // Verifica: «IR AL LISTADO» vuelve al panel con los dos espacios nuevos.
      await tocar(tester, 'IR AL LISTADO');
      await esperarA(tester, find.text('${prefijo}_Futbol_F7_1'));
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
      await entrarComoAdmin(tester);
      await abrirAlta(tester);
      await completar(tester, sede);
      await esperarA(tester, find.text('${prefijo}_Futbol_F5_1'));

      // Otro administrador carga el mismo tipo en la misma sede mientras tanto.
      await crearEspacio(sede);
      await tocar(tester, 'GUARDAR ESPACIO');

      // Verifica: avisa del duplicado y el nombre pasa al número siguiente.
      await esperarA(tester, find.text(duplicado));
      await esperarA(tester, find.text('${prefijo}_Futbol_F5_2'));
      expect(find.text('¡Espacio deportivo creado!'), findsNothing);

      // Verifica: al volver a guardar, queda con el número nuevo.
      await tocar(tester, 'GUARDAR ESPACIO');
      await esperarA(tester, find.text('¡Espacio deportivo creado!'));
      expect(find.text('${prefijo}_Futbol_F5_2'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets('falta un campo obligatorio y no puede guardar @CU-21-H03-01', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final (sede, prefijo) = await sedePropia();
    await entrarComoAdmin(tester);
    await abrirAlta(tester);
    await elegir(tester, 'Sede', sede);
    await elegir(tester, 'Deporte', 'Fútbol');
    await elegir(tester, 'Condición', 'Al aire libre');
    await elegir(tester, 'Iluminación', 'Iluminada');
    await escribir(tester, 'Precio por hora', '38000');

    await tocar(tester, 'GUARDAR ESPACIO');

    // Verifica: marca el tipo como obligatorio y no se crea nada.
    expect(find.text('Este campo es obligatorio'), findsOneWidget);
    expect(find.text('¡Espacio deportivo creado!'), findsNothing);
    expect(
      (await espaciosQueVeUnUsuario()).where((n) => n.startsWith(prefijo)),
      isEmpty,
    );
    semantica.dispose();
  });

  testWidgets(
    'sin conexión o con el servidor caído al guardar, ve el error y conserva lo cargado @CU-21-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, prefijo) = await sedePropia();
      final api = await ApiIntermedia.abrir();
      await entrarComoAdmin(tester, apiUrl: api.url);
      await abrirAlta(tester);
      await completar(tester, sede);
      await esperarA(tester, find.text('${prefijo}_Futbol_F5_1'));

      // Verifica: con el servidor caído avisa y lo cargado sigue en el formulario.
      api.estado = EstadoApi.falla;
      await tocar(tester, 'GUARDAR ESPACIO');
      await esperarA(tester, find.text('Error del servidor'));
      await tocar(tester, 'ACEPTAR');
      expect(find.text(sede), findsOneWidget);
      expect(find.text('${prefijo}_Futbol_F5_1'), findsOneWidget);

      // Verifica: sin conexión avisa, y al reintentar con la red de vuelta lo guarda.
      api.estado = EstadoApi.sinRed;
      await tocar(tester, 'GUARDAR ESPACIO');
      await esperarA(tester, find.text('Error de conexión'));
      api.estado = EstadoApi.normal;
      await tocar(tester, 'REINTENTAR');
      await esperarA(tester, find.text('¡Espacio deportivo creado!'));
      expect(
        await espaciosQueVeUnUsuario(),
        contains('${prefijo}_Futbol_F5_1'),
      );
      semantica.dispose();
    },
  );
}
