import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../common/config.dart';

/// Starts Firebase only once per configuration and returns its `FirebaseAuth`.
///
/// Each different emulator uses its own named instance. On Android the SDK applies the
/// last `useAuthEmulator` to all instances, so it is set again each time.
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
