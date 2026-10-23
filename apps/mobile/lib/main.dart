import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'api/cliente_api.dart';
import 'app.dart';
import 'comun/apariencia.dart';
import 'comun/configuracion.dart';
import 'notificaciones/centro.dart';
import 'notificaciones/notificaciones.dart';
import 'notificaciones/sistema.dart';
import 'notificaciones/sistema_fcm.dart';
import 'sesion/firebase.dart';
import 'sesion/sesion.dart';

Future<void> main() => arrancar(Configuracion.desdeEntorno());

Future<void> arrancar(Configuracion configuracion) async {
  WidgetsFlutterBinding.ensureInitialized();
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
  final perfil = await sesion.retomar();
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
