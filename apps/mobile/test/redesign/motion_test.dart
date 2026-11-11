import 'dart:math' as math;

import 'package:clubnahuelmosse/common/motion.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Duration _ms(int n) => Duration(milliseconds: n);

final _zero = closeTo(0, 1e-6);
final _one = closeTo(1, 1e-6);

/// A single piece, at the top left of a 400 × 800 screen.
Future<void> _mount(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(400, 800) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: darkTheme,
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );
}

void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// The opacity of [appearance], read from its `FadeTransition`.
double _opacity(WidgetTester tester, Finder appearance) => tester
    .widget<FadeTransition>(
      find
          .descendant(of: appearance, matching: find.byType(FadeTransition))
          .first,
    )
    .opacity
    .value;

Finder _appearanceOf(Finder child) =>
    find.ancestor(of: child, matching: find.byType(FadeIn)).first;

Offset _position(WidgetTester tester, Finder f) => tester.getTopLeft(f);

/// The visible width of [f], with the scale of the pieces that wrap it.
double _visibleWidth(WidgetTester tester, Finder f) =>
    tester.getBottomRight(f).dx - tester.getTopLeft(f).dx;

/// The radius of the clip that reveals the icon of [inside].
double _clipRadius(WidgetTester tester, Finder inside) {
  final clips = find.descendant(
    of: inside,
    matching: find.byWidgetPredicate((w) => w is ClipOval || w is ClipPath),
  );
  expect(clips, findsWidgets);
  final object = tester.renderObject(clips.first);
  if (object is RenderClipPath) {
    final clipper = object.clipper;
    if (clipper == null) fail('the clip has no clipper of its own');
    return clipper.getClip(object.size).getBounds().width / 2;
  }
  if (object is RenderClipOval) {
    final clipper = object.clipper;
    if (clipper == null) fail('the clip has no clipper of its own');
    return clipper.getClip(object.size).width / 2;
  }
  fail('the clip is neither a ClipPath nor a ClipOval');
}

/// What the shake displaces [milliseconds] after starting.
double _expectedShake(int milliseconds) {
  const points = [0.0, -9.0, 9.0, -6.0, 6.0, -3.0, 0.0];
  final i = math.min((milliseconds / 60).floor(), points.length - 2);
  final fraction = (milliseconds - i * 60) / 60;
  return points[i] + (points[i + 1] - points[i]) * fraction;
}

/// All the pieces together, with a common trigger for the shake and the heartbeat.
class _Pieces {
  static const appearance = Key('aparecer');
  static const block0 = Key('bloque-0');
  static const block1 = Key('bloque-1');
  static const shake = Key('temblor');
  static const heartbeat = Key('latido');
  static const pressKey = Key('presion');

  final firing = ValueNotifier<int>(0);
  final repaint = ValueNotifier<int>(0);

  Widget get widget => ListenableBuilder(
    listenable: Listenable.merge([firing, repaint]),
    builder: (context, _) {
      final trigger = firing.value == 0 ? null : firing.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FadeIn(
            delay: Duration(milliseconds: 200),
            fromY: 30,
            child: SizedBox(key: appearance, width: 100, height: 30),
          ),
          const StaggeredEntrance(
            children: [
              SizedBox(key: block0, width: 100, height: 30),
              SizedBox(key: block1, width: 100, height: 30),
            ],
          ),
          Shake(
            trigger: trigger,
            child: const SizedBox(key: shake, width: 100, height: 30),
          ),
          const SuccessPulse(
            icon: Icons.check_rounded,
            background: Color(0xFF1B5E20),
            ink: Color(0xFFFFFFFF),
          ),
          Heartbeat(
            trigger: trigger,
            child: const SizedBox(key: heartbeat, width: 100, height: 30),
          ),
          const Pressable(
            child: ColoredBox(
              color: Color(0xFFFF0000),
              child: SizedBox(key: pressKey, width: 100, height: 30),
            ),
          ),
        ],
      );
    },
  );

  List<Offset> positions(WidgetTester tester) => [
    for (final key in const [
      appearance,
      block0,
      block1,
      shake,
      heartbeat,
      pressKey,
    ])
      tester.getTopLeft(find.byKey(key)),
  ];

  List<double> widths(WidgetTester tester) => [
    for (final key in const [appearance, block0, block1, shake, heartbeat])
      _visibleWidth(tester, find.byKey(key)),
  ];
}

void main() {
  testWidgets(
    'appearance goes from transparent and offset to its place with easeOut @RED-04-S6',
    (tester) async {
      const child = Key('hijo');
      await _mount(
        tester,
        const FadeIn(
          fromX: 30,
          fromY: 20,
          duration: Duration(milliseconds: 400),
          child: SizedBox(key: child, width: 100, height: 40),
        ),
      );
      final initial = _position(tester, find.byKey(child));
      expect(_opacity(tester, find.byType(FadeIn)), 0);

      await tester.pump(_ms(200));
      final middle = _position(tester, find.byKey(child));
      final halfOpacity = _opacity(tester, find.byType(FadeIn));

      await tester.pumpAndSettle();
      final end = _position(tester, find.byKey(child));

      expect(initial.dx - end.dx, closeTo(30, 0.01));
      expect(initial.dy - end.dy, closeTo(20, 0.01));
      final progress = Curves.easeOut.transform(0.5);
      expect(middle.dx - end.dx, closeTo(30 * (1 - progress), 0.05));
      expect(middle.dy - end.dy, closeTo(20 * (1 - progress), 0.05));
      expect(halfOpacity, allOf(greaterThan(0), lessThan(1)));
      expect(_opacity(tester, find.byType(FadeIn)), _one);
      expect(end.dx, _zero);
      expect(end.dy, _zero);

      await _mount(tester, const SizedBox.shrink());
      await _mount(
        tester,
        const FadeIn(
          turn: 0.25,
          scaleFrom: 0.5,
          fromY: 0,
          child: SizedBox(key: child, width: 100, height: 40),
        ),
      );
      // A quarter turn at half scale: the rectangle is seen sideways and at half size.
      final corner =
          tester.getBottomRight(find.byKey(child)) -
          tester.getTopLeft(find.byKey(child));
      expect(corner.dx.abs(), closeTo(20, 0.05));
      expect(corner.dy.abs(), closeTo(50, 0.05));
      await tester.pumpAndSettle();
      final wholeWidth =
          tester.getBottomRight(find.byKey(child)) -
          tester.getTopLeft(find.byKey(child));
      expect(wholeWidth.dx, closeTo(100, 0.01));
      expect(wholeWidth.dy, closeTo(40, 0.01));
    },
  );

  testWidgets('the staggered entrance starts each block at its time @RED-04-S6', (
    tester,
  ) async {
    const blocks = [Key('b0'), Key('b1'), Key('b2')];
    await _mount(
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
    double opacity(int i) =>
        _opacity(tester, _appearanceOf(find.byKey(blocks[i])));

    for (var i = 0; i < blocks.length; i++) {
      expect(
        tester.widget<FadeIn>(_appearanceOf(find.byKey(blocks[i]))).delay,
        _ms(100 + 50 * i),
      );
      expect(opacity(i), 0, reason: 'block $i at 0 ms');
    }

    // Before its delay each block is still transparent; after it, it has started.
    await tester.pump(_ms(90));
    expect([opacity(0), opacity(1), opacity(2)], [0, 0, 0]);
    await tester.pump(_ms(60));
    expect(opacity(0), greaterThan(0));
    expect(opacity(1), 0);
    expect(opacity(2), 0);
    await tester.pump(_ms(50));
    expect(opacity(1), greaterThan(0));
    expect(opacity(2), 0);
    await tester.pump(_ms(50));
    expect(opacity(2), greaterThan(0));

    await tester.pumpAndSettle();
    expect([opacity(0), opacity(1), opacity(2)], [1, 1, 1]);
  });

  testWidgets(
    'the shake goes through −9, 9, −6, 6, −3 and returns to 0 in 360 ms @RED-04-S7',
    (tester) async {
      const child = Key('hijo');
      Object? trigger;
      late StateSetter rebuild;
      await _mount(
        tester,
        StatefulBuilder(
          builder: (context, set) {
            rebuild = set;
            return Shake(
              trigger: trigger,
              child: const SizedBox(key: child, width: 100, height: 40),
            );
          },
        ),
      );
      double displacement() => tester.getTopLeft(find.byKey(child)).dx;
      expect(displacement(), _zero);

      // Without a trigger it does not shake.
      await tester.pump(_ms(500));
      expect(displacement(), _zero);

      rebuild(() => trigger = 'primero');
      await tester.pump();
      expect(displacement(), closeTo(0, 0.01));
      for (var t = 30; t <= 360; t += 30) {
        await tester.pump(_ms(30));
        expect(
          displacement(),
          closeTo(_expectedShake(t), 0.01),
          reason: 'at $t ms',
        );
      }
      await tester.pump(_ms(500));
      expect(displacement(), _zero);

      // The same trigger, even if rebuilt, does not shake.
      rebuild(() => trigger = 'primero');
      await tester.pump();
      await tester.pump(_ms(60));
      expect(displacement(), _zero);
      await tester.pump(_ms(300));
      expect(displacement(), _zero);

      // Another non-null value makes it shake again.
      rebuild(() => trigger = 'segundo');
      await tester.pump();
      await tester.pump(_ms(60));
      expect(displacement(), closeTo(-9, 0.01));
      await tester.pumpAndSettle();
      expect(displacement(), _zero);

      // Removing the trigger is not a shake.
      rebuild(() => trigger = null);
      await tester.pump();
      await tester.pump(_ms(60));
      expect(displacement(), _zero);
    },
  );

  testWidgets(
    'the success pulse scales the circle from 0.4 to 1 and reveals the icon @RED-04-S8',
    (tester) async {
      await _mount(
        tester,
        const SuccessPulse(
          icon: Icons.check_rounded,
          background: Color(0xFF1B5E20),
          ink: Color(0xFFFFFFFF),
        ),
      );
      final pulse = find.byType(SuccessPulse);
      double scale() => tester
          .widget<ScaleTransition>(
            find
                .descendant(of: pulse, matching: find.byType(ScaleTransition))
                .first,
          )
          .scale
          .value;

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(scale(), closeTo(0.4, 1e-6));
      expect(_clipRadius(tester, pulse), _zero);

      // The icon starts to be revealed at 170 ms.
      await tester.pump(_ms(150));
      expect(_clipRadius(tester, pulse), _zero);
      await tester.pump(_ms(245));
      final halfRadius = _clipRadius(tester, pulse);
      expect(scale(), greaterThan(0.4));

      await tester.pump(_ms(155));
      expect(scale(), closeTo(1, 1e-3));

      await tester.pump(_ms(100));
      final fullRadius = _clipRadius(tester, pulse);
      await tester.pumpAndSettle();
      expect(_clipRadius(tester, pulse), closeTo(fullRadius, 1e-6));
      expect(fullRadius, greaterThan(0));
      expect(halfRadius, greaterThan(0));
      expect(scale(), closeTo(1, 1e-6));
    },
  );

  testWidgets(
    'the heartbeat goes to 1.03 and returns to 1 in 500 ms @RED-04-S10',
    (tester) async {
      const child = Key('hijo');
      Object? trigger;
      late StateSetter rebuild;
      await _mount(
        tester,
        StatefulBuilder(
          builder: (context, set) {
            rebuild = set;
            return Heartbeat(
              trigger: trigger,
              child: const SizedBox(key: child, width: 100, height: 40),
            );
          },
        ),
      );
      double scale() => _visibleWidth(tester, find.byKey(child)) / 100;
      expect(scale(), _one);
      await tester.pump(_ms(600));
      expect(scale(), _one);

      rebuild(() => trigger = 1);
      await tester.pump();
      expect(scale(), closeTo(1, 1e-3));
      await tester.pump(_ms(200));
      expect(scale(), allOf(greaterThan(1), lessThanOrEqualTo(1.0301)));
      await tester.pump(_ms(50));
      expect(scale(), closeTo(1.03, 2e-3));
      await tester.pump(_ms(250));
      expect(scale(), closeTo(1, 1e-3));

      // The same trigger does not beat again.
      rebuild(() => trigger = 1);
      await tester.pump();
      await tester.pump(_ms(250));
      expect(scale(), _one);

      rebuild(() => trigger = 2);
      await tester.pump();
      await tester.pump(_ms(250));
      expect(scale(), greaterThan(1));
      await tester.pumpAndSettle();
      expect(scale(), _one);
    },
  );

  testWidgets(
    'pressing shrinks to 0.97 in 80 ms and releasing returns to 1 @RED-04-S13',
    (tester) async {
      const child = Key('hijo');
      await _mount(
        tester,
        const Pressable(
          child: ColoredBox(
            color: Color(0xFFFF0000),
            child: SizedBox(key: child, width: 120, height: 40),
          ),
        ),
      );
      double scale() => _visibleWidth(tester, find.byKey(child)) / 120;
      expect(scale(), _one);

      final finger = await tester.startGesture(
        tester.getCenter(find.byKey(child)),
      );
      await tester.pump();
      await tester.pump(_ms(40));
      expect(scale(), allOf(greaterThan(0.97), lessThan(1)));
      await tester.pump(_ms(40));
      expect(scale(), closeTo(0.97, 1e-3));
      await tester.pump(_ms(500));
      expect(scale(), closeTo(0.97, 1e-3));

      await finger.up();
      await tester.pump();
      await tester.pump(_ms(80));
      expect(scale(), closeTo(1, 1e-3));
    },
  );

  testWidgets(
    'with reduce motion each piece shows its end state on the first frame @RED-04-S14',
    (tester) async {
      final pieces = _Pieces();
      addTearDown(pieces.firing.dispose);
      addTearDown(pieces.repaint.dispose);
      _reduceMotion(tester);
      await _mount(tester, pieces.widget);

      double pulseScale() => tester
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

      // The first frame is already the end of each piece.
      expect(_opacity(tester, find.byType(FadeIn).first), 1);
      expect(_opacity(tester, _appearanceOf(find.byKey(_Pieces.block0))), 1);
      expect(_opacity(tester, _appearanceOf(find.byKey(_Pieces.block1))), 1);
      expect(pulseScale(), 1);
      final radiusAtFirstFrame = _clipRadius(tester, find.byType(SuccessPulse));
      final displaced = pieces.positions(tester);

      pieces.firing.value = 1;
      await tester.pump();
      expect(pieces.positions(tester), displaced);
      expect(pieces.widths(tester), everyElement(closeTo(100, 1e-6)));
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pumpAndSettle();
      expect(pieces.positions(tester), displaced);
      expect(pulseScale(), 1);
      expect(
        _clipRadius(tester, find.byType(SuccessPulse)),
        closeTo(radiusAtFirstFrame, 1e-6),
      );
      expect(radiusAtFirstFrame, greaterThan(0));
      expect(pieces.positions(tester)[0], Offset.zero);
    },
  );

  testWidgets('no piece repeats on its own after finishing @RED-04-S15', (
    tester,
  ) async {
    final pieces = _Pieces();
    addTearDown(pieces.firing.dispose);
    addTearDown(pieces.repaint.dispose);
    await _mount(tester, pieces.widget);

    pieces.firing.value = 1;
    await tester.pump();
    await tester.pump(_ms(100));
    // If any repeated, this would never finish.
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    final still = pieces.positions(tester);
    final widths = pieces.widths(tester);
    expect(_opacity(tester, find.byType(FadeIn).first), 1);

    await tester.pump(const Duration(seconds: 5));
    expect(pieces.positions(tester), still);
    expect(pieces.widths(tester), widths);
    expect(tester.binding.hasScheduledFrame, isFalse);

    // Rebuilding without changing the trigger does not move them again either.
    pieces.repaint.value++;
    await tester.pump();
    await tester.pump(_ms(1000));
    expect(pieces.positions(tester), still);
    expect(pieces.widths(tester), widths);
    expect(_opacity(tester, find.byType(FadeIn).first), 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  test(
    'the curves are easeOut, easeOutCubic, easeOutQuart and easeOutBack @RED-04-ASM-02',
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
    'leaving in the middle of an animation leaves no pending timer @RED-04-ASM-03',
    (tester) async {
      final pieces = _Pieces();
      addTearDown(pieces.firing.dispose);
      addTearDown(pieces.repaint.dispose);
      await _mount(tester, pieces.widget);

      pieces.firing.value = 1;
      await tester.pump();
      await tester.pump(_ms(100));
      final finger = await tester.startGesture(
        tester.getCenter(find.byKey(_Pieces.pressKey)),
      );
      await tester.pump(_ms(20));

      // It leaves with everything half-way: the appearance delay, the shake, the heartbeat and the pulse.
      await tester.pumpWidget(const SizedBox.shrink());
      await finger.cancel();
      await tester.pump(const Duration(seconds: 5));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets(
    'a block that enters is already in the screen reader tree @RED-04-ASM-11',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _mount(
        tester,
        FadeIn(
          delay: const Duration(milliseconds: 500),
          child: Semantics(
            label: 'Bloque de prueba',
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      );

      // Transparent and not yet started, but the screen reader already sees it.
      expect(_opacity(tester, find.byType(FadeIn)), 0);
      expect(find.bySemanticsLabel('Bloque de prueba'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Bloque de prueba')).label,
        'Bloque de prueba',
      );

      await tester.pump(_ms(300));
      expect(_opacity(tester, find.byType(FadeIn)), 0);
      expect(find.bySemanticsLabel('Bloque de prueba'), findsOneWidget);

      await tester.pump(_ms(400));
      expect(_opacity(tester, find.byType(FadeIn)), greaterThan(0));
      expect(find.bySemanticsLabel('Bloque de prueba'), findsOneWidget);
      semantics.dispose();
    },
  );
}
