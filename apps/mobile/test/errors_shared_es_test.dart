import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/common/error_dialog.dart';
import 'package:clubnahuelmosse/features/session/presentation/access_denied_screen.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/mount.dart';

/// The app in Spanish on [routes].
Widget _app(GoRouter routes) => MaterialApp.router(
  routerConfig: routes,
  theme: darkTheme,
  localeListResolutionCallback: resolveLanguage,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
);

void main() {
  setUpAll(loadFonts);

  testWidgets(
    'a 403 from the API shows «Acceso denegado» and leads to «Mis reservas»',
    (tester) async {
      final routes = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    showNetworkError(context, const ServerError(403)),
                child: const Text('ABRIR'),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/access-denied',
            builder: (context, _) =>
                AccessDeniedScreen(session: FakeSession(userProfile)),
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, _) => const Scaffold(body: Text('Mis reservas')),
          ),
        ],
      );
      addTearDown(routes.dispose);
      await tester.pumpWidget(_app(routes));
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      expect(find.text('Acceso denegado'), findsOneWidget);
      expect(find.text('Error del servidor'), findsNothing);
      await tester.tap(find.text('IR A MIS RESERVAS'));
      await tester.pumpAndSettle();
      expect(find.text('Mis reservas'), findsOneWidget);
      expect(find.text('Acceso denegado'), findsNothing);
    },
  );

  testWidgets('a 403 returns its own outcome', (tester) async {
    ErrorOutcome? outcome;
    final routes = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async => outcome = await handleNetworkError(
                context,
                const ServerError(403),
              ),
              child: const Text('ABRIR'),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/access-denied',
          builder: (context, _) =>
              AccessDeniedScreen(session: FakeSession(userProfile)),
        ),
      ],
    );
    addTearDown(routes.dispose);
    await tester.pumpWidget(_app(routes));
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();

    expect(outcome, ErrorOutcome.accessDenied);
  });
}
