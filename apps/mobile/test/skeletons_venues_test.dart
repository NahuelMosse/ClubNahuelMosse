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

import 'support/held_api.dart';
import 'support/mount.dart';
import 'support/user.dart';

const _moron = '00000000-0000-7000-8000-000000000001';

/// Mounts the app in 393x852 on [route] with every request held.
Future<HeldApi> _mount(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await loadFonts();
  final held = HeldApi(venueRoutes());
  await tester.pumpWidget(
    App(
      api: held.client,
      session: FakeSession(userProfile),
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
    'the venue loads shaped like its cover, filters and court cards at 393 by 852, edges within 1 px and height within 8 px @VIS-03-S1 @assumption:VIS-03-ASM-01',
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
    'the venue on filtering loads court cards under the filters @VIS-03-S1',
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

  testWidgets('«Sedes» loads shaped like the venue card @VIS-03-S1', (
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
    'the venue skeletons keep what the previous card set: they shimmer, stop with reduce motion and say «Cargando» once @assumption:VIS-03-ASM-05',
    (tester) async {
      final semantics = tester.ensureSemantics();
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
      semantics.dispose();
    },
  );
}
