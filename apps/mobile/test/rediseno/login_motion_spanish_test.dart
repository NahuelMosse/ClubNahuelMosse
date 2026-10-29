import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/common/text_field.dart';
import 'package:clubnahuelmosse/common/logo_mark.dart';
import 'package:clubnahuelmosse/common/motion.dart';
import 'package:clubnahuelmosse/common/pending_booking.dart';
import 'package:clubnahuelmosse/common/snackbar.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../soporte/montar.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'el login entra escalonado: isotipo, formulario, botón y pie @RED-04-S6',
    (tester) async {
      await _montarLibre(tester, _login());
      Iterable<Duration> retrasos(Finder f) =>
          _aparecedores(tester, f).map((a) => a.delay);

      expect(
        _aparecedores(
          tester,
          find.byType(LogoMark),
        ).any((a) => a.turn != 0 && a.fromY < 0),
        isTrue,
        reason: 'el isotipo cae y gira',
      );
      expect(retrasos(find.byType(FormTextField).first), contains(_ms(460)));
      expect(retrasos(find.text('INICIAR SESIÓN')), contains(_ms(540)));
      expect(retrasos(find.text('¿No tenés cuenta?')), contains(_ms(620)));

      final form = _aparecerQue(
        find.byType(FormTextField).first,
        (a) => a.delay == _ms(460),
      ).first;
      expect(_opacidad(tester, form), 0);
      await tester.pump(_ms(400));
      expect(_opacidad(tester, form), 0);
      await tester.pump(_ms(300));
      expect(_opacidad(tester, form), allOf(greaterThan(0), lessThan(1)));
      await tester.pumpAndSettle();
      expect(_opacidad(tester, form), 1);
    },
  );

  testWidgets(
    'el aviso de credenciales inválidas tiembla cada vez que aparece y el mismo error no vuelve a hacer temblar el campo @RED-04-ASM-10',
    (tester) async {
      final credenciales = CredencialesFalsas(
        alIngresar: (_, _) async => throw const InvalidCredentials(),
      );
      await _montarLibre(tester, _login(credenciales: credenciales));
      await tester.pumpAndSettle();
      final campo = find.byType(TextField).first;

      // Reenviar vacío con el mismo error: tiembla la primera vez y no la segunda.
      await tester.tap(find.text('INICIAR SESIÓN'));
      await _arrancar(tester);
      expect(find.text('Completá tu correo electrónico'), findsOneWidget);
      _tiembla(await _recorrido(tester, campo), motivo: 'el campo, 1.ª vez');
      await tester.tap(find.text('INICIAR SESIÓN'));
      await _arrancar(tester);
      expect(find.text('Completá tu correo electrónico'), findsOneWidget);
      _noTiembla(await _recorrido(tester, campo), motivo: 'el mismo error');

      // Con los datos completos y mal, el aviso tiembla al aparecer, cada vez.
      await tester.enterText(find.byType(TextField).first, 'nahuel@correo.com');
      await tester.enterText(find.byType(TextField).last, 'Mala1234');
      for (var vez = 1; vez <= 2; vez++) {
        await tester.tap(find.text('INICIAR SESIÓN'));
        await _hastaQue(
          tester,
          () => find.text(invalidCredentialsMessage).evaluate().isNotEmpty,
        );
        await _arrancar(tester);
        _tiembla(
          await _recorrido(tester, find.byType(ErrorSnackbar)),
          motivo: 'el aviso, $vez.ª vez',
        );
        await tester.tap(find.byTooltip('Cerrar aviso'));
        await tester.pumpAndSettle();
        expect(find.text(invalidCredentialsMessage), findsNothing);
      }
      expect(credenciales.intentos, hasLength(2));
    },
  );
}

Duration _ms(int n) => Duration(milliseconds: n);

/// Lo que desplaza el temblor a los 60, 120, 180, 240, 300 y 360 ms.
const _temblor = [-9.0, 9.0, -6.0, 6.0, -3.0, 0.0];

/// La pantalla con el tema y el idioma de la app, sin esperar a que termine ninguna animación.
Future<void> _montarLibre(WidgetTester tester, Widget pantalla) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: darkTheme,
      localeListResolutionCallback: resolveLanguage,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: pantalla,
    ),
  );
}

/// Pasa cuadros sin avanzar el reloj, para que arranque lo que se disparó.
Future<void> _arrancar(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump();
  }
}

/// Pasa cuadros sin avanzar el reloj hasta que se cumple [condicion].
Future<void> _hastaQue(WidgetTester tester, bool Function() condicion) async {
  for (var i = 0; i < 20 && !condicion(); i++) {
    await tester.pump();
  }
  expect(condicion(), isTrue);
}

/// Los `FadeIn` que envuelven a [f], del más cercano al más lejano.
List<FadeIn> _aparecedores(WidgetTester tester, Finder f) => tester
    .widgetList<FadeIn>(find.ancestor(of: f, matching: find.byType(FadeIn)))
    .toList();

/// El `FadeIn` que envuelve a [f] y cumple [cumple].
Finder _aparecerQue(Finder f, bool Function(FadeIn) cumple) => find.ancestor(
  of: f,
  matching: find.byWidgetPredicate((w) => w is FadeIn && cumple(w)),
);

Widget _login({CredencialesFalsas? credenciales}) => LoginScreen(
  session: Session(
    repository: SessionRepository(
      credentials: credenciales ?? CredencialesFalsas(),
      api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
    ),
  ),
  pending: PendingBooking(),
);

double _opacidad(WidgetTester tester, Finder aparecer) => tester
    .widget<FadeTransition>(
      find
          .descendant(of: aparecer, matching: find.byType(FadeTransition))
          .first,
    )
    .opacity
    .value;

void _tiembla(List<double> recorrido, {String? motivo}) {
  expect(recorrido, hasLength(_temblor.length));
  for (var i = 0; i < _temblor.length; i++) {
    expect(
      recorrido[i],
      closeTo(_temblor[i], 0.01),
      reason: '$motivo a los ${60 * (i + 1)} ms',
    );
  }
}

void _noTiembla(List<double> recorrido, {String? motivo}) {
  expect(recorrido, everyElement(closeTo(0, 0.01)), reason: motivo);
}

/// Cuánto se corrió [f] a los 60, 120, 180, 240, 300 y 360 ms respecto de su reposo.
Future<List<double>> _recorrido(WidgetTester tester, Finder f) async {
  final posiciones = <double>[];
  for (var t = 0; t < 360; t += 60) {
    await tester.pump(_ms(60));
    posiciones.add(tester.getTopLeft(f).dx);
  }
  await tester.pumpAndSettle();
  final reposo = tester.getTopLeft(f).dx;
  return [for (final x in posiciones) x - reposo];
}
