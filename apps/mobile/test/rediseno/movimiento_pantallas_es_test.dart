import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';

import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/club_timezone.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_greeting.dart';
import 'package:clubnahuelmosse/common/text_field.dart';
import 'package:clubnahuelmosse/common/member_profile.dart';
import 'package:clubnahuelmosse/common/logo_mark.dart';
import 'package:clubnahuelmosse/common/marker.dart';
import 'package:clubnahuelmosse/common/motion.dart';
import 'package:clubnahuelmosse/common/pending_booking.dart';
import 'package:clubnahuelmosse/common/snackbar.dart';
import 'package:clubnahuelmosse/common/sport_tile.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soporte/montar.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/features/users/presentation/my_profile_screen.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_done_screen.dart';

Duration _ms(int n) => Duration(milliseconds: n);

final _cero = closeTo(0, 1e-6);
final _uno = closeTo(1, 1e-6);

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

double _opacidad(WidgetTester tester, Finder aparecer) => tester
    .widget<FadeTransition>(
      find
          .descendant(of: aparecer, matching: find.byType(FadeTransition))
          .first,
    )
    .opacity
    .value;

bool _todasEnSuFinal(WidgetTester tester) {
  final cuantas = find.byType(FadeIn).evaluate().length;
  return cuantas > 0 &&
      [
        for (var i = 0; i < cuantas; i++)
          _opacidad(tester, find.byType(FadeIn).at(i)),
      ].every((o) => o == 1);
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

/// El radio del recorte que revela el ícono de [dentro].
double _radioDeRecorte(WidgetTester tester, Finder dentro) {
  final recortes = find.descendant(
    of: dentro,
    matching: find.byWidgetPredicate((w) => w is ClipOval || w is ClipPath),
  );
  expect(recortes, findsWidgets);
  final objeto = tester.renderObject(recortes.first);
  if (objeto is RenderClipPath) {
    final recortador = objeto.clipper;
    if (recortador == null) fail('el recorte no tiene un recortador propio');
    return recortador.getClip(objeto.size).getBounds().width / 2;
  }
  if (objeto is RenderClipOval) {
    final recortador = objeto.clipper;
    if (recortador == null) fail('el recorte no tiene un recortador propio');
    return recortador.getClip(objeto.size).width / 2;
  }
  fail('el recorte no es un ClipPath ni un ClipOval');
}

double _escalaDelPulso(WidgetTester tester) => tester
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

// ---- las apis ----

// ---- las pantallas ----

Widget _login({CredencialesFalsas? credenciales}) => LoginScreen(
  session: Session(
    repository: SessionRepository(
      credentials: credenciales ?? CredencialesFalsas(),
      api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
    ),
  ),
  pending: PendingBooking(),
);

void main() {
  setUpAll(cargarFuentes);

  // ---- T3: la lista cambia en su lugar ----

  // ---- T4: las entradas, los errores y los éxitos ----

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

      final formulario = _aparecerQue(
        find.byType(FormTextField).first,
        (a) => a.delay == _ms(460),
      ).first;
      expect(_opacidad(tester, formulario), 0);
      await tester.pump(_ms(400));
      expect(_opacidad(tester, formulario), 0);
      await tester.pump(_ms(300));
      expect(_opacidad(tester, formulario), allOf(greaterThan(0), lessThan(1)));
      await tester.pumpAndSettle();
      expect(_opacidad(tester, formulario), 1);
    },
  );

  testWidgets(
    'el inicio entra escalonado: saludo, marcador, próxima reserva y tiles @RED-04-S6',
    (tester) async {
      await _montarLibre(tester, inicioFalso(SesionFalsa(perfilUsuario)));
      await _hastaQue(
        tester,
        () => find.byType(SportTile).evaluate().isNotEmpty,
      );

      expect(
        _aparecedores(tester, find.text(HomeGreeting.forHour(clubNow()))),
        isNotEmpty,
      );
      expect(
        _aparecedores(
          tester,
          find.byType(AppMarker),
        ).any((a) => a.delay == _ms(250) && a.scaleFrom == 0.85),
        isTrue,
        reason: 'el marcador a los 250 ms, creciendo de 0,85 a 1',
      );
      expect(
        _aparecedores(
          tester,
          find.text('TU PRÓXIMA RESERVA'),
        ).any((a) => a.delay == _ms(450) && a.fromY > 0),
        isTrue,
        reason: 'la próxima reserva a los 450 ms, bajando desde abajo',
      );
      expect(_aparecedores(tester, find.text('Buscar cancha')), isNotEmpty);

      final tiles = find.byType(SportTile).evaluate().length;
      expect(tiles, greaterThan(1));
      final retrasos = <Duration>[];
      for (var i = 0; i < tiles; i++) {
        final tile = _aparecedores(tester, find.byType(SportTile).at(i)).first;
        expect(tile.fromX, 120, reason: 'tile $i');
        expect(tile.turn, isNot(0), reason: 'tile $i');
        retrasos.add(tile.delay);
      }
      expect(retrasos.first, greaterThanOrEqualTo(_ms(700)));
      for (var i = 1; i < retrasos.length; i++) {
        expect(retrasos[i], greaterThan(retrasos[i - 1]), reason: 'tile $i');
      }

      // El reloj arrancó con los datos: el marcador espera sus 250 ms.
      final marcador = _aparecerQue(
        find.byType(AppMarker),
        (a) => a.delay == _ms(250),
      ).first;
      expect(_opacidad(tester, marcador), 0);
      await tester.pump(_ms(200));
      expect(_opacidad(tester, marcador), 0);
      await tester.pump(_ms(300));
      expect(_opacidad(tester, marcador), allOf(greaterThan(0), lessThan(1)));
      await tester.pumpAndSettle();
      expect(_opacidad(tester, marcador), 1);
    },
  );

  testWidgets('mi perfil entra escalonado: ficha y tarjetas @RED-04-S6', (
    tester,
  ) async {
    await _montarLibre(
      tester,
      MyProfileScreen(
        session: SesionFalsa(perfilUsuario),
        appearance: Appearance.inMemory(),
      ),
    );
    await _hastaQue(
      tester,
      () => find.byType(MemberProfile).evaluate().isNotEmpty,
    );

    final ficha = _aparecedores(tester, find.byType(MemberProfile));
    expect(
      ficha.any(
        (a) => a.fromY == -24 && a.turn != 0 && a.curve == AppMotion.smooth,
      ),
      isTrue,
      reason: 'la ficha baja 24 girando, con la curva suave',
    );

    final retrasos = <Duration>[];
    for (final titulo in ['DATOS PERSONALES', 'SEGURIDAD', 'APARIENCIA']) {
      final envolventes = _aparecedores(tester, find.text(titulo));
      expect(envolventes, isNotEmpty, reason: titulo);
      retrasos.add(envolventes.first.delay);
    }
    final cierre = _aparecedores(tester, find.text('CERRAR SESIÓN'));
    expect(cierre, isNotEmpty);
    retrasos.add(cierre.first.delay);
    for (var i = 1; i < retrasos.length; i++) {
      expect(retrasos[i], greaterThan(retrasos[i - 1]), reason: 'bloque $i');
    }
    expect(
      ficha.map((a) => a.delay).reduce((a, b) => a < b ? a : b),
      lessThanOrEqualTo(retrasos.first),
    );
  });

  testWidgets(
    'recargar el inicio desde cero no repite la entrada @RED-04-ASM-04',
    (tester) async {
      final datos = ValueNotifier<int>(0);
      addTearDown(datos.dispose);
      final sesion = SesionFalsa(perfilUsuario);
      await _montarLibre(
        tester,
        ValueListenableBuilder<int>(
          valueListenable: datos,
          builder: (context, n, _) => inicioFalso(sesion, conReserva: n.isEven),
        ),
      );
      await _hastaQue(
        tester,
        () => find.byType(SportTile).evaluate().isNotEmpty,
      );
      expect(
        _todasEnSuFinal(tester),
        isFalse,
        reason: 'la primera vez sí entra',
      );
      await tester.pumpAndSettle();
      expect(_todasEnSuFinal(tester), isTrue);

      // Otros datos: la pantalla se vacía y vuelve a leer.
      datos.value = 1;
      await tester.pump();
      expect(find.byType(SportTile), findsNothing);
      await _hastaQue(
        tester,
        () => find.byType(SportTile).evaluate().isNotEmpty,
      );

      // Los bloques nuevos ya están en su final, sin volver a entrar.
      expect(find.byType(FadeIn), findsWidgets);
      expect(_todasEnSuFinal(tester), isTrue);
      expect(find.text('TU PRÓXIMA RESERVA'), findsNothing);
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

  testWidgets(
    '«el tilde se dibuja»: el registro exitoso revela su ícono con la misma pieza @RED-04-ASM-08',
    (tester) async {
      await _montarLibre(tester, const RegistrationDoneScreen());
      final paleta = tester
          .element(find.byType(RegistrationDoneScreen))
          .palette;

      final pulso = tester.widget<SuccessPulse>(find.byType(SuccessPulse));
      expect(pulso.icon, Icons.check_circle_outline_rounded);
      expect(pulso.background, paleta.stateSuccessMuted);
      expect(pulso.ink, paleta.stateSuccessInk);
      expect(_escalaDelPulso(tester), closeTo(0.4, 1e-6));

      // El ícono se revela con un recorte que crece.
      final icono = find.byType(SuccessPulse);
      expect(_radioDeRecorte(tester, icono), _cero);
      await tester.pump(_ms(150));
      expect(_radioDeRecorte(tester, icono), _cero);
      await tester.pump(_ms(250));
      expect(_radioDeRecorte(tester, icono), greaterThan(0));
      await tester.pump(_ms(250));
      final completo = _radioDeRecorte(tester, icono);
      await tester.pumpAndSettle();
      expect(_radioDeRecorte(tester, icono), closeTo(completo, 1e-6));
      expect(_escalaDelPulso(tester), _uno);

      // El título y el texto escalonan como en ResultScreen.
      expect(_aparecedores(tester, find.text('¡Cuenta creada!')), isNotEmpty);
    },
  );

  // ---- T5: diálogos y tarjeta de la cuenta ----

  // ---- T6: las capturas ----
}
