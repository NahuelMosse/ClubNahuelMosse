import 'dart:async';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/common/loading_screen.dart';
import 'package:clubnahuelmosse/common/skeleton.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/mount.dart';

/// An API that never answers: the screen stays loading.
ApiClient _hungApi() => ApiClient(
  'http://api.falsa',
  client: MockClient((_) => Completer<http.Response>().future),
);

Future<void> _loading(
  WidgetTester tester, {
  required String start,
  bool admin = false,
  bool dark = true,
}) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    App(
      api: _hungApi(),
      session: FakeSession(admin ? adminProfile : userProfile),
      appearance: Appearance.inMemory(dark: dark),
      initialLocation: start,
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _shape(
  WidgetTester tester,
  SkeletonShape shape, {
  ThemeData? theme,
}) => tester.pumpWidget(
  MaterialApp(
    theme: theme ?? darkTheme,
    home: Scaffold(body: SkeletonList(shape: shape)),
  ),
);

void main() {
  group('loading skeletons', () {
    for (final (route, admin) in [
      ('/venues', false),
      ('/bookings', false),
      ('/home', false),
      ('/admin/venues', true),
    ]) {
      testWidgets(
        'every loading screen shows skeletons shaped like its content, not a spinner @VIS-02-S1 @assumption:VIS-02-ASM-02 $route',
        (tester) async {
          await _loading(tester, start: route, admin: admin);
          expect(find.byType(Skeleton), findsWidgets);
          expect(find.byType(CircularProgressIndicator), findsNothing);
        },
      );
    }

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

    testWidgets(
      'button spinners and the startup wait stay the same @assumption:VIS-02-ASM-01',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: darkTheme,
            home: Scaffold(
              body: PrimaryButton(label: 'ENVIAR', onTap: () {}, loading: true),
            ),
          ),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pumpWidget(
          MaterialApp(theme: darkTheme, home: const LoadingScreen()),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
