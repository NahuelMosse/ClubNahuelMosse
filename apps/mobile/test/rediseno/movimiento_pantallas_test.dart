import 'dart:async';
import 'dart:convert';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/comun/apariencia.dart';
import 'package:clubnahuelmosse/comun/boton.dart';
import 'package:clubnahuelmosse/comun/campo_texto.dart';
import 'package:clubnahuelmosse/comun/ficha_socio.dart';
import 'package:clubnahuelmosse/comun/isotipo.dart';
import 'package:clubnahuelmosse/comun/linea_del_dia.dart';
import 'package:clubnahuelmosse/comun/marcador.dart';
import 'package:clubnahuelmosse/comun/movimiento.dart';
import 'package:clubnahuelmosse/comun/reserva_pendiente.dart';
import 'package:clubnahuelmosse/comun/resultado.dart';
import 'package:clubnahuelmosse/comun/selector.dart';
import 'package:clubnahuelmosse/comun/snackbar.dart';
import 'package:clubnahuelmosse/comun/tile_deporte.dart';
import 'package:clubnahuelmosse/comun/dialogo_error.dart';
import 'package:clubnahuelmosse/notificaciones/panel_avisos.dart';
import 'package:clubnahuelmosse/reservas/pantalla_reserva_confirmada.dart';
import 'package:clubnahuelmosse/reservas/reservas.dart';
import 'package:clubnahuelmosse/sesion/pantalla_inicio_sesion.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:clubnahuelmosse/sesion/tarjeta_cuenta.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:clubnahuelmosse/tema/tokens.dart';
import 'package:clubnahuelmosse/usuarios/pantalla_mi_perfil.dart';
import 'package:clubnahuelmosse/usuarios/pantalla_registro_exitoso.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../mis_reservas_test.dart' show reservaJson;
import '../notificaciones_test.dart'
    show ApiFalsa, ahoraClub, centroDe, recordatorio;
import '../soporte/admin.dart';
import '../soporte/montar.dart';
import '../soporte/usuario.dart';

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
      theme: temaOscuro,
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: pantalla,
    ),
  );
}

Future<void> _desmontar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void _reducirMovimiento(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
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

/// Los `Aparecer` que envuelven a [f], del más cercano al más lejano.
List<Aparecer> _aparecedores(WidgetTester tester, Finder f) => tester
    .widgetList<Aparecer>(find.ancestor(of: f, matching: find.byType(Aparecer)))
    .toList();

/// El `Aparecer` que envuelve a [f] y cumple [cumple].
Finder _aparecerQue(Finder f, bool Function(Aparecer) cumple) => find.ancestor(
  of: f,
  matching: find.byWidgetPredicate((w) => w is Aparecer && cumple(w)),
);

double _opacidad(WidgetTester tester, Finder aparecer) => tester
    .widget<FadeTransition>(
      find
          .descendant(of: aparecer, matching: find.byType(FadeTransition))
          .first,
    )
    .opacity
    .value;

/// Cuánto se ve [f]: el producto de todas las opacidades que lo envuelven.
double _visibilidad(WidgetTester tester, Finder f) {
  if (f.evaluate().isEmpty) return 0;
  var visible = 1.0;
  for (final fundido in tester.widgetList<FadeTransition>(
    find.ancestor(of: f, matching: find.byType(FadeTransition)),
  )) {
    visible *= fundido.opacity.value;
  }
  return visible;
}

bool _todasEnSuFinal(WidgetTester tester) {
  final cuantas = find.byType(Aparecer).evaluate().length;
  return cuantas > 0 &&
      [
        for (var i = 0; i < cuantas; i++)
          _opacidad(tester, find.byType(Aparecer).at(i)),
      ].every((o) => o == 1);
}

/// El ancho que se ve de [f], con la escala de lo que lo envuelve.
double _ancho(WidgetTester tester, Finder f) =>
    tester.getBottomRight(f).dx - tester.getTopLeft(f).dx;

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

Iterable<Temblor> _temblores(WidgetTester tester, Finder f) => [
  ...tester.widgetList<Temblor>(
    find.descendant(of: f, matching: find.byType(Temblor)),
  ),
  ...tester.widgetList<Temblor>(
    find.ancestor(of: f, matching: find.byType(Temblor)),
  ),
];

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
            of: find.byType(PulsoDeExito),
            matching: find.byType(ScaleTransition),
          )
          .first,
    )
    .scale
    .value;

/// El `AnimatedSwitcher` de 150 ms que cambia sólo la lista.
Finder get _fundidoDeLaLista => find.byWidgetPredicate(
  (w) =>
      w is AnimatedSwitcher && w.duration == const Duration(milliseconds: 150),
);

Future<void> _tocarSinEsperar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
}

// ---- las apis ----

ClienteApi _apiMisReservas(Completer<void>? esperaHistorial) {
  final rutas = rutasDeSedes();
  return ClienteApi(
    'http://api.falsa',
    cliente: MockClient((pedido) async {
      final historial = pedido.url.queryParameters['cuando'] == 'historial';
      if (pedido.url.path == '/reservas' && historial) {
        await esperaHistorial?.future;
      }
      final (codigo, cuerpo) = pedido.url.path == '/reservas'
          ? (
              200,
              '{"reservas": [${historial ? reservaJson(id: '00000000-0000-7000-8000-000000000002', estado: 'completada') : reservaJson()}]}',
            )
          : rutas['${pedido.method} ${pedido.url.path}'] ?? (404, '{}');
      return http.Response.bytes(
        utf8.encode(cuerpo),
        codigo,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );
}

ClienteApi _apiSede(Completer<void>? espera) {
  final rutas = rutasDeSedes();
  return ClienteApi(
    'http://api.falsa',
    cliente: MockClient((pedido) async {
      final filtrado =
          pedido.url.path == '/espacios' &&
          pedido.url.queryParameters.containsKey('deporte');
      if (filtrado) await espera?.future;
      final (codigo, cuerpo) = filtrado
          ? (200, '{"espacios": [$espacioF5Json]}')
          : rutas['${pedido.method} ${pedido.url.path}'] ?? (404, '{}');
      return http.Response.bytes(
        utf8.encode(cuerpo),
        codigo,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );
}

// ---- las pantallas ----

Widget _login({CredencialesFalsas? credenciales}) => PantallaInicioSesion(
  sesion: Sesion(
    credenciales: credenciales ?? CredencialesFalsas(),
    api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
  ),
  pendiente: ReservaPendiente(),
);

Widget _resultado(TonoResultado tono) => PantallaResultado(
  icono: Icons.check_circle_outline_rounded,
  tono: tono,
  titulo: 'Contraseña actualizada',
  texto: 'Ya podés iniciar sesión con tu contraseña nueva.',
  principal: 'VOLVER AL INICIO',
  alTocarPrincipal: () {},
  secundaria: 'Ver más tarde',
  alTocarSecundaria: () {},
);

Reserva _reservaConfirmada() {
  final reserva = Reserva.desdeJson(jsonDecode(reservaJson()));
  if (reserva == null) fail('la reserva de prueba no se lee');
  return reserva;
}

/// Un botón que abre lo que haga [abrir].
class _Anfitrion extends StatelessWidget {
  const _Anfitrion({required this.abrir});

  final void Function(BuildContext context) abrir;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => abrir(context),
          child: const Text('ABRIR'),
        ),
      ),
    ),
  );
}

Widget _cancelacion() => _Anfitrion(
  abrir: (context) =>
      unawaited(confirmarCancelacion(context, 'Fútbol 5 · Sede Morón')),
);

void main() {
  setUpAll(cargarFuentes);

  // ---- T3: la lista cambia en su lugar ----

  testWidgets(
    'cambiar a Historial cambia sólo la lista con un fundido de 150 ms @RED-04-S5',
    (tester) async {
      final espera = Completer<void>();
      await montarUsuario(
        tester,
        api: _apiMisReservas(espera),
        inicio: '/reservas',
      );
      final titulo = tester.element(find.text('Mis reservas'));
      final selector = tester.element(find.text('Historial'));
      final lista = _fundidoDeLaLista;

      // El fundido es de la lista: el título y el selector quedan afuera.
      expect(lista, findsOneWidget);
      expect(
        find.ancestor(of: find.text('Mis reservas'), matching: lista),
        findsNothing,
      );
      expect(
        find.ancestor(of: find.text('Historial'), matching: lista),
        findsNothing,
      );
      expect(
        find.descendant(of: lista, matching: find.text('ACTIVA')),
        findsOneWidget,
      );

      await tester.tap(find.text('Historial'));
      await _arrancar(tester);
      await tester.pump(_ms(200));
      expect(tester.element(find.text('Mis reservas')), same(titulo));
      expect(tester.element(find.text('Historial')), same(selector));
      expect(
        find.descendant(
          of: lista,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      espera.complete();
      await _arrancar(tester);
      await tester.pump(_ms(75));
      final nueva = find.text('COMPLETADA');
      expect(find.descendant(of: lista, matching: nueva), findsOneWidget);
      expect(_visibilidad(tester, nueva), allOf(greaterThan(0), lessThan(1)));
      await tester.pump(_ms(200));
      expect(_visibilidad(tester, nueva), _uno);
      expect(tester.element(find.text('Mis reservas')), same(titulo));
      expect(tester.element(find.text('Historial')), same(selector));
    },
  );

  testWidgets(
    'filtrar por deporte en una sede cambia sólo la lista con un fundido @RED-04-S5',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final espera = Completer<void>();
      await montarUsuario(tester, api: _apiSede(espera), inicio: '/sedes/00000000-0000-7000-8000-000000000001');
      const tenis = 'Moron_Rivadavia_19850_Tenis_PDL_1';
      const futbol = 'Moron_Rivadavia_19850_Futbol_F5_1';
      final titulo = tester.element(find.text('SEDE MORÓN'));
      final filtro = tester.element(find.text('DEPORTE'));
      final lista = _fundidoDeLaLista;

      expect(lista, findsOneWidget);
      expect(
        find.ancestor(of: find.text('SEDE MORÓN'), matching: lista),
        findsNothing,
      );
      expect(
        find.ancestor(of: find.text('DEPORTE'), matching: lista),
        findsNothing,
      );
      expect(
        find.descendant(of: lista, matching: find.text(tenis)),
        findsOneWidget,
      );

      await _tocarSinEsperar(tester, find.bySemanticsLabel('Deporte Fútbol'));
      await _arrancar(tester);
      await tester.pump(_ms(200));
      expect(tester.element(find.text('SEDE MORÓN')), same(titulo));
      expect(tester.element(find.text('DEPORTE')), same(filtro));
      expect(_fundidoDeLaLista, findsOneWidget);

      espera.complete();
      await _arrancar(tester);
      await tester.pump(_ms(200));
      expect(find.text(tenis), findsNothing);
      expect(
        find.descendant(of: lista, matching: find.text(futbol)),
        findsOneWidget,
      );
      expect(tester.element(find.text('SEDE MORÓN')), same(titulo));
      expect(tester.element(find.text('DEPORTE')), same(filtro));
      semantica.dispose();
    },
  );

  testWidgets(
    'con reducir movimiento la lista cambia en el primer cuadro @RED-04-S14',
    (tester) async {
      _reducirMovimiento(tester);
      await montarUsuario(
        tester,
        api: _apiMisReservas(null),
        inicio: '/reservas',
      );
      expect(find.text('ACTIVA'), findsOneWidget);

      await tester.tap(find.text('Historial'));
      await _arrancar(tester);

      expect(find.text('COMPLETADA'), findsOneWidget);
      expect(find.text('ACTIVA'), findsNothing);
      expect(_visibilidad(tester, find.text('COMPLETADA')), _uno);
    },
  );

  testWidgets(
    'la lista de la otra pestaña no queda a la vista mientras carga @RED-04-ASM-07',
    (tester) async {
      final espera = Completer<void>();
      await montarUsuario(
        tester,
        api: _apiMisReservas(espera),
        inicio: '/reservas',
      );
      expect(find.text('ACTIVA'), findsOneWidget);

      await tester.tap(find.text('Historial'));
      await _arrancar(tester);
      await tester.pump(_ms(200));

      // La lista vieja es de Próximas: con Historial elegido no puede verse.
      expect(find.text('ACTIVA'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('COMPLETADA'), findsNothing);

      espera.complete();
      await _arrancar(tester);
      await tester.pump(_ms(200));
      expect(find.text('COMPLETADA'), findsOneWidget);
      expect(find.text('ACTIVA'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  // ---- T4: las entradas, los errores y los éxitos ----

  testWidgets(
    'el login entra escalonado: isotipo, formulario, botón y pie @RED-04-S6',
    (tester) async {
      await _montarLibre(tester, _login());
      Iterable<Duration> retrasos(Finder f) =>
          _aparecedores(tester, f).map((a) => a.retraso);

      expect(
        _aparecedores(
          tester,
          find.byType(Isotipo),
        ).any((a) => a.giro != 0 && a.desdeY < 0),
        isTrue,
        reason: 'el isotipo cae y gira',
      );
      expect(retrasos(find.byType(CampoTexto).first), contains(_ms(460)));
      expect(retrasos(find.text('INICIAR SESIÓN')), contains(_ms(540)));
      expect(retrasos(find.text('¿No tenés cuenta?')), contains(_ms(620)));

      final formulario = _aparecerQue(
        find.byType(CampoTexto).first,
        (a) => a.retraso == _ms(460),
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
        () => find.byType(TileDeporte).evaluate().isNotEmpty,
      );

      expect(_aparecedores(tester, find.text('BUENOS DÍAS,')), isNotEmpty);
      expect(
        _aparecedores(
          tester,
          find.byType(Marcador),
        ).any((a) => a.retraso == _ms(250) && a.escalaDesde == 0.85),
        isTrue,
        reason: 'el marcador a los 250 ms, creciendo de 0,85 a 1',
      );
      expect(
        _aparecedores(
          tester,
          find.text('TU PRÓXIMA RESERVA'),
        ).any((a) => a.retraso == _ms(450) && a.desdeY > 0),
        isTrue,
        reason: 'la próxima reserva a los 450 ms, bajando desde abajo',
      );
      expect(_aparecedores(tester, find.text('Buscar cancha')), isNotEmpty);

      final tiles = find.byType(TileDeporte).evaluate().length;
      expect(tiles, greaterThan(1));
      final retrasos = <Duration>[];
      for (var i = 0; i < tiles; i++) {
        final tile = _aparecedores(
          tester,
          find.byType(TileDeporte).at(i),
        ).first;
        expect(tile.desdeX, 120, reason: 'tile $i');
        expect(tile.giro, isNot(0), reason: 'tile $i');
        retrasos.add(tile.retraso);
      }
      expect(retrasos.first, greaterThanOrEqualTo(_ms(700)));
      for (var i = 1; i < retrasos.length; i++) {
        expect(retrasos[i], greaterThan(retrasos[i - 1]), reason: 'tile $i');
      }

      // El reloj arrancó con los datos: el marcador espera sus 250 ms.
      final marcador = _aparecerQue(
        find.byType(Marcador),
        (a) => a.retraso == _ms(250),
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
      PantallaMiPerfil(
        sesion: SesionFalsa(perfilUsuario),
        apariencia: Apariencia.enMemoria(),
      ),
    );
    await _hastaQue(
      tester,
      () => find.byType(FichaSocio).evaluate().isNotEmpty,
    );

    final ficha = _aparecedores(tester, find.byType(FichaSocio));
    expect(
      ficha.any(
        (a) => a.desdeY == -24 && a.giro != 0 && a.curva == Movimiento.suave,
      ),
      isTrue,
      reason: 'la ficha baja 24 girando, con la curva suave',
    );

    final retrasos = <Duration>[];
    for (final titulo in ['DATOS PERSONALES', 'SEGURIDAD', 'APARIENCIA']) {
      final envolventes = _aparecedores(tester, find.text(titulo));
      expect(envolventes, isNotEmpty, reason: titulo);
      retrasos.add(envolventes.first.retraso);
    }
    final cierre = _aparecedores(tester, find.text('CERRAR SESIÓN'));
    expect(cierre, isNotEmpty);
    retrasos.add(cierre.first.retraso);
    for (var i = 1; i < retrasos.length; i++) {
      expect(retrasos[i], greaterThan(retrasos[i - 1]), reason: 'bloque $i');
    }
    expect(
      ficha.map((a) => a.retraso).reduce((a, b) => a < b ? a : b),
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
        () => find.byType(TileDeporte).evaluate().isNotEmpty,
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
      expect(find.byType(TileDeporte), findsNothing);
      await _hastaQue(
        tester,
        () => find.byType(TileDeporte).evaluate().isNotEmpty,
      );

      // Los bloques nuevos ya están en su final, sin volver a entrar.
      expect(find.byType(Aparecer), findsWidgets);
      expect(_todasEnSuFinal(tester), isTrue);
      expect(find.text('TU PRÓXIMA RESERVA'), findsNothing);
    },
  );

  testWidgets(
    'un campo de texto que pasa a tener error tiembla una vez @RED-04-S7',
    (tester) async {
      final controlador = TextEditingController();
      addTearDown(controlador.dispose);
      String? error;
      late StateSetter reconstruir;
      await _montarLibre(
        tester,
        Padding(
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, set) {
              reconstruir = set;
              return CampoTexto(
                etiquetaAccesible: 'Correo',
                controlador: controlador,
                error: error,
              );
            },
          ),
        ),
      );
      final campo = find.descendant(
        of: find.byType(CampoTexto),
        matching: find.byType(TextField),
      );
      final reposo = tester.getTopLeft(campo).dx;

      // Sin error no tiembla.
      await tester.pump(_ms(500));
      expect(tester.getTopLeft(campo).dx, reposo);

      reconstruir(() => error = 'Completá tu correo electrónico');
      await _arrancar(tester);
      expect(
        _temblores(
          tester,
          find.byType(CampoTexto),
        ).any((t) => t.disparador == error),
        isTrue,
        reason: 'el disparador es el error',
      );
      _tiembla(await _recorrido(tester, campo), motivo: 'el campo');
      expect(tester.getTopLeft(campo).dx, closeTo(reposo, 0.01));

      // Una sola vez: el mismo error, aunque se reconstruya, no lo repite.
      reconstruir(() => error = 'Completá tu correo electrónico');
      await _arrancar(tester);
      _noTiembla(await _recorrido(tester, campo), motivo: 'el mismo error');
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets('un selector que pasa a tener error tiembla una vez @RED-04-S7', (
    tester,
  ) async {
    String? error;
    late StateSetter reconstruir;
    await _montarLibre(
      tester,
      Padding(
        padding: const EdgeInsets.all(24),
        child: StatefulBuilder(
          builder: (context, set) {
            reconstruir = set;
            return CampoSelector(
              etiqueta: 'DEPORTE',
              etiquetaAccesible: 'Deporte',
              valor: null,
              placeholder: 'Elegí un deporte',
              icono: Icons.expand_more_rounded,
              alTocar: () {},
              error: error,
            );
          },
        ),
      ),
    );
    final selector = find.descendant(
      of: find.byType(CampoSelector),
      matching: find.byType(InkWell),
    );
    final reposo = tester.getTopLeft(selector).dx;

    await tester.pump(_ms(500));
    expect(tester.getTopLeft(selector).dx, reposo);

    reconstruir(() => error = 'Elegí un deporte');
    await _arrancar(tester);
    expect(
      _temblores(
        tester,
        find.byType(CampoSelector),
      ).any((t) => t.disparador == error),
      isTrue,
      reason: 'el disparador es el error',
    );
    _tiembla(await _recorrido(tester, selector), motivo: 'el selector');
    expect(tester.getTopLeft(selector).dx, closeTo(reposo, 0.01));

    reconstruir(() => error = 'Elegí un deporte');
    await _arrancar(tester);
    _noTiembla(await _recorrido(tester, selector), motivo: 'el mismo error');
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets(
    'el aviso de credenciales inválidas tiembla cada vez que aparece y el mismo error no vuelve a hacer temblar el campo @RED-04-ASM-10',
    (tester) async {
      final credenciales = CredencialesFalsas(
        alIngresar: (_, _) async => throw const CredencialesInvalidas(),
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
          () => find.text(mensajeCredencialesInvalidas).evaluate().isNotEmpty,
        );
        await _arrancar(tester);
        _tiembla(
          await _recorrido(tester, find.byType(SnackbarError)),
          motivo: 'el aviso, $vez.ª vez',
        );
        await tester.tap(find.byTooltip('Cerrar aviso'));
        await tester.pumpAndSettle();
        expect(find.text(mensajeCredencialesInvalidas), findsNothing);
      }
      expect(credenciales.intentos, hasLength(2));
    },
  );

  testWidgets(
    'el resultado de éxito anima su círculo y escalona su texto @RED-04-S8',
    (tester) async {
      await _montarLibre(tester, _resultado(TonoResultado.exito));
      final paleta = tester.element(find.byType(PantallaResultado)).paleta;

      final pulso = tester.widget<PulsoDeExito>(find.byType(PulsoDeExito));
      expect(pulso.icono, Icons.check_circle_outline_rounded);
      expect(pulso.fondo, paleta.stateSuccessMuted);
      expect(pulso.tinta, paleta.stateSuccessInk);
      expect(_escalaDelPulso(tester), closeTo(0.4, 1e-6));
      await tester.pump(_ms(550));
      expect(_escalaDelPulso(tester), closeTo(1, 1e-3));

      // Título, texto y acción bajan 14, escalonados.
      for (final (finder, retraso) in [
        (find.text('Contraseña actualizada'), 370),
        (find.text('Ya podés iniciar sesión con tu contraseña nueva.'), 460),
        (find.text('VOLVER AL INICIO'), 550),
      ]) {
        final entrada = _aparecedores(tester, finder);
        expect(
          entrada.any((a) => a.retraso == _ms(retraso) && a.desdeY == 14),
          isTrue,
          reason: 'a los $retraso ms',
        );
      }
      await tester.pumpAndSettle();
      expect(_todasEnSuFinal(tester), isTrue);
    },
  );

  testWidgets(
    'el resultado de aviso y el de peligro también animan su círculo @RED-04-S8',
    (tester) async {
      for (final tono in [TonoResultado.aviso, TonoResultado.peligro]) {
        await _montarLibre(tester, _resultado(tono));
        final paleta = tester.element(find.byType(PantallaResultado)).paleta;
        final (fondo, tinta) = switch (tono) {
          TonoResultado.aviso => (paleta.bgSurfaceRaised, paleta.textSecondary),
          _ => (paleta.stateDangerMuted, paleta.stateDangerInk),
        };

        final pulso = tester.widget<PulsoDeExito>(find.byType(PulsoDeExito));
        expect(pulso.fondo, fondo, reason: '$tono');
        expect(pulso.tinta, tinta, reason: '$tono');
        expect(_escalaDelPulso(tester), closeTo(0.4, 1e-6), reason: '$tono');
        expect(_radioDeRecorte(tester, find.byType(PulsoDeExito)), _cero);
        await tester.pump(_ms(550));
        expect(_escalaDelPulso(tester), closeTo(1, 1e-3), reason: '$tono');
        await tester.pumpAndSettle();
        await _desmontar(tester);
      }
    },
  );

  testWidgets(
    '«el tilde se dibuja»: el registro exitoso revela su ícono con la misma pieza @RED-04-ASM-08',
    (tester) async {
      await _montarLibre(tester, const PantallaRegistroExitoso());
      final paleta = tester
          .element(find.byType(PantallaRegistroExitoso))
          .paleta;

      final pulso = tester.widget<PulsoDeExito>(find.byType(PulsoDeExito));
      expect(pulso.icono, Icons.check_circle_outline_rounded);
      expect(pulso.fondo, paleta.stateSuccessMuted);
      expect(pulso.tinta, paleta.stateSuccessInk);
      expect(_escalaDelPulso(tester), closeTo(0.4, 1e-6));

      // El ícono se revela con un recorte que crece.
      final icono = find.byType(PulsoDeExito);
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

      // El título y el texto escalonan como en PantallaResultado.
      expect(_aparecedores(tester, find.text('¡Cuenta creada!')), isNotEmpty);
    },
  );

  testWidgets('la reserva confirmada festeja una vez @RED-04-S9', (
    tester,
  ) async {
    await _montarLibre(
      tester,
      PantallaReservaConfirmada(reserva: _reservaConfirmada()),
    );
    expect(find.byType(Festejo), findsOneWidget);
    final titulo = find.text('¡Reserva confirmada!');
    final comprobante = find.text('Horario');

    final alPrincipio = _ancho(tester, titulo);
    await tester.pump(_ms(500));
    final aMitad = _ancho(tester, titulo);
    await tester.pump(_ms(300));
    expect(_visibilidad(tester, comprobante), 0, reason: 'antes de los 870 ms');

    // Termina sola: si el festejo se repitiera, esto no terminaría.
    await tester.pumpAndSettle();
    final entero = _ancho(tester, titulo);
    expect(alPrincipio / entero, lessThan(1));
    expect(aMitad / entero, allOf(greaterThan(0.5), lessThan(1)));
    expect(_visibilidad(tester, comprobante), _uno);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pump(const Duration(seconds: 10));
    expect(_ancho(tester, titulo), closeTo(entero, 1e-6));
    expect(_visibilidad(tester, comprobante), _uno);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets(
    'cambiar la duración hace latir la línea del día y elegir una franja la hace crecer @RED-04-S10',
    (tester) async {
      await montarUsuario(
        tester,
        api: apiRutas(rutasDeSedes()),
        inicio: '/sedes/00000000-0000-7000-8000-000000000001/canchas/00000000-0000-7000-8000-000000000009',
      );
      final linea = find.byType(LineaDelDia);
      expect(
        find.ancestor(of: linea, matching: find.byType(Latido)),
        findsOneWidget,
      );
      final base = _ancho(tester, linea);
      double escala() => _ancho(tester, linea) / base;

      await _tocarSinEsperar(tester, find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(escala(), closeTo(1, 1e-3));
      await tester.pump(_ms(200));
      expect(escala(), allOf(greaterThan(1), lessThanOrEqualTo(1.0301)));
      await tester.pump(_ms(50));
      expect(escala(), closeTo(1.03, 3e-3));
      await tester.pump(_ms(250));
      expect(escala(), closeTo(1, 1e-3));
      await tester.pumpAndSettle();
      expect(escala(), closeTo(1, 1e-3));

      // La franja elegida crece de 0,88 a 1.
      final franja = find.text('18:00 – 19:00').first;
      final entera = _ancho(tester, franja);
      await _tocarSinEsperar(tester, franja);
      await tester.pump();
      expect(_ancho(tester, franja) / entera, closeTo(0.88, 0.02));
      await tester.pump(_ms(200));
      expect(_ancho(tester, franja) / entera, greaterThan(0.88));
      await tester.pumpAndSettle();
      expect(_ancho(tester, franja) / entera, closeTo(1, 1e-3));
    },
  );

  testWidgets('el aviso dentro de la app baja desde arriba @RED-04-S12', (
    tester,
  ) async {
    final api = ApiFalsa();
    final sesion = SesionFalsa(perfilUsuario);
    final centro = centroDe(api, sesion);
    await montar(
      tester,
      Stack(
        children: [
          const Scaffold(body: Center(child: Text('la pantalla de abajo'))),
          PanelDeAvisos(
            centro: centro,
            ahora: () => ahoraClub,
            alAbrir: (_) {},
          ),
        ],
      ),
      tema: temaOscuro,
    );
    api
      ..avisos = [recordatorio]
      ..noLeidas = 1;
    await tester.runAsync(centro.cargar);
    await tester.pump();
    await tester.pump();

    final titulo = find.text('NOTIFICACIONES');
    expect(titulo, findsOneWidget);
    expect(
      _aparecedores(
        tester,
        titulo,
      ).any((a) => a.desdeY == -150 && a.curva == Movimiento.rebote),
      isTrue,
      reason: 'baja desde −150 con rebote',
    );
    final arriba = tester.getTopLeft(titulo).dy;
    await tester.pump(_ms(100));
    expect(tester.getTopLeft(titulo).dy, greaterThan(arriba));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(titulo).dy - arriba, closeTo(150, 0.5));
  });

  testWidgets(
    'los botones de boton.dart se achican mientras se presionan @RED-04-S13',
    (tester) async {
      await montar(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BotonPrimario(texto: 'PRIMARIO', alTocar: () {}),
                BotonTexto(texto: 'TEXTO', alTocar: () {}),
                BotonContorno(texto: 'CONTORNO', alTocar: () {}),
                BotonPeligro(texto: 'PELIGRO', alTocar: () {}),
              ],
            ),
          ),
        ),
        tema: temaOscuro,
      );

      for (final texto in ['PRIMARIO', 'TEXTO', 'CONTORNO', 'PELIGRO']) {
        final etiqueta = find.text(texto);
        final suelto = _ancho(tester, etiqueta);
        final dedo = await tester.startGesture(tester.getCenter(etiqueta));
        await tester.pump();
        await tester.pump(_ms(40));
        expect(_ancho(tester, etiqueta) / suelto, lessThan(1), reason: texto);
        await tester.pump(_ms(40));
        expect(
          _ancho(tester, etiqueta) / suelto,
          closeTo(0.97, 3e-3),
          reason: texto,
        );
        await dedo.up();
        await tester.pump();
        await tester.pump(_ms(80));
        expect(
          _ancho(tester, etiqueta) / suelto,
          closeTo(1, 3e-3),
          reason: texto,
        );
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'con reducir movimiento el festejo, el aviso y la entrada muestran su final en el primer cuadro @RED-04-S14',
    (tester) async {
      _reducirMovimiento(tester);

      // El festejo.
      await _montarLibre(
        tester,
        PantallaReservaConfirmada(reserva: _reservaConfirmada()),
      );
      final titulo = find.text('¡Reserva confirmada!');
      final comprobante = find.text('Horario');
      expect(find.byType(Festejo), findsOneWidget);
      final ancho = _ancho(tester, titulo);
      expect(_visibilidad(tester, comprobante), _uno);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpAndSettle();
      expect(_ancho(tester, titulo), closeTo(ancho, 1e-6));
      await _desmontar(tester);

      // El aviso dentro de la app.
      final api = ApiFalsa();
      final sesion = SesionFalsa(perfilUsuario);
      final centro = centroDe(api, sesion);
      await _montarLibre(
        tester,
        Stack(
          children: [
            const Scaffold(body: Center(child: Text('la pantalla de abajo'))),
            PanelDeAvisos(
              centro: centro,
              ahora: () => ahoraClub,
              alAbrir: (_) {},
            ),
          ],
        ),
      );
      api
        ..avisos = [recordatorio]
        ..noLeidas = 1;
      await tester.runAsync(centro.cargar);
      await tester.pump();
      await tester.pump();
      final aviso = find.text('NOTIFICACIONES');
      expect(aviso, findsOneWidget);
      final arriba = tester.getTopLeft(aviso).dy;
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(aviso).dy, closeTo(arriba, 1e-6));
      await _desmontar(tester);

      // La entrada escalonada del inicio.
      await _montarLibre(tester, inicioFalso(SesionFalsa(perfilUsuario)));
      await _hastaQue(
        tester,
        () => find.byType(TileDeporte).evaluate().isNotEmpty,
      );
      expect(_todasEnSuFinal(tester), isTrue);
    },
  );

  // ---- T5: diálogos y tarjeta de la cuenta ----

  testWidgets(
    'un diálogo de MarcoDeDialogo entra con fundido y escala de 0,88 a 1 @RED-04-S11',
    (tester) async {
      await montar(tester, _cancelacion(), tema: temaOscuro);
      await tester.tap(find.text('ABRIR'));
      await tester.pump();

      final titulo = find.text('¿Cancelar la reserva?');
      expect(titulo, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MarcoDeDialogo),
          matching: find.byWidgetPredicate((w) => w is Aparecer),
        ),
        findsWidgets,
        reason: 'el diálogo se anima dentro del marco',
      );
      final entrada = _aparecerQue(titulo, (a) => a.escalaDesde == 0.88);
      expect(entrada, findsOneWidget);
      final aparecer = tester.widget<Aparecer>(entrada);
      expect(aparecer.desdeY, 0);
      expect(aparecer.curva, Movimiento.rapida);

      final alPrincipio = _ancho(tester, titulo);
      expect(_opacidad(tester, entrada), 0);
      await tester.pump(_ms(100));
      expect(_opacidad(tester, entrada), allOf(greaterThan(0), lessThan(1)));
      await tester.pumpAndSettle();
      final entero = _ancho(tester, titulo);
      expect(alPrincipio / entero, closeTo(0.88, 0.02));
      expect(_opacidad(tester, entrada), 1);
    },
  );

  testWidgets(
    'el selector de opciones entra con la misma escala @RED-04-ASM-01',
    (tester) async {
      await montar(
        tester,
        _Anfitrion(
          abrir: (context) => unawaited(
            elegirOpcion<int>(
              context,
              titulo: 'Elegí el deporte',
              opciones: const [(1, 'Fútbol'), (2, 'Tenis')],
            ),
          ),
        ),
        tema: temaOscuro,
      );
      await tester.tap(find.text('ABRIR'));
      await tester.pump();

      final titulo = find.text('Elegí el deporte');
      expect(titulo, findsOneWidget);
      final entrada = _aparecerQue(titulo, (a) => a.escalaDesde == 0.88);
      expect(entrada, findsOneWidget);
      final aparecer = tester.widget<Aparecer>(entrada);
      expect(aparecer.desdeY, 0);
      expect(aparecer.curva, Movimiento.rapida);

      final alPrincipio = _ancho(tester, titulo);
      await tester.pumpAndSettle();
      expect(alPrincipio / _ancho(tester, titulo), closeTo(0.88, 0.02));
    },
  );

  testWidgets(
    'la tarjeta de la cuenta baja 16 y aparece en 350 ms @RED-04-S11',
    (tester) async {
      await montar(
        tester,
        Scaffold(
          body: Center(child: BotonCuenta(sesion: SesionFalsa(perfilUsuario))),
        ),
        tema: temaOscuro,
      );
      await tester.tap(find.byType(BotonCuenta));
      await tester.pump();

      final nombre = find.text('Nahuel Mosse');
      expect(nombre, findsOneWidget);
      final entrada = _aparecerQue(
        nombre,
        (a) => a.desdeY == -16 && a.duracion == _ms(350),
      );
      expect(entrada, findsOneWidget);

      final arriba = tester.getTopLeft(nombre).dy;
      expect(_opacidad(tester, entrada), 0);
      await tester.pump(_ms(175));
      final aMitad = tester.getTopLeft(nombre).dy;
      expect(_opacidad(tester, entrada), allOf(greaterThan(0), lessThan(1)));
      await tester.pump(_ms(175));
      final abajo = tester.getTopLeft(nombre).dy;
      expect(abajo - arriba, closeTo(16, 0.01));
      expect(aMitad, allOf(greaterThan(arriba), lessThan(abajo)));
      expect(_opacidad(tester, entrada), 1);
    },
  );

  testWidgets(
    'los botones de un diálogo se achican mientras se presionan @RED-04-S13',
    (tester) async {
      await montar(tester, _cancelacion(), tema: temaOscuro);
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      for (final texto in ['CANCELAR RESERVA', 'NO CANCELAR']) {
        final etiqueta = find.text(texto);
        final suelto = _ancho(tester, etiqueta);
        final dedo = await tester.startGesture(tester.getCenter(etiqueta));
        await tester.pump();
        await tester.pump(_ms(40));
        expect(_ancho(tester, etiqueta) / suelto, lessThan(1), reason: texto);
        await tester.pump(_ms(40));
        expect(
          _ancho(tester, etiqueta) / suelto,
          closeTo(0.97, 3e-3),
          reason: texto,
        );
        await dedo.cancel();
        await tester.pump();
        await tester.pump(_ms(80));
        expect(
          _ancho(tester, etiqueta) / suelto,
          closeTo(1, 3e-3),
          reason: texto,
        );
      }
    },
  );

  testWidgets(
    'con reducir movimiento el diálogo aparece entero en el primer cuadro @RED-04-S14',
    (tester) async {
      _reducirMovimiento(tester);
      await montar(tester, _cancelacion(), tema: temaOscuro);
      await tester.tap(find.text('ABRIR'));
      await tester.pump();

      final titulo = find.text('¿Cancelar la reserva?');
      final entrada = _aparecerQue(titulo, (a) => a.escalaDesde == 0.88);
      expect(entrada, findsOneWidget);
      expect(_opacidad(tester, entrada), 1);
      final alPrincipio = _ancho(tester, titulo);
      await tester.pumpAndSettle();
      expect(_ancho(tester, titulo), closeTo(alPrincipio, 1e-6));
    },
  );

  // ---- T6: las capturas ----

  testWidgets(
    'las capturas se toman con las animaciones terminadas @RED-04-ASM-12',
    (tester) async {
      final pantallas = <String, Widget>{
        'login': _login(),
        'inicio': inicioFalso(SesionFalsa(perfilUsuario)),
        'mi perfil': PantallaMiPerfil(
          sesion: SesionFalsa(perfilUsuario),
          apariencia: Apariencia.enMemoria(),
        ),
        'reserva confirmada': PantallaReservaConfirmada(
          reserva: _reservaConfirmada(),
        ),
      };
      for (final MapEntry(key: nombre, value: pantalla) in pantallas.entries) {
        // Como los helpers de test/capturas: `montar` termina con pumpAndSettle.
        await montar(tester, pantalla, tema: temaOscuro);
        expect(find.byType(Aparecer), findsWidgets, reason: nombre);
        expect(_todasEnSuFinal(tester), isTrue, reason: nombre);
        expect(tester.binding.hasScheduledFrame, isFalse, reason: nombre);
        await _desmontar(tester);
      }
    },
  );
}
