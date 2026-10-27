import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/comun/barra_inferior.dart';
import 'package:clubnahuelmosse/comun/boton.dart';
import 'package:clubnahuelmosse/comun/calendario.dart';
import 'package:clubnahuelmosse/comun/campo_texto.dart';
import 'package:clubnahuelmosse/admin/dialogos_de_baja.dart';
import 'package:clubnahuelmosse/comun/selector.dart';
import 'package:clubnahuelmosse/comun/reloj.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:clubnahuelmosse/usuarios/pantalla_registro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'mis_reservas_test.dart' show reservaJson;
import 'soporte/admin.dart';
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

/// El contraste de WCAG entre dos colores opacos.
double contraste(Color a, Color b) {
  final (claro, oscuro) = a.computeLuminance() > b.computeLuminance()
      ? (a.computeLuminance(), b.computeLuminance())
      : (b.computeLuminance(), a.computeLuminance());
  return (claro + 0.05) / (oscuro + 0.05);
}

void main() {
  setUpAll(cargarFuentes);

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  group('registro', () {
    const faltantes = [
      'El nombre es obligatorio',
      'El apellido es obligatorio',
      'El DNI es obligatorio',
      'La fecha de nacimiento es obligatoria',
      'El correo es obligatorio',
      'La contraseña es obligatoria',
    ];

    testWidgets(
      'tocar CREAR CUENTA con el formulario vacío muestra cada dato que falta @REV-04-S1',
      (tester) async {
        final pedidos = <http.Request>[];
        await montar(
          tester,
          PantallaRegistro(api: apiRutas({}, pedidos: pedidos)),
          tema: temaOscuro,
        );

        await tocar(tester, find.text('CREAR CUENTA'));

        for (final mensaje in faltantes) {
          expect(find.text(mensaje), findsOneWidget, reason: mensaje);
        }
        expect(pedidos, isEmpty);
      },
    );

    testWidgets(
      'salir de un campo vacío no muestra un error antes de intentar crear la cuenta '
      '@REV-04-S1 @assumption:REV-04-ASM-01',
      (tester) async {
        await montar(
          tester,
          PantallaRegistro(api: apiRutas({})),
          tema: temaOscuro,
        );

        await tester.tap(find.bySemanticsLabel('Nombre'));
        await tester.pump();
        await tester.tap(find.bySemanticsLabel('Apellido'));
        await tester.pumpAndSettle();

        expect(find.text('El nombre es obligatorio'), findsNothing);
      },
    );

    testWidgets(
      'el lector anuncia el formato de la fecha de nacimiento @REV-04-S4',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await montar(
          tester,
          PantallaRegistro(api: apiRutas({})),
          tema: temaOscuro,
        );

        final nodo = tester.getSemantics(
          find.bySemanticsLabel(RegExp('^Fecha de nacimiento')),
        );

        expect(
          '${nodo.label} ${nodo.hint} ${nodo.value}',
          contains('DD / MM / AAAA'),
        );
        semantica.dispose();
      },
    );
  });

  testWidgets(
    'el lector anuncia el error de un campo junto con el campo @REV-04-S3',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: temaOscuro,
          home: Scaffold(
            body: CampoTexto(
              etiqueta: 'NOMBRE',
              etiquetaAccesible: 'Nombre',
              controlador: TextEditingController(),
              placeholder: 'Tu nombre',
              error: 'El nombre es obligatorio',
            ),
          ),
        ),
      );

      final nodo = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Nombre')),
      );

      expect(
        '${nodo.label} ${nodo.hint} ${nodo.value}',
        contains('El nombre es obligatorio'),
      );
      semantica.dispose();
    },
  );

  testWidgets(
    'guardar la edición de una sede sin nombre muestra qué falta y no envía '
    '@REV-04-S2 @assumption:REV-04-ASM-04',
    (tester) async {
      final pedidos = <http.Request>[];
      await montarAdmin(
        tester,
        api: ClienteApi(
          'http://api.falsa',
          cliente: MockClient((pedido) async {
            pedidos.add(pedido);
            final (codigo, cuerpo) = switch ((pedido.method, pedido.url.path)) {
              ('GET', '/sedes') => (200, '{"sedes": [$sedeMoronJson]}'),
              ('PUT', '/sedes/00000000-0000-7000-8000-000000000001') => (200, sedeMoronJson),
              _ => (404, '{}'),
            };
            return http.Response.bytes(
              utf8.encode(cuerpo),
              codigo,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );
      await tocar(tester, find.bySemanticsLabel('Editar sede Sede Morón'));
      final nombre = find.descendant(
        of: find.bySemanticsLabel(RegExp('^Nombre')),
        matching: find.byType(EditableText),
      );
      await tester.enterText(nombre, '');
      await tocar(
        tester,
        find.descendant(
          of: find.bySemanticsLabel(RegExp('^Dirección')),
          matching: find.byType(EditableText),
        ),
      );

      await tocar(tester, find.text('GUARDAR CAMBIOS'));

      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      expect(
        tester.widget<EditableText>(nombre).focusNode.hasPrimaryFocus,
        isTrue,
      );
      expect(pedidos.where((p) => p.method == 'PUT'), isEmpty);
    },
  );

  Future<void> hastaConfirmarReserva(WidgetTester tester) async {
    await montarUsuario(
      tester,
      inicio: '/sedes/00000000-0000-7000-8000-000000000001/canchas/00000000-0000-7000-8000-000000000009',
      api: apiRutas({
        ...rutasDeSedes(),
        'POST /reservas': (
          422,
          '{"errores": {"fecha": "Ese horario ya empezó"}}',
        ),
      }),
    );
    await tocar(tester, find.bySemanticsLabel('18:00 – 19:00'));
    await tocar(tester, find.text('CONTINUAR'));
  }

  testWidgets(
    'el rechazo de una reserva sigue a la vista hasta que la persona lo cierra '
    '@REV-04-S5 @assumption:REV-04-ASM-02',
    (tester) async {
      await hastaConfirmarReserva(tester);

      await tocar(tester, find.text('CONFIRMAR RESERVA'));
      // I20: el aviso tiene que seguir pasados 10 s; es el reloj del test, no una espera real.
      await tester.pump(const Duration(seconds: 10));

      expect(find.text('Ese horario ya empezó'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tocar(tester, find.text('ELEGIR OTRO HORARIO'));
      expect(find.text('Ese horario ya empezó'), findsNothing);
      expect(find.text('HORARIO DISPONIBLE'), findsOneWidget);
    },
  );

  testWidgets(
    'el rechazo de un cambio de reserva sigue a la vista hasta que la persona lo cierra '
    '@REV-04-S6 @assumption:REV-04-ASM-02',
    (tester) async {
      final rutas = rutasDeSedes(grilla: grillaJson(ocupadas: {9, 12}));
      await montarUsuario(
        tester,
        inicio: '/reservas',
        api: apiRutas({
          ...rutas,
          'GET /reservas': (200, '{"reservas": [${reservaJson()}]}'),
          'POST /reservas/00000000-0000-7000-8000-000000000001/modificar': (
            422,
            '{"errores": {"fecha": "Ese horario ya empezó"}}',
          ),
        }),
      );
      await tocar(tester, find.text('MODIFICAR'));
      await tocar(tester, find.text('19:00 – 20:00'));
      await tocar(tester, find.text('CONTINUAR CON EL CAMBIO'));

      await tocar(tester, find.text('GUARDAR EL CAMBIO'));
      // I20: el aviso tiene que seguir pasados 10 s; es el reloj del test, no una espera real.
      await tester.pump(const Duration(seconds: 10));

      expect(find.text('Ese horario ya empezó'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tocar(tester, find.text('ELEGIR OTRO HORARIO'));
      expect(find.text('Ese horario ya empezó'), findsNothing);
    },
  );

  testWidgets(
    'al confirmar una cancelación el foco empieza en la opción que no cancela '
    '@REV-04-S7 @assumption:REV-04-ASM-03',
    (tester) async {
      final futura = DateTime.now().toUtc().add(const Duration(days: 2));
      final inicio = DateTime.utc(futura.year, futura.month, futura.day, 21);
      final proxima = reservaJson(
        inicio: inicio.toIso8601String(),
        fin: inicio.add(const Duration(hours: 1)).toIso8601String(),
      );
      await montarUsuario(
        tester,
        inicio: '/reservas',
        api: apiRutas({
          ...rutasDeSedes(),
          'GET /reservas': (200, '{"reservas": [$proxima]}'),
        }),
      );

      await tocar(tester, find.text('CANCELAR'));

      expect(find.text('¿Cancelar la reserva?'), findsOneWidget);
      expect(
        Focus.of(tester.element(find.text('NO CANCELAR'))).hasPrimaryFocus,
        isTrue,
      );
    },
  );

  Future<void> abrirDialogo(
    WidgetTester tester,
    Future<bool> Function(BuildContext) abrir,
  ) async {
    await montar(
      tester,
      Scaffold(
        body: Builder(
          builder: (contexto) => TextButton(
            onPressed: () => abrir(contexto),
            child: const Text('ABRIR'),
          ),
        ),
      ),
      tema: temaOscuro,
    );
    await tocar(tester, find.text('ABRIR'));
  }

  bool enfocado(WidgetTester tester, String texto) =>
      Focus.of(tester.element(find.text(texto))).hasPrimaryFocus;

  testWidgets(
    'al dar de baja una sede el foco empieza en CANCELAR @REV-04-S7 @assumption:REV-04-ASM-03',
    (tester) async {
      await abrirDialogo(tester, (c) => confirmarBajaDeSede(c, 'Sede Morón'));

      expect(enfocado(tester, 'CANCELAR'), isTrue);
      expect(
        tester.getTopLeft(find.text('DAR DE BAJA')).dy,
        lessThan(tester.getTopLeft(find.text('CANCELAR')).dy),
      );
    },
  );

  testWidgets(
    'al dar de baja un espacio el foco empieza en CANCELAR @REV-04-S7 @assumption:REV-04-ASM-03',
    (tester) async {
      await abrirDialogo(
        tester,
        (c) => confirmarBajaDeEspacio(c, 'Moron_Rivadavia_19850_Futbol_F5_1'),
      );

      expect(enfocado(tester, 'CANCELAR'), isTrue);
    },
  );

  testWidgets(
    'el lector anuncia el error de un selector junto con el selector @REV-04-S3',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await montar(
        tester,
        Scaffold(
          body: CampoSelector(
            etiqueta: 'DEPORTE',
            etiquetaAccesible: 'Deporte',
            valor: null,
            placeholder: 'Elegí un deporte',
            icono: Icons.sports_soccer,
            alTocar: () {},
            error: 'Elegí un deporte',
          ),
        ),
        tema: temaOscuro,
      );

      final nodo = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Deporte')),
      );

      expect(
        '${nodo.label} ${nodo.hint} ${nodo.value}',
        contains('Elegí un deporte'),
      );
      expect(find.bySemanticsLabel('Elegí un deporte'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'en el registro el error de un campo es parte del campo y no un nodo aparte @REV-04-S3',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await montar(
        tester,
        PantallaRegistro(api: apiRutas({})),
        tema: temaOscuro,
      );

      await tocar(tester, find.text('CREAR CUENTA'));

      final nodo = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Nombre')),
      );
      expect(
        '${nodo.label} ${nodo.hint} ${nodo.value}',
        contains('El nombre es obligatorio'),
      );
      expect(find.bySemanticsLabel('El nombre es obligatorio'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'con un dato completado sólo se marca lo que falta, y escribirlo borra su error '
    '@REV-04-S1 @assumption:REV-04-ASM-01',
    (tester) async {
      final pedidos = <http.Request>[];
      await montar(
        tester,
        PantallaRegistro(
          api: apiRutas({
            'POST /registro': (201, '{"id": "00000000-0000-7000-8000-000000000001"}'),
          }, pedidos: pedidos),
        ),
        tema: temaOscuro,
      );
      await tester.enterText(find.bySemanticsLabel('Nombre'), 'Ana');
      await tester.enterText(find.bySemanticsLabel('Apellido'), 'Pérez');
      await tester.enterText(find.bySemanticsLabel('DNI'), '12345678');
      await tester.enterText(
        find.bySemanticsLabel('Fecha de nacimiento'),
        '14032000',
      );
      await tester.enterText(
        find.bySemanticsLabel('Contraseña'),
        'ClubNahuel1',
      );

      await tocar(tester, find.text('CREAR CUENTA'));

      expect(find.text('El correo es obligatorio'), findsOneWidget);
      expect(find.text('El nombre es obligatorio'), findsNothing);
      expect(pedidos, isEmpty);
      await tester.enterText(
        find.bySemanticsLabel('Correo electrónico'),
        'ana@correo.com',
      );
      await tester.pumpAndSettle();
      expect(find.text('El correo es obligatorio'), findsNothing);
      await tocar(tester, find.text('CREAR CUENTA'));
      expect(pedidos.where((p) => p.url.path == '/registro'), hasLength(1));
    },
  );

  testWidgets(
    'una fecha de nacimiento tipeada se compara con el día del club @REV-04-S10 '
    '@assumption:REV-04-ASM-08',
    (tester) async {
      // 02:30 UTC del 13 de noviembre: en el club todavía es el 12.
      await withClock(Clock.fixed(DateTime.utc(2026, 11, 13, 2, 30)), () async {
        await montar(
          tester,
          PantallaRegistro(api: apiRutas({})),
          tema: temaOscuro,
        );
        await tester.enterText(
          find.bySemanticsLabel('Fecha de nacimiento'),
          '12112026',
        );
        await tocar(tester, find.text('CREAR CUENTA'));
        expect(
          find.text('La fecha tiene que ser anterior a hoy'),
          findsOneWidget,
        );

        await tester.enterText(
          find.bySemanticsLabel('Fecha de nacimiento'),
          '11112026',
        );
        await tester.pumpAndSettle();
        expect(
          find.text('La fecha tiene que ser anterior a hoy'),
          findsNothing,
        );
      });
    },
  );

  for (final ancho in [320.0, 360.0]) {
    testWidgets(
      'a ${ancho.toInt()} de ancho y con el texto al 200 % la barra del socio muestra cada destino '
      'entero @REV-04-S8 @assumption:REV-04-ASM-05',
      (tester) async {
        await montar(
          tester,
          const Scaffold(
            bottomNavigationBar: BarraInferior(actual: Seccion.reservas),
          ),
          tema: temaOscuro,
          tamano: Size(ancho, 800),
          escalaTexto: 2,
        );

        for (final destino in ['INICIO', 'SEDES', 'RESERVAS', 'PERFIL']) {
          final rect = tester.getRect(find.text(destino));
          final parrafo = tester.renderObject<RenderParagraph>(
            find.text(destino),
          );
          expect(parrafo.didExceedMaxLines, isFalse, reason: destino);
          expect(
            parrafo.size.width,
            greaterThanOrEqualTo(
              parrafo.getMaxIntrinsicWidth(double.infinity) - 0.5,
            ),
            reason: destino,
          );
          expect(rect.left, greaterThanOrEqualTo(0), reason: destino);
          expect(rect.right, lessThanOrEqualTo(ancho), reason: destino);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'con el texto al 200 % la barra del socio muestra RESERVAS entera @REV-04-S8',
    (tester) async {
      await montar(
        tester,
        const Scaffold(
          bottomNavigationBar: BarraInferior(actual: Seccion.reservas),
        ),
        tema: temaOscuro,
        tamano: const Size(360, 800),
        escalaTexto: 2,
      );

      final reservas = tester.renderObject<RenderParagraph>(
        find.text('RESERVAS'),
      );
      expect(reservas.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'con el texto al 200 % la barra del admin no pega ESPACIOS al borde @REV-04-S8',
    (tester) async {
      await montar(
        tester,
        const Scaffold(
          bottomNavigationBar: BarraAdmin(actual: SeccionAdmin.espacios),
        ),
        tema: temaOscuro,
        tamano: const Size(360, 800),
        escalaTexto: 2,
      );

      final espacios = tester.renderObject<RenderParagraph>(
        find.text('ESPACIOS'),
      );
      expect(espacios.didExceedMaxLines, isFalse);
      expect(
        tester.getRect(find.text('ESPACIOS')).right,
        lessThanOrEqualTo(352),
      );
    },
  );

  testWidgets(
    'el botón atenuado en modo oscuro se lee con contraste suficiente @REV-04-S9',
    (tester) async {
      await montar(
        tester,
        Scaffold(
          body: Center(
            child: BotonPrimario(
              texto: 'GUARDAR SEDE',
              alTocar: () {},
              atenuado: true,
            ),
          ),
        ),
        tema: temaOscuro,
      );
      final estilo = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      // El fondo atenuado es translúcido: lo que ve la persona es la mezcla con la pantalla.
      final fondo = Color.alphaBlend(
        estilo.backgroundColor!.resolve(<WidgetState>{})!,
        temaOscuro.scaffoldBackgroundColor,
      );
      final texto = estilo.foregroundColor!.resolve(<WidgetState>{})!;

      expect(contraste(texto, fondo), greaterThanOrEqualTo(4.5));
    },
  );

  testWidgets(
    'el calendario de nacimiento termina el día anterior al del club @REV-04-S10 '
    '@assumption:REV-04-ASM-08',
    (tester) async {
      DateTime? elegida;
      // 02:30 UTC del 13 de noviembre: en el club todavía es el 12 a las 23:30.
      await withClock(Clock.fixed(DateTime.utc(2026, 11, 13, 2, 30)), () async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es', 'AR'),
            supportedLocales: const [Locale('es', 'AR')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Builder(
              builder: (contexto) => TextButton(
                onPressed: () async => elegida = await elegirFechaDeNacimiento(
                  contexto,
                  DateTime(2030),
                ),
                child: const Text('ABRIR'),
              ),
            ),
          ),
        );
        await tocar(tester, find.text('ABRIR'));
        await tocar(
          tester,
          find.textContaining(RegExp('aceptar', caseSensitive: false)),
        );
      });

      expect(elegida, DateTime(2026, 11, 11));
    },
  );

  test(
    'la hora del club sale del reloj, el que las capturas fijan @REV-04-S11',
    () {
      final ahora = withClock(
        Clock.fixed(DateTime.utc(2026, 11, 13, 2, 30)),
        ahoraEnElClub,
      );

      expect(
        (ahora.year, ahora.month, ahora.day, ahora.hour, ahora.minute),
        (2026, 11, 12, 23, 30),
      );
    },
  );

  Future<void> altaDeEspacio(WidgetTester tester, {double escala = 1}) async {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await montarAdmin(
      tester,
      inicio: '/admin/espacios/nuevo',
      tamano: const Size(320, 568),
      api: apiRutas(rutasDeEspacios()),
    );
  }

  testWidgets(
    'el alta de espacio entra entera en una pantalla de 320 × 568 @REV-04-S12',
    (tester) async {
      await altaDeEspacio(tester);
      await elegir(tester, 'Sede', 'Sede Morón');
      await elegir(tester, 'Deporte', 'Fútbol');
      await elegir(tester, 'Tipo', 'Fútbol 5');
      await tocar(tester, find.text('GUARDAR ESPACIO'));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a 320 × 568 los faltantes del alta de espacio entran enteros @REV-04-S12',
    (tester) async {
      await altaDeEspacio(tester);

      await tocar(tester, find.text('GUARDAR ESPACIO'));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a 320 × 568 el alta de espacio completa, con su nombre generado, entra entera '
    '@REV-04-S12',
    (tester) async {
      await altaDeEspacio(tester, escala: 1.3);
      await elegir(tester, 'Sede', 'Sede Morón');
      await elegir(tester, 'Deporte', 'Fútbol');
      await elegir(tester, 'Tipo', 'Fútbol 5');
      await elegir(tester, 'Condición', 'Al aire libre');
      await elegir(tester, 'Iluminación', 'Iluminada');
      await tester.enterText(find.bySemanticsLabel('Precio por hora'), '38000');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a 320 × 568 el selector de sede abierto entra entero @REV-04-S12',
    (tester) async {
      await altaDeEspacio(tester);

      await tocar(tester, find.bySemanticsLabel(RegExp('^Sede')));

      expect(tester.takeException(), isNull);
    },
  );
}
