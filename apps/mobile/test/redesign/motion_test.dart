import 'dart:math' as math;

import 'package:clubnahuelmosse/common/motion.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Duration _ms(int n) => Duration(milliseconds: n);

final _cero = closeTo(0, 1e-6);
final _uno = closeTo(1, 1e-6);

/// Una pieza sola, arriba a la izquierda de una pantalla de 400 × 800.
Future<void> _montar(WidgetTester tester, Widget hijo) async {
  tester.view.physicalSize = const Size(400, 800) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: darkTheme,
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: hijo),
      ),
    ),
  );
}

void _reducirMovimiento(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// La opacidad de [aparecer], leída de su `FadeTransition`.
double _opacidad(WidgetTester tester, Finder aparecer) => tester
    .widget<FadeTransition>(
      find
          .descendant(of: aparecer, matching: find.byType(FadeTransition))
          .first,
    )
    .opacity
    .value;

Finder _aparecerDe(Finder hijo) =>
    find.ancestor(of: hijo, matching: find.byType(FadeIn)).first;

Offset _posicion(WidgetTester tester, Finder f) => tester.getTopLeft(f);

/// El ancho que se ve de [f], con la escala de las piezas que lo envuelven.
double _anchoVisible(WidgetTester tester, Finder f) =>
    tester.getBottomRight(f).dx - tester.getTopLeft(f).dx;

/// El radio del recorte que revela el ícono de [dentro].
double _radioDeRecorte(WidgetTester tester, Finder dentro) {
  final recortes = find.descendant(
    of: dentro,
    matching: find.byWidgetPredicate((w) => w is ClipOval || w is ClipPath),
  );
  expect(recortes, findsWidgets);
  final objeto = tester.renderObject(recortes.first);
  if (objeto is RenderClipPath) {
    final recortador = objeto.clipper;
    if (recortador == null) fail('el recorte no tiene un recortador propio');
    return recortador.getClip(objeto.size).getBounds().width / 2;
  }
  if (objeto is RenderClipOval) {
    final recortador = objeto.clipper;
    if (recortador == null) fail('el recorte no tiene un recortador propio');
    return recortador.getClip(objeto.size).width / 2;
  }
  fail('el recorte no es un ClipPath ni un ClipOval');
}

/// Lo que desplaza el temblor [milisegundos] después de empezar.
double _temblorEsperado(int milisegundos) {
  const puntos = [0.0, -9.0, 9.0, -6.0, 6.0, -3.0, 0.0];
  final i = math.min((milisegundos / 60).floor(), puntos.length - 2);
  final fraccion = (milisegundos - i * 60) / 60;
  return puntos[i] + (puntos[i + 1] - puntos[i]) * fraccion;
}

/// Todas las piezas juntas, con un disparador común para el temblor y el latido.
class _Piezas {
  static const aparecer = Key('aparecer');
  static const bloque0 = Key('bloque-0');
  static const bloque1 = Key('bloque-1');
  static const temblor = Key('temblor');
  static const latido = Key('latido');
  static const presion = Key('presion');

  final disparo = ValueNotifier<int>(0);
  final redibujar = ValueNotifier<int>(0);

  Widget get widget => ListenableBuilder(
    listenable: Listenable.merge([disparo, redibujar]),
    builder: (context, _) {
      final disparador = disparo.value == 0 ? null : disparo.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FadeIn(
            delay: Duration(milliseconds: 200),
            fromY: 30,
            child: SizedBox(key: aparecer, width: 100, height: 30),
          ),
          const StaggeredEntrance(
            children: [
              SizedBox(key: bloque0, width: 100, height: 30),
              SizedBox(key: bloque1, width: 100, height: 30),
            ],
          ),
          Shake(
            trigger: disparador,
            child: const SizedBox(key: temblor, width: 100, height: 30),
          ),
          const SuccessPulse(
            icon: Icons.check_rounded,
            background: Color(0xFF1B5E20),
            ink: Color(0xFFFFFFFF),
          ),
          Heartbeat(
            trigger: disparador,
            child: const SizedBox(key: latido, width: 100, height: 30),
          ),
          const Pressable(
            child: ColoredBox(
              color: Color(0xFFFF0000),
              child: SizedBox(key: presion, width: 100, height: 30),
            ),
          ),
        ],
      );
    },
  );

  List<Offset> posiciones(WidgetTester tester) => [
    for (final clave in const [
      aparecer,
      bloque0,
      bloque1,
      temblor,
      latido,
      presion,
    ])
      tester.getTopLeft(find.byKey(clave)),
  ];

  List<double> anchos(WidgetTester tester) => [
    for (final clave in const [aparecer, bloque0, bloque1, temblor, latido])
      _anchoVisible(tester, find.byKey(clave)),
  ];
}

void main() {
  testWidgets(
    'aparecer va de transparente y corrido a su lugar con easeOut @RED-04-S6',
    (tester) async {
      const hijo = Key('hijo');
      await _montar(
        tester,
        const FadeIn(
          fromX: 30,
          fromY: 20,
          duration: Duration(milliseconds: 400),
          child: SizedBox(key: hijo, width: 100, height: 40),
        ),
      );
      final inicial = _posicion(tester, find.byKey(hijo));
      expect(_opacidad(tester, find.byType(FadeIn)), 0);

      await tester.pump(_ms(200));
      final medio = _posicion(tester, find.byKey(hijo));
      final opacidadMedia = _opacidad(tester, find.byType(FadeIn));

      await tester.pumpAndSettle();
      final fin = _posicion(tester, find.byKey(hijo));

      expect(inicial.dx - fin.dx, closeTo(30, 0.01));
      expect(inicial.dy - fin.dy, closeTo(20, 0.01));
      final avance = Curves.easeOut.transform(0.5);
      expect(medio.dx - fin.dx, closeTo(30 * (1 - avance), 0.05));
      expect(medio.dy - fin.dy, closeTo(20 * (1 - avance), 0.05));
      expect(opacidadMedia, allOf(greaterThan(0), lessThan(1)));
      expect(_opacidad(tester, find.byType(FadeIn)), _uno);
      expect(fin.dx, _cero);
      expect(fin.dy, _cero);

      await _montar(tester, const SizedBox.shrink());
      await _montar(
        tester,
        const FadeIn(
          turn: 0.25,
          scaleFrom: 0.5,
          fromY: 0,
          child: SizedBox(key: hijo, width: 100, height: 40),
        ),
      );
      // Un cuarto de vuelta a media escala: el rectángulo se ve de lado y a la mitad.
      final esquina =
          tester.getBottomRight(find.byKey(hijo)) -
          tester.getTopLeft(find.byKey(hijo));
      expect(esquina.dx.abs(), closeTo(20, 0.05));
      expect(esquina.dy.abs(), closeTo(50, 0.05));
      await tester.pumpAndSettle();
      final entera =
          tester.getBottomRight(find.byKey(hijo)) -
          tester.getTopLeft(find.byKey(hijo));
      expect(entera.dx, closeTo(100, 0.01));
      expect(entera.dy, closeTo(40, 0.01));
    },
  );

  testWidgets(
    'la entrada escalonada arranca cada bloque a su tiempo @RED-04-S6',
    (tester) async {
      const bloques = [Key('b0'), Key('b1'), Key('b2')];
      await _montar(
        tester,
        const StaggeredEntrance(
          start: Duration(milliseconds: 100),
          step: Duration(milliseconds: 50),
          children: [
            SizedBox(key: Key('b0'), width: 100, height: 30),
            SizedBox(key: Key('b1'), width: 100, height: 30),
            SizedBox(key: Key('b2'), width: 100, height: 30),
          ],
        ),
      );
      double opacidad(int i) =>
          _opacidad(tester, _aparecerDe(find.byKey(bloques[i])));

      for (var i = 0; i < bloques.length; i++) {
        expect(
          tester.widget<FadeIn>(_aparecerDe(find.byKey(bloques[i]))).delay,
          _ms(100 + 50 * i),
        );
        expect(opacidad(i), 0, reason: 'bloque $i en 0 ms');
      }

      // Antes de su retraso, cada bloque sigue transparente; después, ya empezó.
      await tester.pump(_ms(90));
      expect([opacidad(0), opacidad(1), opacidad(2)], [0, 0, 0]);
      await tester.pump(_ms(60));
      expect(opacidad(0), greaterThan(0));
      expect(opacidad(1), 0);
      expect(opacidad(2), 0);
      await tester.pump(_ms(50));
      expect(opacidad(1), greaterThan(0));
      expect(opacidad(2), 0);
      await tester.pump(_ms(50));
      expect(opacidad(2), greaterThan(0));

      await tester.pumpAndSettle();
      expect([opacidad(0), opacidad(1), opacidad(2)], [1, 1, 1]);
    },
  );

  testWidgets(
    'el temblor pasa por −9, 9, −6, 6, −3 y vuelve a 0 en 360 ms @RED-04-S7',
    (tester) async {
      const hijo = Key('hijo');
      Object? disparador;
      late StateSetter reconstruir;
      await _montar(
        tester,
        StatefulBuilder(
          builder: (context, set) {
            reconstruir = set;
            return Shake(
              trigger: disparador,
              child: const SizedBox(key: hijo, width: 100, height: 40),
            );
          },
        ),
      );
      double desplazamiento() => tester.getTopLeft(find.byKey(hijo)).dx;
      expect(desplazamiento(), _cero);

      // Sin disparador no tiembla.
      await tester.pump(_ms(500));
      expect(desplazamiento(), _cero);

      reconstruir(() => disparador = 'primero');
      await tester.pump();
      expect(desplazamiento(), closeTo(0, 0.01));
      for (var t = 30; t <= 360; t += 30) {
        await tester.pump(_ms(30));
        expect(
          desplazamiento(),
          closeTo(_temblorEsperado(t), 0.01),
          reason: 'a los $t ms',
        );
      }
      await tester.pump(_ms(500));
      expect(desplazamiento(), _cero);

      // El mismo disparador, aunque se reconstruya, no tiembla.
      reconstruir(() => disparador = 'primero');
      await tester.pump();
      await tester.pump(_ms(60));
      expect(desplazamiento(), _cero);
      await tester.pump(_ms(300));
      expect(desplazamiento(), _cero);

      // Otro valor no nulo vuelve a hacerlo temblar.
      reconstruir(() => disparador = 'segundo');
      await tester.pump();
      await tester.pump(_ms(60));
      expect(desplazamiento(), closeTo(-9, 0.01));
      await tester.pumpAndSettle();
      expect(desplazamiento(), _cero);

      // Quitar el disparador no es un temblor.
      reconstruir(() => disparador = null);
      await tester.pump();
      await tester.pump(_ms(60));
      expect(desplazamiento(), _cero);
    },
  );

  testWidgets(
    'el pulso de éxito escala el círculo de 0,4 a 1 y revela el ícono @RED-04-S8',
    (tester) async {
      await _montar(
        tester,
        const SuccessPulse(
          icon: Icons.check_rounded,
          background: Color(0xFF1B5E20),
          ink: Color(0xFFFFFFFF),
        ),
      );
      final pulso = find.byType(SuccessPulse);
      double escala() => tester
          .widget<ScaleTransition>(
            find
                .descendant(of: pulso, matching: find.byType(ScaleTransition))
                .first,
          )
          .scale
          .value;

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(escala(), closeTo(0.4, 1e-6));
      expect(_radioDeRecorte(tester, pulso), _cero);

      // El ícono empieza a revelarse a los 170 ms.
      await tester.pump(_ms(150));
      expect(_radioDeRecorte(tester, pulso), _cero);
      await tester.pump(_ms(245));
      final radioMedio = _radioDeRecorte(tester, pulso);
      expect(escala(), greaterThan(0.4));

      await tester.pump(_ms(155));
      expect(escala(), closeTo(1, 1e-3));

      await tester.pump(_ms(100));
      final radioCompleto = _radioDeRecorte(tester, pulso);
      await tester.pumpAndSettle();
      expect(_radioDeRecorte(tester, pulso), closeTo(radioCompleto, 1e-6));
      expect(radioCompleto, greaterThan(0));
      expect(radioMedio, greaterThan(0));
      expect(escala(), closeTo(1, 1e-6));
    },
  );

  testWidgets('el latido va a 1,03 y vuelve a 1 en 500 ms @RED-04-S10', (
    tester,
  ) async {
    const hijo = Key('hijo');
    Object? disparador;
    late StateSetter reconstruir;
    await _montar(
      tester,
      StatefulBuilder(
        builder: (context, set) {
          reconstruir = set;
          return Heartbeat(
            trigger: disparador,
            child: const SizedBox(key: hijo, width: 100, height: 40),
          );
        },
      ),
    );
    double escala() => _anchoVisible(tester, find.byKey(hijo)) / 100;
    expect(escala(), _uno);
    await tester.pump(_ms(600));
    expect(escala(), _uno);

    reconstruir(() => disparador = 1);
    await tester.pump();
    expect(escala(), closeTo(1, 1e-3));
    await tester.pump(_ms(200));
    expect(escala(), allOf(greaterThan(1), lessThanOrEqualTo(1.0301)));
    await tester.pump(_ms(50));
    expect(escala(), closeTo(1.03, 2e-3));
    await tester.pump(_ms(250));
    expect(escala(), closeTo(1, 1e-3));

    // El mismo disparador no late de nuevo.
    reconstruir(() => disparador = 1);
    await tester.pump();
    await tester.pump(_ms(250));
    expect(escala(), _uno);

    reconstruir(() => disparador = 2);
    await tester.pump();
    await tester.pump(_ms(250));
    expect(escala(), greaterThan(1));
    await tester.pumpAndSettle();
    expect(escala(), _uno);
  });

  testWidgets(
    'presionar achica a 0,97 en 80 ms y soltar vuelve a 1 @RED-04-S13',
    (tester) async {
      const hijo = Key('hijo');
      await _montar(
        tester,
        const Pressable(
          child: ColoredBox(
            color: Color(0xFFFF0000),
            child: SizedBox(key: hijo, width: 120, height: 40),
          ),
        ),
      );
      double escala() => _anchoVisible(tester, find.byKey(hijo)) / 120;
      expect(escala(), _uno);

      final dedo = await tester.startGesture(
        tester.getCenter(find.byKey(hijo)),
      );
      await tester.pump();
      await tester.pump(_ms(40));
      expect(escala(), allOf(greaterThan(0.97), lessThan(1)));
      await tester.pump(_ms(40));
      expect(escala(), closeTo(0.97, 1e-3));
      await tester.pump(_ms(500));
      expect(escala(), closeTo(0.97, 1e-3));

      await dedo.up();
      await tester.pump();
      await tester.pump(_ms(80));
      expect(escala(), closeTo(1, 1e-3));
    },
  );

  testWidgets(
    'con reducir movimiento cada pieza muestra su estado final en el primer cuadro @RED-04-S14',
    (tester) async {
      final piezas = _Piezas();
      addTearDown(piezas.disparo.dispose);
      addTearDown(piezas.redibujar.dispose);
      _reducirMovimiento(tester);
      await _montar(tester, piezas.widget);

      double escalaDelPulso() => tester
          .widget<ScaleTransition>(
            find
                .descendant(
                  of: find.byType(SuccessPulse),
                  matching: find.byType(ScaleTransition),
                )
                .first,
          )
          .scale
          .value;

      // El primer cuadro ya es el final de cada pieza.
      expect(_opacidad(tester, find.byType(FadeIn).first), 1);
      expect(_opacidad(tester, _aparecerDe(find.byKey(_Piezas.bloque0))), 1);
      expect(_opacidad(tester, _aparecerDe(find.byKey(_Piezas.bloque1))), 1);
      expect(escalaDelPulso(), 1);
      final radioEnElPrimerCuadro = _radioDeRecorte(
        tester,
        find.byType(SuccessPulse),
      );
      final desplazadas = piezas.posiciones(tester);

      piezas.disparo.value = 1;
      await tester.pump();
      expect(piezas.posiciones(tester), desplazadas);
      expect(piezas.anchos(tester), everyElement(closeTo(100, 1e-6)));
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pumpAndSettle();
      expect(piezas.posiciones(tester), desplazadas);
      expect(escalaDelPulso(), 1);
      expect(
        _radioDeRecorte(tester, find.byType(SuccessPulse)),
        closeTo(radioEnElPrimerCuadro, 1e-6),
      );
      expect(radioEnElPrimerCuadro, greaterThan(0));
      expect(piezas.posiciones(tester)[0], Offset.zero);
    },
  );

  testWidgets('ninguna pieza se repite sola después de terminar @RED-04-S15', (
    tester,
  ) async {
    final piezas = _Piezas();
    addTearDown(piezas.disparo.dispose);
    addTearDown(piezas.redibujar.dispose);
    await _montar(tester, piezas.widget);

    piezas.disparo.value = 1;
    await tester.pump();
    await tester.pump(_ms(100));
    // Si alguna se repitiera, esto no terminaría nunca.
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    final quietas = piezas.posiciones(tester);
    final anchos = piezas.anchos(tester);
    expect(_opacidad(tester, find.byType(FadeIn).first), 1);

    await tester.pump(const Duration(seconds: 5));
    expect(piezas.posiciones(tester), quietas);
    expect(piezas.anchos(tester), anchos);
    expect(tester.binding.hasScheduledFrame, isFalse);

    // Reconstruir sin cambiar el disparador tampoco las vuelve a mover.
    piezas.redibujar.value++;
    await tester.pump();
    await tester.pump(_ms(1000));
    expect(piezas.posiciones(tester), quietas);
    expect(piezas.anchos(tester), anchos);
    expect(_opacidad(tester, find.byType(FadeIn).first), 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  test(
    'las curvas son easeOut, easeOutCubic, easeOutQuart y easeOutBack @RED-04-ASM-02',
    () {
      expect(AppMotion.out, same(Curves.easeOut));
      expect(AppMotion.smooth, same(Curves.easeOutCubic));
      expect(AppMotion.fast, same(Curves.easeOutQuart));
      expect(AppMotion.bounce, same(Curves.easeOutBack));

      expect(AppMotion.forward, _ms(320));
      expect(AppMotion.back, _ms(280));
      expect(AppMotion.fade, _ms(250));
      expect(AppMotion.listChange, _ms(150));
      expect(AppMotion.shake, _ms(360));
      expect(AppMotion.heartbeat, _ms(500));
      expect(AppMotion.press, _ms(80));
      expect(AppMotion.entrance, _ms(400));
      expect(AppMotion.step, _ms(80));
    },
  );

  testWidgets(
    'al salir a mitad de una animación no queda ningún temporizador pendiente @RED-04-ASM-03',
    (tester) async {
      final piezas = _Piezas();
      addTearDown(piezas.disparo.dispose);
      addTearDown(piezas.redibujar.dispose);
      await _montar(tester, piezas.widget);

      piezas.disparo.value = 1;
      await tester.pump();
      await tester.pump(_ms(100));
      final dedo = await tester.startGesture(
        tester.getCenter(find.byKey(_Piezas.presion)),
      );
      await tester.pump(_ms(20));

      // Se sale con todo a mitad: el retraso del aparecer, el temblor, el latido y el pulso.
      await tester.pumpWidget(const SizedBox.shrink());
      await dedo.cancel();
      await tester.pump(const Duration(seconds: 5));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets(
    'un bloque que entra ya está en el árbol del lector @RED-04-ASM-11',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await _montar(
        tester,
        FadeIn(
          delay: const Duration(milliseconds: 500),
          child: Semantics(
            label: 'Bloque de prueba',
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      );

      // Transparente y todavía sin empezar, pero el lector ya lo ve.
      expect(_opacidad(tester, find.byType(FadeIn)), 0);
      expect(find.bySemanticsLabel('Bloque de prueba'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Bloque de prueba')).label,
        'Bloque de prueba',
      );

      await tester.pump(_ms(300));
      expect(_opacidad(tester, find.byType(FadeIn)), 0);
      expect(find.bySemanticsLabel('Bloque de prueba'), findsOneWidget);

      await tester.pump(_ms(400));
      expect(_opacidad(tester, find.byType(FadeIn)), greaterThan(0));
      expect(find.bySemanticsLabel('Bloque de prueba'), findsOneWidget);
      semantica.dispose();
    },
  );
}
