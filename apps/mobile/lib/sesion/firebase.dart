import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../comun/configuracion.dart';

/// Inicia Firebase una sola vez por configuración y devuelve su `FirebaseAuth`.
///
/// Cada emulador distinto usa su propia instancia con nombre. En Android el SDK aplica el
/// último `useAuthEmulator` a todas las instancias, así que se vuelve a fijar cada vez.
Future<FirebaseAuth> iniciarFirebase(Configuracion configuracion) async {
  final emulador = configuracion.authEmulador;
  final nombre = emulador == null ? defaultFirebaseAppName : 'auth-$emulador';
  final existente = Firebase.apps.where((a) => a.name == nombre);
  final FirebaseApp app;
  if (existente.isNotEmpty) {
    app = existente.first;
  } else {
    final proyecto = configuracion.firebase;
    final opciones = FirebaseOptions(
      apiKey: proyecto.apiKey,
      appId: proyecto.appId,
      messagingSenderId: proyecto.senderId,
      projectId: proyecto.projectId,
    );
    app = emulador == null
        ? await Firebase.initializeApp(options: opciones)
        : await Firebase.initializeApp(name: nombre, options: opciones);
  }
  final auth = FirebaseAuth.instanceFor(app: app);
  if (emulador != null) {
    final separador = emulador.lastIndexOf(':');
    await auth.useAuthEmulator(
      emulador.substring(0, separador),
      int.parse(emulador.substring(separador + 1)),
    );
  }
  return auth;
}
