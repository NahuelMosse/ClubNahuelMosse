import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/common/error_dialog.dart';
import 'package:clubnahuelmosse/features/session/presentation/access_denied_screen.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'soporte/montar.dart';

/// La app en castellano sobre [rutas].
Widget _app(GoRouter rutas) => MaterialApp.router(
  routerConfig: rutas,
  theme: darkTheme,
  localeListResolutionCallback: resolveLanguage,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
);

void main() {
  setUpAll(cargarFuentes);

  testWidgets(
    'un 403 de la API muestra «Acceso denegado» y lleva a Mis reservas',
    (tester) async {
      final rutas = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    showNetworkError(context, const ErrorDelServidor(403)),
                child: const Text('ABRIR'),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/acceso-denegado',
            builder: (context, _) =>
                AccessDeniedScreen(session: SesionFalsa(perfilUsuario)),
          ),
          GoRoute(
            path: '/reservas',
            builder: (context, _) => const Scaffold(body: Text('Mis reservas')),
          ),
        ],
      );
      addTearDown(rutas.dispose);
      await tester.pumpWidget(_app(rutas));
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

  testWidgets('un 403 devuelve su propio resultado', (tester) async {
    ErrorOutcome? resultado;
    final rutas = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async => resultado = await handleNetworkError(
                context,
                const ErrorDelServidor(403),
              ),
              child: const Text('ABRIR'),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/acceso-denegado',
          builder: (context, _) =>
              AccessDeniedScreen(session: SesionFalsa(perfilUsuario)),
        ),
      ],
    );
    addTearDown(rutas.dispose);
    await tester.pumpWidget(_app(rutas));
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();

    expect(resultado, ErrorOutcome.accessDenied);
  });
}
