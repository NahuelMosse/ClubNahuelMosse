import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/comun/dialogo_error.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:clubnahuelmosse/usuarios/pantalla_cambiar_contrasena.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo.
void main() {
  setUpAll(cargarFuentes);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  final temas = {'oscuro': temaOscuro, 'claro': temaClaro};

  Future<Sesion> sesionCon((int, String) cambio) async {
    final sesion = Sesion(
      credenciales: CredencialesFalsas(),
      api: apiRutas({
        'GET /yo': (200, perfilJson()),
        'PUT /yo/contrasena': cambio,
      }),
    );
    await sesion.iniciar('nahuel@correo.com', 'ClubNahuel1');
    return sesion;
  }

  Future<void> escribir(
    WidgetTester tester, {
    String actual = 'ClubNahuel1',
    String nueva = 'ClubNahuel2',
    String? repetida,
  }) async {
    await tester.enterText(find.bySemanticsLabel('Contraseña actual'), actual);
    await tester.enterText(find.bySemanticsLabel('Contraseña nueva'), nueva);
    await tester.enterText(
      find.bySemanticsLabel('Repetir contraseña'),
      repetida ?? nueva,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  Future<void> capturar(String archivo) =>
      expectLater(find.byType(MaterialApp), matchesGoldenFile(archivo));

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: tema) in temas.entries) {
      Future<void> montarCon(WidgetTester tester, (int, String) cambio) async {
        final sesion = await sesionCon(cambio);
        await montar(
          tester,
          PantallaCambiarContrasena(sesion: sesion),
          tema: tema,
          tamano: tamano,
        );
      }

      testWidgets('contraseña vacía $ancho $modo', (tester) async {
        await montarCon(tester, (204, ''));
        await capturar('usuarios/contrasena_vacia_${ancho}_$modo.png');
      });

      testWidgets('contraseña reglas $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montarCon(tester, (204, ''));
        await tester.enterText(
          find.bySemanticsLabel('Contraseña actual'),
          'ClubNahuel1',
        );
        await tester.enterText(
          find.bySemanticsLabel('Contraseña nueva'),
          'ClubNahuel',
        );
        await tester.pump();
        await capturar('usuarios/contrasena_reglas_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('contraseña no coinciden $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montarCon(tester, (204, ''));
        await escribir(tester, repetida: 'ClubNahuel3');
        await capturar('usuarios/contrasena_no_coinciden_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('contraseña actual equivocada $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montarCon(tester, (
          422,
          '{"errores": {"actual": "La contraseña actual no coincide"}}',
        ));
        await escribir(tester);
        await tester.tap(find.text('GUARDAR CONTRASEÑA'));
        await tester.pumpAndSettle();
        await capturar('usuarios/contrasena_actual_mal_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('contraseña actualizada $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montarCon(tester, (204, ''));
        await escribir(tester);
        await tester.tap(find.text('GUARDAR CONTRASEÑA'));
        await tester.pumpAndSettle();
        await capturar('usuarios/contrasena_actualizada_${ancho}_$modo.png');
        semantica.dispose();
      });

      for (final (nombre, abrir) in [
        (
          'error_conexion',
          (BuildContext c) => mostrarErrorDeRed(c, const SinConexion()),
        ),
        (
          'error_servidor',
          (BuildContext c) => mostrarErrorDeRed(c, const ErrorDelServidor(500)),
        ),
        ('sesion_vencida', mostrarSesionVencida),
      ]) {
        testWidgets('overlay $nombre $ancho $modo', (tester) async {
          await montar(
            tester,
            Builder(
              builder: (c) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => abrir(c),
                    child: const Text('abrir'),
                  ),
                ),
              ),
            ),
            tema: tema,
            tamano: tamano,
          );
          await tester.tap(find.text('abrir'));
          await tester.pumpAndSettle();
          await capturar('comun/${nombre}_${ancho}_$modo.png');
        });
      }
    }
  }
}
