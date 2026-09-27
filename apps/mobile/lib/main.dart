import 'package:flutter/material.dart';

import 'api/cliente_api.dart';
import 'app.dart';
import 'configuracion.dart';
import 'sesion/firebase.dart';
import 'sesion/sesion.dart';

Future<void> main() => arrancar(Configuracion.desdeEntorno());

Future<void> arrancar(Configuracion configuracion) async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = await iniciarFirebase(configuracion);
  final api = ClienteApi(configuracion.apiUrl);
  final sesion = Sesion(credenciales: CredencialesFirebase(auth), api: api);
  // La sesión queda abierta en el dispositivo: si todavía vale, se entra directo.
  final perfil = await sesion.retomar();
  // Una key nueva por arranque: la app se arma de cero aunque runApp se llame otra vez.
  runApp(
    App(
      key: UniqueKey(),
      api: api,
      sesion: sesion,
      inicio: perfil?.inicio ?? '/',
    ),
  );
}
