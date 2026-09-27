import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../configuracion.dart';

/// Inicia Firebase una sola vez por configuración y devuelve su `FirebaseAuth`.
///
/// Cada emulador distinto usa su propia instancia con nombre: el SDK sólo acepta
/// `useAuthEmulator` antes del primer uso, así que una instancia no cambia de emulador.
Future<FirebaseAuth> iniciarFirebase(Configuracion configuracion) async {
  final emulador = configuracion.authEmulador;
  final nombre = emulador == null ? defaultFirebaseAppName : 'auth-$emulador';
  final existente = Firebase.apps.where((a) => a.name == nombre);
  if (existente.isNotEmpty) {
    return FirebaseAuth.instanceFor(app: existente.first);
  }
  final proyecto = configuracion.firebase;
  final opciones = FirebaseOptions(
    apiKey: proyecto.apiKey,
    appId: proyecto.appId,
    messagingSenderId: proyecto.senderId,
    projectId: proyecto.projectId,
  );
  final app = emulador == null
      ? await Firebase.initializeApp(options: opciones)
      : await Firebase.initializeApp(name: nombre, options: opciones);
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
