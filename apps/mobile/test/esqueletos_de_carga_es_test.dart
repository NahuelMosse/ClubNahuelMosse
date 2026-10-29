import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/common/skeleton.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta [forma] con los delegados de traducción de la app, en castellano.
Future<void> _forma(
  WidgetTester tester,
  SkeletonShape forma, {
  ThemeData? tema,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tema ?? darkTheme,
    localeListResolutionCallback: resolveLanguage,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: SkeletonList(shape: forma)),
  ),
);

void main() {
  group('esqueletos de carga', () {
    for (final forma in SkeletonShape.values) {
      for (final tema in [darkTheme, lightTheme]) {
        testWidgets(
          'cada pantalla que carga muestra skeletons con la forma de su contenido y no un spinner @VIS-02-S1 forma ${forma.name} ${tema.brightness.name}',
          (tester) async {
            await _forma(tester, forma, tema: tema);
            expect(find.byType(Skeleton), findsWidgets);
            expect(find.byType(CircularProgressIndicator), findsNothing);
            final bloque = tester.widget<Skeleton>(find.byType(Skeleton).first);
            expect(bloque.height, greaterThan(0));
          },
        );
      }
    }

    testWidgets(
      'el brillo se detiene con reducir movimiento y el lector anuncia Cargando una vez @VIS-02-S2',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await _forma(tester, SkeletonShape.booking);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.hasRunningAnimations, isTrue);
        expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('.+')), findsOneWidget);

        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await _forma(tester, SkeletonShape.notice);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.hasRunningAnimations, isFalse);
        expect(find.byType(Skeleton), findsWidgets);
        expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
        semantica.dispose();
      },
    );
  });
}
