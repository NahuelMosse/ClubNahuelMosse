import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../common/config.dart';

/// Inicia Firebase una sola vez por configuración y devuelve su `FirebaseAuth`.
///
/// Cada emulador distinto usa su propia instancia con nombre. En Android el SDK aplica el
/// último `useAuthEmulator` a todas las instancias, así que se vuelve a fijar cada vez.
Future<FirebaseAuth> initFirebase(AppConfig config) async {
  final emulator = config.authEmulator;
  final name = emulator == null ? defaultFirebaseAppName : 'auth-$emulator';
  final existing = Firebase.apps.where((a) => a.name == name);
  final FirebaseApp app;
  if (existing.isNotEmpty) {
    app = existing.first;
  } else {
    final project = config.firebase;
    final options = FirebaseOptions(
      apiKey: project.apiKey,
      appId: project.appId,
      messagingSenderId: project.senderId,
      projectId: project.projectId,
    );
    app = emulator == null
        ? await Firebase.initializeApp(options: options)
        : await Firebase.initializeApp(name: name, options: options);
  }
  final auth = FirebaseAuth.instanceFor(app: app);
  if (emulator != null) {
    final separator = emulator.lastIndexOf(':');
    await auth.useAuthEmulator(
      emulator.substring(0, separator),
      int.parse(emulator.substring(separator + 1)),
    );
  }
  return auth;
}
