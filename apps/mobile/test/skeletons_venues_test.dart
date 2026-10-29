import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/card_frame.dart';
import 'package:clubnahuelmosse/common/selectable_chip.dart';
import 'package:clubnahuelmosse/features/venues/presentation/space_card_skeleton.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venue_card.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venue_card_skeleton.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venue_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/held_api.dart';
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

const _moron = '00000000-0000-7000-8000-000000000001';

/// Mounts the app in 393x852 on [route] with every request held.
Future<HeldApi> _mount(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await cargarFuentes();
  final held = HeldApi(rutasDeSedes());
  await tester.pumpWidget(
    App(
      api: held.client,
      session: SesionFalsa(perfilUsuario),
      appearance: Appearance.inMemory(dark: true),
      initialLocation: route,
    ),
  );
  await tester.pump();
  await tester.pump();
  return held;
}

Rect _rect(WidgetTester tester, Finder finder) {
  final box = finder.evaluate().first.renderObject! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 2));
}

void main() {
  testWidgets(
    'la sede carga con la forma de su portada, filtros y tarjetas de cancha en 393 por 852, bordes a 1 px y alto a 8 px @VIS-03-S1 @assumption:VIS-03-ASM-01',
    (tester) async {
      final held = await _mount(tester, '/sedes/$_moron');
      expect(find.byType(VenueSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final blocks = skeletonRects(tester);
      final cover = blocks.first;
      final chip = blocks[2];
      final card = _rect(tester, find.byType(CardFrame));
      final cards = find.byType(CardFrame).evaluate().length;

      held.release();
      await tester.pumpAndSettle();
      expect(find.byType(VenueSkeleton), findsNothing);
      expectSameBox(
        cover,
        _rect(tester, find.byType(Image).first),
        reason: 'cover',
      );
      expectSameBox(
        chip,
        _rect(tester, find.byType(SelectableChip)),
        reason: 'chip',
        height: 8,
      );
      expectSameBox(
        card,
        _rect(tester, find.byType(CardFrame)),
        reason: 'card',
      );
      expect(cards, find.byType(CardFrame).evaluate().length);
      await _drain(tester);
    },
  );

  testWidgets(
    'la sede al filtrar carga tarjetas de cancha bajo los filtros @VIS-03-S1',
    (tester) async {
      final held = await _mount(tester, '/sedes/$_moron');
      held.release();
      await tester.pumpAndSettle();
      held.holdAgain();
      await tester.tap(find.byType(SelectableChip).first);
      await tester.pump();
      await tester.pump();
      expect(find.byType(SpaceCardSkeleton), findsWidgets);
      expect(find.byType(SelectableChip), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final card = _rect(tester, find.byType(CardFrame));

      held.release();
      await tester.pumpAndSettle();
      expect(find.byType(SpaceCardSkeleton), findsNothing);
      expectSameBox(
        card,
        _rect(tester, find.byType(CardFrame)),
        reason: 'card',
      );
      await _drain(tester);
    },
  );

  testWidgets('Sedes carga con la forma de la tarjeta de sede @VIS-03-S1', (
    tester,
  ) async {
    final held = await _mount(tester, '/sedes');
    expect(find.byType(VenueCardSkeleton), findsWidgets);
    expect(find.text('Sedes'), findsWidgets);
    final card = _rect(tester, find.byType(VenueCardSkeleton));

    held.release();
    await tester.pumpAndSettle();
    expect(find.byType(VenueCardSkeleton), findsNothing);
    expectSameBox(card, _rect(tester, find.byType(VenueCard)), reason: 'card');
    await _drain(tester);
  });

  testWidgets(
    'los skeletons de sedes conservan lo de la card anterior: brillan, se detienen con reducir movimiento y dicen Cargando una vez @assumption:VIS-03-ASM-05',
    (tester) async {
      final semantica = tester.ensureSemantics();
      for (final route in ['/sedes', '/sedes/$_moron']) {
        await _mount(tester, route);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.hasRunningAnimations, isTrue, reason: route);
        expect(
          find.bySemanticsLabel('Cargando'),
          findsOneWidget,
          reason: route,
        );
        await _drain(tester);
      }
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _mount(tester, '/sedes');
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
      await _drain(tester);
      semantica.dispose();
    },
  );
}
