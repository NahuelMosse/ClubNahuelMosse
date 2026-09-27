import 'package:flutter/material.dart';

import 'app.dart';
import 'configuracion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App(configuracion: Configuracion.desdeEntorno()));
}
