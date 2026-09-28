import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const invalido = 'El formato de los datos no es válido';

  Future<void> abrirPerfil(WidgetTester tester) async {
    await tocar(tester, 'PERFIL');
    await esperarA(tester, find.text('DATOS PERSONALES'));
  }

  Future<void> editar(WidgetTester tester) async {
    await abrirPerfil(tester);
    await tocar(tester, 'Editar');
    expect(find.text('GUARDAR'), findsOneWidget);
  }

  TextField campo(WidgetTester tester, String etiqueta) =>
      tester.widget<TextField>(
        find.descendant(
          of: find.bySemanticsLabel(etiqueta),
          matching: find.byType(TextField),
        ),
      );

  Brightness brillo(WidgetTester tester) =>
      Theme.of(tester.element(find.text('DATOS PERSONALES'))).brightness;

  testWidgets(
    'edita su nombre, guarda, y el perfil muestra el dato nuevo al volver a abrirlo @CU-06-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');
      await editar(tester);

      await escribir(tester, 'Nombre', 'Agustín');
      await tocar(tester, 'GUARDAR');

      // Verifica: vuelve a modo lectura con el nombre nuevo.
      await esperarA(tester, find.text('Agustín'));
      expect(find.text('GUARDAR'), findsNothing);
      expect(find.text('Agustín Mosse'), findsOneWidget);

      // Verifica: el cambio quedó guardado en la API, no sólo en la pantalla.
      await tocar(tester, 'INICIO');
      await abrirPerfil(tester);
      expect(find.text('Agustín'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets('el correo no se puede editar @CU-06-H01-02', (tester) async {
    final semantica = tester.ensureSemantics();
    final correo = 'socio.${unico()}@correo.com';
    await entrarComoUsuario(tester, correo: correo);
    await editar(tester);

    // Verifica: el correo está en el formulario pero deshabilitado, con su valor.
    final correoEnEdicion = campo(tester, 'Correo electrónico');
    expect(correoEnEdicion.enabled, isFalse);
    expect(correoEnEdicion.controller?.text, correo);
    expect(campo(tester, 'Nombre').enabled, isTrue);
    semantica.dispose();
  });

  testWidgets(
    'alterna el modo oscuro y el tema cambia al opuesto @CU-06-H01-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');
      await editar(tester);
      final antes = brillo(tester);

      Future<void> alternar() async {
        await tester.ensureVisible(find.bySemanticsLabel('Modo oscuro'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Modo oscuro'));
        await tester.pumpAndSettle();
      }

      // Verifica: cada toque pasa el tema al opuesto del que tenía.
      await alternar();
      expect(brillo(tester), isNot(antes));
      await alternar();
      expect(brillo(tester), antes);
      semantica.dispose();
    },
  );

  testWidgets(
    'guarda un DNI o una fecha con formato inválido, ve el error y no se guarda nada @CU-06-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');
      await editar(tester);

      await escribir(tester, 'Nombre', 'Agustín');
      await escribir(tester, 'DNI', '42118');
      await escribir(tester, 'Fecha de nacimiento', '32132000');
      await tocar(tester, 'GUARDAR');

      // Verifica: marca los dos datos inválidos y sigue en edición.
      expect(find.text(invalido), findsNWidgets(2));
      expect(find.text('GUARDAR'), findsOneWidget);

      // Verifica: no se guardó ningún dato, ni siquiera el nombre válido.
      await tocar(tester, 'INICIO');
      await abrirPerfil(tester);
      expect(find.text('Agustín'), findsNothing);
      expect(find.text('14/03/2000'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin conexión al guardar, ve el error de conectividad y conserva lo escrito @CU-06-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final api = await ApiIntermedia.abrir();
      await entrarComoUsuario(
        tester,
        correo: 'socio.${unico()}@correo.com',
        apiUrl: api.url,
      );
      await editar(tester);
      await escribir(tester, 'Nombre', 'Agustín');

      api.estado = EstadoApi.sinRed;
      await tocar(tester, 'GUARDAR');

      // Verifica: avisa que no hay conexión y lo escrito sigue en el campo.
      await esperarA(tester, find.text('Error de conexión'));
      await tocar(tester, 'Volver');
      expect(campo(tester, 'Nombre').controller?.text, 'Agustín');
      expect(find.text('GUARDAR'), findsOneWidget);
      semantica.dispose();
    },
  );
}
