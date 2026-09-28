import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Una sede propia del test y la parte del nombre compuesto que le corresponde.
  Future<(String, String)> sedePropia() async {
    final s = unico();
    await crearSede('Sede Haedo $s', 'Av. Vergara 1850');
    return ('Sede Haedo $s', 'Haedo${s}_Vergara_1850');
  }

  /// Una sede con dos Fútbol 5 y un Hockey 7.
  Future<(String, String)> sedeConCanchas() async {
    final (sede, prefijo) = await sedePropia();
    await crearEspacio(sede);
    await crearEspacio(sede);
    await crearEspacio(sede, deporte: 'Hockey', tipo: 'H7');
    return (sede, prefijo);
  }

  Future<void> entrarA(
    WidgetTester tester,
    String sede,
    String contador,
  ) async {
    await tocar(tester, 'SEDES');
    final tarjeta = find.bySemanticsLabel(RegExp('^${RegExp.escape(sede)},'));
    await esperarA(tester, tarjeta);
    await tester.ensureVisible(tarjeta);
    await tester.pumpAndSettle();
    await tester.tap(tarjeta);
    await tester.pumpAndSettle();
    await esperarA(tester, find.text(contador));
  }

  Future<void> filtrar(WidgetTester tester, String chip) async {
    final boton = find.bySemanticsLabel(chip);
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  /// La tarjeta del panel del administrador para el espacio [nombre] de la sede [sede].
  Finder tarjetaDelPanel(String sede, String nombre) => find.bySemanticsLabel(
    RegExp('${RegExp.escape(sede)}, ${RegExp.escape(nombre)}\$'),
  );

  testWidgets(
    'en la pantalla de cada sede, cada espacio se muestra con su sede y su dirección @TP-05-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, prefijo) = await sedeConCanchas();
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');

      await entrarA(tester, sede, '3 CANCHAS · TODOS LOS DEPORTES');

      // Verifica: la sede y su dirección encabezan sus canchas, y cada una las lleva en el nombre.
      expect(find.text(sede.toUpperCase()), findsOneWidget);
      expect(find.textContaining('AV. VERGARA 1850'), findsOneWidget);
      for (final n in ['Futbol_F5_1', 'Futbol_F5_2', 'Hockey_H7_1']) {
        expect(find.text('${prefijo}_$n'), findsOneWidget);
      }
      semantica.dispose();
    },
  );

  testWidgets(
    'cada espacio muestra su nombre compuesto por sede, dirección, tipo y número @TP-05-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, prefijo) = await sedePropia();
      final uno = await crearEspacio(sede, deporte: 'Padel', tipo: 'PAD');
      final dos = await crearEspacio(sede, deporte: 'Padel', tipo: 'PAD');
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');

      await entrarA(tester, sede, '2 CANCHAS · TODOS LOS DEPORTES');

      // Verifica: sede, calle, altura, deporte, tipo y número, en ese orden.
      expect(uno, '${prefijo}_Padel_PAD_1');
      expect(dos, '${prefijo}_Padel_PAD_2');
      expect(find.text(uno), findsOneWidget);
      expect(find.text(dos), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'el panel del administrador lista los espacios de todas las sedes, cada uno con su sede @TP-05-H01-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (haedo, _) = await sedePropia();
      final s = unico();
      await crearSede('Sede Ramos $s', 'Av. Vergara 1850');
      final enHaedo = await crearEspacio(haedo);
      final enRamos = await crearEspacio('Sede Ramos $s', tipo: 'F7');
      await entrarComoAdmin(tester);

      await tocar(tester, 'ESPACIOS');

      // Verifica: los espacios de las dos sedes, cada uno con la suya.
      for (final (sede, nombre) in [
        (haedo, enHaedo),
        ('Sede Ramos $s', enRamos),
      ]) {
        final tarjeta = tarjetaDelPanel(sede, nombre);
        await esperarA(tester, tarjeta);
        await tester.ensureVisible(tarjeta);
        await tester.pumpAndSettle();
        expect(find.text(nombre), findsOneWidget);
      }
      expect(find.textContaining('ESPACIOS ACTIVOS ·'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'un espacio recién dado de alta aparece en su sede y en el panel del administrador @TP-05-H01-04',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, prefijo) = await sedePropia();
      final nombre = '${prefijo}_Voley_PLA_1';
      await entrarComoAdmin(tester);
      await tocar(tester, 'ESPACIOS');
      await tocar(tester, 'ALTA ESPACIO');
      await esperarA(tester, find.text('Nuevo espacio deportivo'));
      await elegir(tester, 'Sede', sede);
      await elegir(tester, 'Deporte', 'Vóley');
      await elegir(tester, 'Tipo', 'Vóley playa');
      await elegir(tester, 'Condición', 'Al aire libre');
      await elegir(tester, 'Iluminación', 'Sin iluminación');
      await escribir(tester, 'Precio por hora', '29000');
      await tocar(tester, 'GUARDAR ESPACIO');
      await esperarA(tester, find.text('¡Espacio deportivo creado!'));

      await tocar(tester, 'IR AL LISTADO');

      // Verifica: el panel ya lo lista con su sede.
      final tarjeta = tarjetaDelPanel(sede, nombre);
      await esperarA(tester, tarjeta);

      // Verifica: un usuario lo ve en la pantalla de la sede.
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');
      await entrarA(tester, sede, '1 CANCHA · TODOS LOS DEPORTES');
      expect(find.text(nombre), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'dentro de una sede filtra por tipo y sólo ve los espacios de ese tipo @TP-05-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, prefijo) = await sedeConCanchas();
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');
      await entrarA(tester, sede, '3 CANCHAS · TODOS LOS DEPORTES');

      await filtrar(tester, 'Deporte Hockey');

      // Verifica: queda sólo la de hockey.
      await esperarA(tester, find.text('1 CANCHA · HOCKEY'));
      expect(find.text('${prefijo}_Hockey_H7_1'), findsOneWidget);
      expect(find.text('${prefijo}_Futbol_F5_1'), findsNothing);
      expect(find.text('${prefijo}_Futbol_F5_2'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'quita el filtro y vuelve a ver todos los espacios de la sede @TP-05-H02-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, prefijo) = await sedeConCanchas();
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');
      await entrarA(tester, sede, '3 CANCHAS · TODOS LOS DEPORTES');
      await filtrar(tester, 'Deporte Fútbol');
      await esperarA(tester, find.text('2 CANCHAS · FÚTBOL'));

      await filtrar(tester, 'Deporte Fútbol');

      // Verifica: vuelven las tres canchas, sin deporte elegido.
      await esperarA(tester, find.text('3 CANCHAS · TODOS LOS DEPORTES'));
      for (final n in ['Futbol_F5_1', 'Futbol_F5_2', 'Hockey_H7_1']) {
        expect(find.text('${prefijo}_$n'), findsOneWidget);
      }
      semantica.dispose();
    },
  );
}
