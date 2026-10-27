import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'api/cliente_api.dart';
import 'app.dart';
import 'comun/apariencia.dart';
import 'comun/configuracion.dart';
import 'comun/dialogo_error.dart';
import 'notificaciones/centro.dart';
import 'notificaciones/notificaciones.dart';
import 'notificaciones/sistema.dart';
import 'notificaciones/sistema_fcm.dart';
import 'sesion/firebase.dart';
import 'sesion/sesion.dart';
import 'tema/tema.dart';
import 'tema/tokens.dart';

void main() => arrancar(Configuracion.desdeEntorno());

Future<void> arrancar(Configuracion configuracion) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
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
  final perfil = await retomarConReintento(sesion);
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

/// Retoma la sesión guardada. Si no se puede saber si la sesión vale (sin conexión o la
/// API no responde), muestra el diálogo de error con «Reintentar» en vez de mandar al login.
Future<Perfil?> retomarConReintento(Sesion sesion) async {
  final navegador = GlobalKey<NavigatorState>();
  runApp(_Espera(navegador: navegador));
  while (true) {
    try {
      return await sesion.retomar();
    } on FalloDeRed catch (e) {
      await WidgetsBinding.instance.endOfFrame;
      final contexto = navegador.currentState?.overlay?.context;
      if (contexto == null || !contexto.mounted) rethrow;
      await atenderErrorDeRed(contexto, e);
    }
  }
}

class _Espera extends StatelessWidget {
  const _Espera({required this.navegador});

  final GlobalKey<NavigatorState> navegador;

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navegador,
    debugShowCheckedModeBanner: false,
    theme: temaClaro,
    darkTheme: temaOscuro,
    home: Builder(
      builder: (context) => Scaffold(
        backgroundColor: context.paleta.bgBase,
        body: const Center(child: CircularProgressIndicator()),
      ),
    ),
  );
}
