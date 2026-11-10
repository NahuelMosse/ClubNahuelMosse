import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/common/skeleton.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mounts [shape] with the app's translation delegates, in Spanish.
Future<void> _shape(
  WidgetTester tester,
  SkeletonShape shape, {
  ThemeData? theme,
}) => tester.pumpWidget(
  MaterialApp(
    theme: theme ?? darkTheme,
    localeListResolutionCallback: resolveLanguage,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: SkeletonList(shape: shape)),
  ),
);

void main() {
  group('loading skeletons', () {
    for (final shape in SkeletonShape.values) {
      for (final theme in [darkTheme, lightTheme]) {
        testWidgets(
          'every loading screen shows skeletons shaped like its content, not a spinner @VIS-02-S1 shape ${shape.name} ${theme.brightness.name}',
          (tester) async {
            await _shape(tester, shape, theme: theme);
            expect(find.byType(Skeleton), findsWidgets);
            expect(find.byType(CircularProgressIndicator), findsNothing);
            final block = tester.widget<Skeleton>(find.byType(Skeleton).first);
            expect(block.height, greaterThan(0));
          },
        );
      }
    }

    testWidgets(
      'the shimmer stops with reduced motion and the screen reader announces «Cargando» once @VIS-02-S2',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _shape(tester, SkeletonShape.booking);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.hasRunningAnimations, isTrue);
        expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('.+')), findsOneWidget);

        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await _shape(tester, SkeletonShape.notice);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.hasRunningAnimations, isFalse);
        expect(find.byType(Skeleton), findsWidgets);
        expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
        semantics.dispose();
      },
    );
  });
}
