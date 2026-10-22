import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'api/cliente_api.dart';
import 'app.dart';
import 'comun/apariencia.dart';
import 'comun/aviso_despertando.dart';
import 'comun/errores_no_manejados.dart';
import 'comun/pantalla_error_de_arranque.dart';
import 'configuracion.dart';
import 'notificaciones/centro.dart';
import 'notificaciones/notificaciones.dart';
import 'notificaciones/sistema.dart';
import 'notificaciones/sistema_fcm.dart';
import 'sesion/firebase.dart';
import 'sesion/sesion.dart';
import 'tema/tema.dart';
import 'tema/tokens.dart';

void main() => correrProtegido(() => arrancar(Configuracion.desdeEntorno()));

Future<void> arrancar(Configuracion configuracion) async {
  WidgetsFlutterBinding.ensureInitialized();
  instalarCapturaDeErrores();
  final auth = await iniciarFirebase(configuracion);
  final api = ClienteApi(configuracion.apiUrl);
  final sesion = Sesion(credenciales: CredencialesFirebase(auth), api: api);
  final SistemaDeNotificaciones sistema = switch (configuracion.push) {
    Push.fcm => SistemaFcm(FirebaseMessaging.instance),
    Push.simulado => SistemaSimulado(),
  };
  final centro = CentroDeNotificaciones(
    notificaciones: Notificaciones(api: api, sesion: sesion),
    sesion: sesion,
    sistema: sistema,
    cada: configuracion.avisosCada,
  );
  // La sesión queda abierta en el dispositivo: si todavía vale, se entra directo.
  final apariencia = await Apariencia.cargar();
  final perfil = await _retomar(sesion, api);
  // Una key nueva por arranque: la app se arma de cero aunque runApp se llame otra vez.
  runApp(
    App(
      key: UniqueKey(),
      api: api,
      sesion: sesion,
      apariencia: apariencia,
      centro: centro,
      inicio: perfil?.inicio ?? '/',
    ),
  );
}

/// Retoma la sesión guardada. Mientras la API despierta avisa; si no se puede saber si la
/// sesión vale, ofrece reintentar en vez de mandar al login.
Future<Perfil?> _retomar(Sesion sesion, ClienteApi api) async {
  while (true) {
    runApp(_Espera(api: api));
    try {
      return await sesion.retomar();
    } on ErrorDelServidor catch (e) {
      await _ofrecerReintento(sinRed: false, causa: e);
    } on SinConexion catch (e) {
      await _ofrecerReintento(sinRed: true, causa: e);
    }
  }
}

Future<void> _ofrecerReintento({
  required bool sinRed,
  required Object causa,
}) {
  registrarError(causa);
  final pulsado = Completer<void>();
  runApp(
    _Marco(
      child: PantallaErrorDeArranque(
        sinRed: sinRed,
        alReintentar: () {
          if (!pulsado.isCompleted) pulsado.complete();
        },
      ),
    ),
  );
  return pulsado.future;
}

class _Marco extends StatelessWidget {
  const _Marco({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: temaClaro,
    darkTheme: temaOscuro,
    home: child,
  );
}

class _Espera extends StatelessWidget {
  const _Espera({required this.api});

  final ClienteApi api;

  @override
  Widget build(BuildContext context) => _Marco(
    child: Builder(
      builder: (context) => Scaffold(
        backgroundColor: context.paleta.bgBase,
        body: Stack(
          children: [
            const Center(child: CircularProgressIndicator()),
            AvisoDespertando(despertando: api.despertando),
          ],
        ),
      ),
    ),
  );
}
