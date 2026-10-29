import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'package:clubnahuelmosse/common/logo_mark.dart';
import 'package:clubnahuelmosse/common/pending_booking.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../soporte/montar.dart';

void main() {
  group('login', () {
    testWidgets('la marca del login lleva el isotipo decorativo @RED-03-S6', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final session = Session(
        repository: SessionRepository(
          credentials: CredencialesFalsas(),
          api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
        ),
      );
      final rutas = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                LoginScreen(session: session, pending: PendingBooking()),
          ),
        ],
      );
      addTearDown(rutas.dispose);
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: darkTheme,
          localeListResolutionCallback: resolveLanguage,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: rutas,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LogoMark), findsOneWidget);
      expect(tester.widget<LogoMark>(find.byType(LogoMark)).decorative, isTrue);
      expect(
        tester.getTopLeft(find.byType(LogoMark)).dy,
        lessThan(tester.getTopLeft(find.text('BIENVENIDO A')).dy),
      );
      expect(find.bySemanticsLabel('Club Nahuel Mosse'), findsOneWidget);
      semantica.dispose();
    });
  });
}
