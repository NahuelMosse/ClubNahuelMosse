import 'package:clubnahuelmosse/admin/pantalla_panel_admin.dart';
import 'package:clubnahuelmosse/inicio/pantalla_inicio.dart';
import 'package:clubnahuelmosse/sesion/pantalla_inicio_sesion.dart';
import 'package:clubnahuelmosse/sesion/pantalla_recuperar_contrasena.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:clubnahuelmosse/usuarios/pantalla_mi_perfil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

void main() {
  setUpAll(cargarFuentes);

  Widget login({bool rechaza = false}) => PantallaInicioSesion(
    sesion: Sesion(
      credenciales: CredencialesFalsas(
        alIngresar: rechaza
            ? (_, _) async => throw const CredencialesInvalidas()
            : null,
      ),
      api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
    ),
  );

  Future<void> cumpleLasGuias(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  final temas = {'oscuro': temaOscuro, 'claro': temaClaro};
  final pantallas = <String, Widget Function()>{
    'el login': login,
    'el Home': () => PantallaInicio(sesion: SesionFalsa(perfilUsuario)),
    'el panel de administración': () =>
        PantallaPanelAdmin(sesion: SesionFalsa(perfilAdmin)),
    'recuperar contraseña': () => const PantallaRecuperarContrasena(),
    'Mi perfil': () => PantallaMiPerfil(sesion: SesionFalsa(perfilUsuario)),
  };

  for (final MapEntry(key: modo, value: tema) in temas.entries) {
    for (final MapEntry(key: nombre, value: pantalla) in pantallas.entries) {
      testWidgets('$nombre cumple las guías de accesibilidad en modo $modo', (
        tester,
      ) async {
        final semantica = tester.ensureSemantics();
        await montar(tester, pantalla(), tema: tema);
        await cumpleLasGuias(tester);
        semantica.dispose();
      });
    }

    testWidgets('el login con errores y aviso cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(tester, login(rechaza: true), tema: tema);
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle();
      await cumpleLasGuias(tester);
      await tester.enterText(find.bySemanticsLabel('Correo'), 'n@correo.com');
      await tester.enterText(find.bySemanticsLabel('Contraseña'), 'Mala1234');
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle();
      expect(find.text(mensajeCredencialesInvalidas), findsOneWidget);
      await cumpleLasGuias(tester);
      semantica.dispose();
    });
  }

  testWidgets('los campos del login anuncian su nombre', (tester) async {
    final semantica = tester.ensureSemantics();
    await montar(tester, login(), tema: temaOscuro);
    expect(find.bySemanticsLabel('Correo'), findsOneWidget);
    expect(find.bySemanticsLabel('Contraseña'), findsOneWidget);
    expect(find.bySemanticsLabel('Club Nahuel Mosse'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('con el texto al 200 % nada se desborda', (tester) async {
    for (final pantalla in pantallas.values) {
      await montar(
        tester,
        pantalla(),
        tema: temaOscuro,
        tamano: const Size(360, 800),
        escalaTexto: 2,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
