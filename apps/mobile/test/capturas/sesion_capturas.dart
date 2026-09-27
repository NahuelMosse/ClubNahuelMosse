import 'package:clubnahuelmosse/admin/pantalla_panel_admin.dart';
import 'package:clubnahuelmosse/inicio/pantalla_inicio.dart';
import 'package:clubnahuelmosse/sesion/pantalla_inicio_sesion.dart';
import 'package:clubnahuelmosse/sesion/pantalla_recuperar_contrasena.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soporte/montar.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo.
void main() {
  setUpAll(cargarFuentes);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  final temas = {'oscuro': temaOscuro, 'claro': temaClaro};

  Widget login() => PantallaInicioSesion(
    sesion: Sesion(
      credenciales: CredencialesFalsas(
        alIngresar: (_, _) async => throw const CredencialesInvalidas(),
      ),
      api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
    ),
  );

  Future<void> capturar(WidgetTester tester, String archivo) async {
    // La foto del fondo se decodifica fuera del reloj falso del test.
    await tester.runAsync(() async {
      for (final elemento in find.byType(Image).evaluate()) {
        final imagen = elemento.widget;
        if (imagen is Image) await precacheImage(imagen.image, elemento);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(archivo));
  }

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: tema) in temas.entries) {
      testWidgets('login vacío $ancho $modo', (tester) async {
        await montar(tester, login(), tema: tema, tamano: tamano);
        await capturar(tester, 'sesion/login_vacio_${ancho}_$modo.png');
      });

      testWidgets('login campos incompletos $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montar(tester, login(), tema: tema, tamano: tamano);
        await tester.tap(find.text('INICIAR SESIÓN'));
        await tester.pumpAndSettle();
        await capturar(tester, 'sesion/login_incompleto_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('login credenciales inválidas $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montar(tester, login(), tema: tema, tamano: tamano);
        await tester.enterText(
          find.bySemanticsLabel('Correo'),
          'nmosse@unimoron.edu.ar',
        );
        await tester.enterText(
          find.bySemanticsLabel('Contraseña'),
          'Clave1234',
        );
        await tester.tap(find.text('INICIAR SESIÓN'));
        await tester.pumpAndSettle();
        await capturar(tester, 'sesion/login_invalido_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('home $ancho $modo', (tester) async {
        await montar(
          tester,
          const PantallaInicio(nombre: 'Nahuel'),
          tema: tema,
          tamano: tamano,
        );
        await capturar(tester, 'sesion/home_${ancho}_$modo.png');
      });

      testWidgets('panel admin $ancho $modo', (tester) async {
        await montar(
          tester,
          const PantallaPanelAdmin(),
          tema: tema,
          tamano: tamano,
        );
        await capturar(tester, 'sesion/panel_admin_${ancho}_$modo.png');
      });

      testWidgets('recuperar contraseña $ancho $modo', (tester) async {
        await montar(
          tester,
          const PantallaRecuperarContrasena(),
          tema: tema,
          tamano: tamano,
        );
        await capturar(tester, 'sesion/recuperar_${ancho}_$modo.png');
      });
    }
  }
}
