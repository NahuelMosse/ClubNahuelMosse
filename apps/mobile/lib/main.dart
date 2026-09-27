import 'package:flutter/material.dart';

import 'app.dart';
import 'configuracion.dart';
import 'sesion/firebase.dart';

Future<void> main() => arrancar(Configuracion.desdeEntorno());

Future<void> arrancar(Configuracion configuracion) async {
  WidgetsFlutterBinding.ensureInitialized();
  await iniciarFirebase(configuracion);
  runApp(App(configuracion: configuracion));
}
