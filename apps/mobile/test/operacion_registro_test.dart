// ignore_for_file: unawaited_futures
import 'dart:convert';

import 'package:clubnahuelmosse/admin/historial_reservas.dart';
import 'package:clubnahuelmosse/admin/pantalla_detalle_reserva.dart';
import 'package:clubnahuelmosse/admin/pantalla_editar_espacio.dart';
import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/comun/apariencia.dart';
import 'package:clubnahuelmosse/comun/errores_no_manejados.dart';
import 'package:clubnahuelmosse/espacios/espacio.dart';
import 'package:clubnahuelmosse/espacios/espacios.dart';
import 'package:clubnahuelmosse/inicio/pantalla_inicio.dart';
import 'package:clubnahuelmosse/reservas/reservas.dart';
import 'package:clubnahuelmosse/sedes/sedes.dart';
import 'package:clubnahuelmosse/notificaciones/centro.dart';
import 'package:clubnahuelmosse/notificaciones/notificaciones.dart';
import 'package:clubnahuelmosse/notificaciones/sistema.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/admin.dart';
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

const _reservaJson =
    '{"id": 1, "espacio_id": 9, "sede_id": 1, "espacio":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", "tipo": "F5", "sede":'
    ' "Sede Morón", "direccion": "Av. Rivadavia 19850", "inicio":'
    ' "2026-11-12T21:00:00-03:00", "fin": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "estado": "activa", "motivo": null, "usuario_id": 1, "usuario": "Nahuel Mosse",'
    ' "creado_en": "2026-11-02T18:42:00-03:00", "cancelada_en": null,'
    ' "cancelada_por_nombre": null, "espacio_de_baja": false, "anulable": true}';

void main() {
  setUpAll(cargarFuentes);

  ClienteApi lenta(Duration demora, {String cuerpo = '{"sedes": []}'}) =>
      ClienteApi(
        'http://api.falsa',
        cliente: MockClient(
          (_) => Future.delayed(demora, () => http.Response(cuerpo, 200)),
        ),
      );

  ClienteApi sinRed() => ClienteApi(
    'http://api.falsa',
    cliente: MockClient((_) async => throw http.ClientException('sin red')),
  );

  /// Anota en [registrados] lo que la app registra y lo restaura al terminar.
  List<Object> escuchar() {
    final anterior = registroDeErrores;
    addTearDown(() => registroDeErrores = anterior);
    final registrados = <Object>[];
    registroDeErrores = (error, pila) => registrados.add(error);
    return registrados;
  }

  testWidgets(
    'un pedido que tarda 40 s porque la API está despertando no se corta @REV-02-S8 @assumption:REV-02-ASM-06',
    (tester) async {
      Respuesta? respuesta;
      Object? error;
      lenta(const Duration(seconds: 40))
          .get('/sedes', token: 'token')
          .then((r) { respuesta = r; }, onError: (Object e) { error = e; });

      await tester.pump(const Duration(seconds: 41));

      expect(error, isNull);
      expect(respuesta?.codigo, 200);
    },
  );

  testWidgets(
    'a los 60 s sin respuesta dice El servidor no responde. Probá de nuevo en unos minutos. @REV-02-S8 @assumption:REV-02-ASM-06',
    (tester) async {
      await montarUsuario(
        tester,
        api: lenta(const Duration(seconds: 90)),
      );
      await tester.pump(const Duration(seconds: 61));
      await tester.pump();

      expect(
        find.text('El servidor no responde. Probá de nuevo en unos minutos.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 40));
    },
  );

  testWidgets(
    'sin red sigue diciendo Revisá tu conexión a internet @REV-02-S8 @assumption:REV-02-ASM-06',
    (tester) async {
      await montarUsuario(tester, api: sinRed());

      expect(find.textContaining('Revisá tu conexión a internet'), findsOneWidget);
      expect(find.textContaining('no responde'), findsNothing);
    },
  );

  testWidgets(
    'si la API tarda más de 5 s la app avisa que se está despertando y que puede tardar hasta un minuto @REV-02-S8 @assumption:REV-02-ASM-11',
    (tester) async {
      await tester.pumpWidget(
        App(
          api: lenta(const Duration(seconds: 40)),
          sesion: SesionFalsa(perfilUsuario),
          apariencia: Apariencia.enMemoria(oscuro: true),
          inicio: '/sedes',
        ),
      );
      await tester.pump();
      expect(find.textContaining('despertando'), findsNothing);

      await tester.pump(const Duration(seconds: 6));

      expect(find.textContaining('despertando'), findsOneWidget);
      expect(find.textContaining('hasta un minuto'), findsOneWidget);
      await tester.pump(const Duration(seconds: 40));
    },
  );

  testWidgets(
    'retomar la sesión espera hasta 60 s y sin respuesta no manda al login @REV-02-S8 @assumption:REV-02-ASM-12',
    (tester) async {
      Sesion con(ClienteApi api) => Sesion(
        credenciales: CredencialesFalsas(conCuenta: true),
        api: api,
      );
      Perfil? perfil;
      con(lenta(const Duration(seconds: 40), cuerpo: perfilJson()))
          .retomar()
          .then((p) { perfil = p; });
      await tester.pump(const Duration(seconds: 41));
      expect(perfil?.nombre, 'Nahuel');

      Object? error;
      Perfil? entro;
      con(lenta(const Duration(seconds: 90)))
          .retomar()
          .then((p) { entro = p; }, onError: (Object e) { error = e; });
      await tester.pump(const Duration(seconds: 61));

      expect(error, isA<ServidorSinRespuesta>());
      expect(entro, isNull);
      await tester.pump(const Duration(seconds: 40));
    },
  );

  test('un error de Flutter queda registrado @REV-02-S11 @assumption:REV-02-ASM-13', () {
    final anterior = FlutterError.onError;
    addTearDown(() => FlutterError.onError = anterior);
    final registrados = <Object>[];

    instalarCapturaDeErrores((error, pila) => registrados.add(error));
    FlutterError.onError!(FlutterErrorDetails(exception: StateError('en un widget')));

    expect(registrados, [isA<StateError>()]);
  });

  test('un error de la plataforma queda registrado @REV-02-S11 @assumption:REV-02-ASM-13', () {
    final anterior = PlatformDispatcher.instance.onError;
    addTearDown(() => PlatformDispatcher.instance.onError = anterior);
    final registrados = <Object>[];

    instalarCapturaDeErrores((error, pila) => registrados.add(error));
    final atrapado = PlatformDispatcher.instance.onError!(
      ArgumentError('en un Future'),
      StackTrace.current,
    );

    expect(registrados, [isA<ArgumentError>()]);
    expect(atrapado, isTrue);
  });

  test('un error de una zona queda registrado @REV-02-S11 @assumption:REV-02-ASM-13', () async {
    final registrados = <Object>[];

    correrProtegido(() {
      Future<void>(() => throw FormatException('en una zona'));
    }, (error, pila) => registrados.add(error));
    await Future<void>.delayed(Duration.zero);

    expect(registrados, [isA<FormatException>()]);
  });

  testWidgets(
    'el detalle de la reserva registra el error que ignoraba @REV-02-S11 @assumption:REV-02-ASM-13',
    (tester) async {
      final registrados = escuchar();
      final sesion = SesionFalsa(perfilAdmin);
      final api = apiRutas({
        'GET /reservas/todas/1': (500, '{}'),
        'GET /espacios/catalogo': (500, '{}'),
      });
      final reserva = ReservaHistorial.desdeJson(jsonDecode(_reservaJson));

      await montar(
        tester,
        PantallaDetalleReserva(
          reserva: reserva!,
          historial: HistorialDeReservas(api: api, sesion: sesion),
          sesion: sesion,
          espacios: Espacios(api: api, sesion: sesion),
          filtros: const FiltrosDeHistorial(),
          pendientes: FiltrosDePanelPendientes(),
        ),
        tema: temaOscuro,
      );

      expect(registrados, hasLength(2));
      expect(registrados, everyElement(isA<ErrorDelServidor>()));
    },
  );

  testWidgets(
    'el centro de notificaciones registra los errores que tragaba @REV-02-S11 @assumption:REV-02-ASM-13',
    (tester) async {
      final registrados = escuchar();
      final sesion = SesionFalsa(perfilUsuario);
      final centro = CentroDeNotificaciones(
        notificaciones: Notificaciones(api: sinRed(), sesion: sesion),
        sesion: sesion,
        sistema: SistemaSimulado(),
        cada: Duration.zero,
      );

      await centro.marcarTodas();
      await tester.pump();

      expect(registrados, isNotEmpty);
      expect(registrados, everyElement(isA<SinConexion>()));
    },
  );

  testWidgets(
    'editar espacio registra el error que tragaba @REV-02-S11 @assumption:REV-02-ASM-13',
    (tester) async {
      final registrados = escuchar();
      final sesion = SesionFalsa(perfilAdmin);
      final api = apiRutas({'GET /espacios/catalogo': (500, '{}')});

      await montar(
        tester,
        PantallaEditarEspacio(
          espacio: Espacio.desdeJson(jsonDecode(espacioF5Json))!,
          espacios: Espacios(api: api, sesion: sesion),
          sesion: sesion,
        ),
        tema: temaOscuro,
      );

      expect(registrados, [isA<ErrorDelServidor>()]);
    },
  );

  testWidgets(
    'el inicio registra el error que tragaba al releer @REV-02-S11 @assumption:REV-02-ASM-13',
    (tester) async {
      final registrados = escuchar();
      var fallar = false;
      final base = apiInicio();
      final api = ClienteApi(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          if (fallar) return http.Response('{}', 500);
          if (pedido.method == 'DELETE') return http.Response('', 204);
          return base.get(pedido.url.path, token: 't').then(
            (r) => http.Response.bytes(utf8.encode(jsonEncode(r.cuerpo)), r.codigo),
          );
        }),
      );
      final sesion = SesionFalsa(perfilUsuario);
      await montar(
        tester,
        PantallaInicio(
          sesion: sesion,
          reservas: Reservas(api: api, sesion: sesion),
          espacios: Espacios(api: api, sesion: sesion),
          sedes: Sedes(api: api, sesion: sesion),
        ),
        tema: temaOscuro,
      );

      await tester.pumpAndSettle();
      fallar = true;
      await tester.tap(find.text('CANCELAR').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('CANCELAR RESERVA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();

      expect(registrados, isNotEmpty);
      expect(registrados, everyElement(isA<ErrorDelServidor>()));
    },
  );

  testWidgets(
    'si la API no responde en un minuto, el error dice que no responde y no que falta internet @REV-02-S8 @assumption:REV-02-ASM-06',
    (tester) async {
      Object? error;
      lenta(const Duration(seconds: 90))
          .get('/sedes', token: 'token')
          .then((_) {}, onError: (Object e) { error = e; });

      await tester.pump(const Duration(seconds: 61));

      expect(error, isA<ServidorSinRespuesta>());
      expect(error, isNot(isA<SinConexion>()));
      await tester.pump(const Duration(seconds: 40));
    },
  );

  testWidgets(
    'un error del servidor le muestra a la persona su número de referencia @REV-02-S7',
    (tester) async {
      await montarUsuario(
        tester,
        inicio: '/sedes/1/canchas/9',
        api: apiRutas({
          ...rutasDeSedes(),
          'POST /reservas': (500, '{"mensaje": "Algo falló", "referencia": "ref-7f3a"}'),
        }),
      );
      final franja = find.bySemanticsLabel('18:00 – 19:00');
      await tester.ensureVisible(franja);
      await tester.pumpAndSettle();
      await tester.tap(franja);
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUAR'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CONFIRMAR RESERVA'));
      await tester.pumpAndSettle();

      expect(find.text('Error del servidor'), findsOneWidget);
      expect(find.textContaining('ref-7f3a'), findsOneWidget);
    },
  );

  test('la app registra sus errores no manejados en vez de tragarlos @REV-02-S11', () {
    final anteriorFlutter = FlutterError.onError;
    final anteriorPlataforma = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = anteriorFlutter;
      PlatformDispatcher.instance.onError = anteriorPlataforma;
    });
    final registrados = <Object>[];

    instalarCapturaDeErrores((error, pila) => registrados.add(error));
    FlutterError.onError!(FlutterErrorDetails(exception: StateError('en un widget')));
    final atrapado = PlatformDispatcher.instance.onError!(
      ArgumentError('en un Future'),
      StackTrace.current,
    );

    expect(registrados, [isA<StateError>(), isA<ArgumentError>()]);
    expect(atrapado, isTrue);
  });
}
