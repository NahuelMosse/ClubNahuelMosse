import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Una sede con dos Fútbol 5, un Fútbol 7 y un Hockey 7, y el nombre de cada cancha.
  Future<(String, Map<String, String>)> sedeConCanchas() async {
    final sede = 'Sede Ituzaingó ${unico()}';
    await crearSede(sede, 'Av. Ratti 1400');
    return (
      sede,
      {
        'F5_1': await crearEspacio(sede),
        'F5_2': await crearEspacio(sede),
        'F7_1': await crearEspacio(sede, tipo: 'F7'),
        'H7_1': await crearEspacio(sede, deporte: 'Hockey', tipo: 'H7'),
      },
    );
  }

  Future<void> entrarA(
    WidgetTester tester,
    String sede, {
    String? apiUrl,
  }) async {
    await entrarComoUsuario(
      tester,
      correo: 'socio.${unico()}@correo.com',
      apiUrl: apiUrl,
    );
    await tocar(tester, 'SEDES');
    final tarjeta = find.bySemanticsLabel(RegExp('^${RegExp.escape(sede)},'));
    await esperarA(tester, tarjeta);
    await tester.ensureVisible(tarjeta);
    await tester.pumpAndSettle();
    await tester.tap(tarjeta);
    await tester.pumpAndSettle();
    await esperarA(tester, find.text('4 CANCHAS · TODOS LOS DEPORTES'));
  }

  Future<void> filtrar(WidgetTester tester, String chip) async {
    final boton = find.bySemanticsLabel(chip);
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  bool elegido(WidgetTester tester, String chip) => tester
      .getSemantics(find.bySemanticsLabel(chip))
      .flagsCollection
      .isSelected;

  testWidgets(
    'elige un deporte en una sede y sólo ve las canchas de ese deporte, con el contador @CU-20-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, canchas) = await sedeConCanchas();
      await entrarA(tester, sede);

      await filtrar(tester, 'Deporte Fútbol');

      // Verifica: el contador dice el deporte y quedan sólo sus canchas.
      await esperarA(tester, find.text('3 CANCHAS · FÚTBOL · TODOS LOS TIPOS'));
      expect(elegido(tester, 'Deporte Fútbol'), isTrue);
      for (final c in ['F5_1', 'F5_2', 'F7_1']) {
        expect(find.text(canchas[c]!), findsOneWidget);
      }
      expect(find.text(canchas['H7_1']!), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'elige una variante y sólo ve las canchas de ese tipo, con el contador actualizado @CU-20-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, canchas) = await sedeConCanchas();
      await entrarA(tester, sede);
      await filtrar(tester, 'Deporte Fútbol');
      await esperarA(tester, find.text('3 CANCHAS · FÚTBOL · TODOS LOS TIPOS'));

      await filtrar(tester, 'Tipo Fútbol 5');

      // Verifica: sólo las de Fútbol 5, con el contador del tipo.
      await esperarA(tester, find.text('2 CANCHAS · FÚTBOL 5'));
      expect(elegido(tester, 'Tipo Fútbol 5'), isTrue);
      expect(find.text(canchas['F5_1']!), findsOneWidget);
      expect(find.text(canchas['F5_2']!), findsOneWidget);
      expect(find.text(canchas['F7_1']!), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'una cancha recién dada de alta aparece al filtrar por su deporte y su tipo @CU-20-H01-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, _) = await sedeConCanchas();
      await entrarA(tester, sede);

      // El administrador carga otra cancha mientras el usuario mira la sede.
      final nueva = await crearEspacio(sede, tipo: 'F7');
      await filtrar(tester, 'Deporte Fútbol');
      await esperarA(tester, find.text('4 CANCHAS · FÚTBOL · TODOS LOS TIPOS'));
      await filtrar(tester, 'Tipo Fútbol 7');

      // Verifica: la nueva aparece entre las de su tipo.
      await esperarA(tester, find.text('2 CANCHAS · FÚTBOL 7'));
      expect(find.text(nueva), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'el filtro elegido se mantiene mientras sigue en la sede @CU-20-H01-04',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, _) = await sedeConCanchas();
      await entrarA(tester, sede);
      await filtrar(tester, 'Deporte Fútbol');
      await esperarA(tester, find.text('3 CANCHAS · FÚTBOL · TODOS LOS TIPOS'));
      await filtrar(tester, 'Tipo Fútbol 5');
      await esperarA(tester, find.text('2 CANCHAS · FÚTBOL 5'));

      // Pasa a los horarios de una cancha y vuelve a la sede.
      final reservar = find.text('VER HORARIOS / RESERVAR').first;
      await tester.ensureVisible(reservar);
      await tester.pumpAndSettle();
      await tester.tap(reservar);
      await tester.pumpAndSettle();
      await esperarA(tester, find.text('SELECCIONÁ CANCHA'));
      await tocar(tester, 'Sedes');

      // Verifica: la sede sigue filtrada por Fútbol 5.
      await esperarA(tester, find.text('2 CANCHAS · FÚTBOL 5'));
      expect(elegido(tester, 'Deporte Fútbol'), isTrue);
      expect(elegido(tester, 'Tipo Fútbol 5'), isTrue);
      semantica.dispose();
    },
  );

  testWidgets(
    'elige un deporte con una sola modalidad y no aparece la barra de variantes @CU-20-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, canchas) = await sedeConCanchas();
      await entrarA(tester, sede);

      await filtrar(tester, 'Deporte Hockey');

      // Verifica: filtra por deporte y no ofrece tipos.
      await esperarA(tester, find.text('1 CANCHA · HOCKEY'));
      expect(find.text('TIPO DE CANCHA'), findsNothing);
      expect(find.text(canchas['H7_1']!), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'toca «Todos» y vuelve a ver todas las canchas del deporte, sin perder el deporte @CU-20-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, canchas) = await sedeConCanchas();
      await entrarA(tester, sede);
      await filtrar(tester, 'Deporte Fútbol');
      await esperarA(tester, find.text('3 CANCHAS · FÚTBOL · TODOS LOS TIPOS'));
      await filtrar(tester, 'Tipo Fútbol 7');
      await esperarA(tester, find.text('1 CANCHA · FÚTBOL 7'));

      await filtrar(tester, 'Tipo Todos');

      // Verifica: vuelven todas las de Fútbol y el deporte sigue elegido.
      await esperarA(tester, find.text('3 CANCHAS · FÚTBOL · TODOS LOS TIPOS'));
      expect(elegido(tester, 'Deporte Fútbol'), isTrue);
      expect(elegido(tester, 'Tipo Todos'), isTrue);
      expect(find.text(canchas['F5_1']!), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'entra a una sede sin canchas y no ve chips, sólo el aviso @CU-20-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final sede = 'Sede Haedo ${unico()}';
      await crearSede(sede, 'Av. Vergara 1850');
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');
      await tocar(tester, 'SEDES');
      final tarjeta = find.bySemanticsLabel(RegExp('^${RegExp.escape(sede)},'));
      await esperarA(tester, tarjeta);
      await tester.ensureVisible(tarjeta);
      await tester.pumpAndSettle();
      await tester.tap(tarjeta);
      await tester.pumpAndSettle();

      // Verifica: el aviso y ningún filtro.
      await esperarA(tester, find.text('Todavía no hay canchas'));
      expect(find.text('DEPORTE'), findsNothing);
      expect(find.text('TIPO DE CANCHA'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin conexión al filtrar, ve la alerta y el listado no cambia @CU-20-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, canchas) = await sedeConCanchas();
      final api = await ApiIntermedia.abrir();
      await entrarA(tester, sede, apiUrl: api.url);

      api.estado = EstadoApi.sinRed;
      await filtrar(tester, 'Deporte Fútbol');

      // Verifica: avisa sin conexión y el listado sigue con todos los deportes.
      await esperarA(tester, find.text('Error de conexión'));
      await tocar(tester, 'Volver');
      expect(find.text('4 CANCHAS · TODOS LOS DEPORTES'), findsOneWidget);
      expect(elegido(tester, 'Deporte Fútbol'), isFalse);
      expect(find.text(canchas['H7_1']!), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'el servidor falla al filtrar, ve el error y el listado no cambia @CU-20-H06-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, canchas) = await sedeConCanchas();
      final api = await ApiIntermedia.abrir();
      await entrarA(tester, sede, apiUrl: api.url);
      await filtrar(tester, 'Deporte Fútbol');
      await esperarA(tester, find.text('3 CANCHAS · FÚTBOL · TODOS LOS TIPOS'));

      api.estado = EstadoApi.falla;
      await filtrar(tester, 'Tipo Fútbol 5');

      // Verifica: avisa del servidor y sigue el filtro anterior.
      await esperarA(tester, find.text('Error del servidor'));
      await tocar(tester, 'ACEPTAR');
      expect(find.text('3 CANCHAS · FÚTBOL · TODOS LOS TIPOS'), findsOneWidget);
      expect(elegido(tester, 'Tipo Fútbol 5'), isFalse);
      expect(find.text(canchas['F7_1']!), findsOneWidget);
      semantica.dispose();
    },
  );
}
