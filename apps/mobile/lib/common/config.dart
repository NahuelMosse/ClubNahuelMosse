// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
/// How notifications reach the app.
enum Push {
  /// Firebase Cloud Messaging, with the real project.
  fcm,

  /// Without Firebase Cloud Messaging: the permission and the token are those of a test device.
  simulated,
}

/// What changes between environments arrives through `--dart-define`.
class AppConfig {
  const AppConfig({
    required this.apiUrl,
    required this.firebase,
    this.authEmulator,
    this.push = Push.fcm,
    this.notificationPollInterval = const Duration(seconds: 20),
  });

  factory AppConfig.fromEnvironment() {
    const apiUrl = String.fromEnvironment('API_URL');
    if (apiUrl.isEmpty) {
      throw StateError(
        'Falta --dart-define=API_URL con la dirección de la API',
      );
    }
    const authEmulator = String.fromEnvironment('AUTH_EMULADOR');
    // With the emulator there is no Firebase project: notifications are simulated and the
    // app polls often, so the scenarios do not wait.
    const seconds = int.fromEnvironment(
      'AVISOS_SEGUNDOS',
      defaultValue: authEmulator == '' ? 20 : 2,
    );
    const push = String.fromEnvironment('PUSH');
    if (authEmulator.isNotEmpty) {
      return const AppConfig(
        apiUrl: apiUrl,
        firebase: FirebaseProject.emulator,
        authEmulator: authEmulator,
        push: Push.simulated,
        notificationPollInterval: Duration(seconds: seconds),
      );
    }
    return AppConfig(
      apiUrl: apiUrl,
      firebase: FirebaseProject.fromEnvironment(),
      push: push == 'simulado' ? Push.simulated : Push.fcm,
      notificationPollInterval: const Duration(seconds: seconds),
    );
  }

  final String apiUrl;
  final FirebaseProject firebase;

  /// `host:port` of the Firebase Auth emulator; without it, the real project is used.
  final String? authEmulator;
  final Push push;

  /// How often the open app checks whether a notification arrived.
  final Duration notificationPollInterval;

  AppConfig copyWith({String? apiUrl, String? authEmulator}) => AppConfig(
    apiUrl: apiUrl ?? this.apiUrl,
    firebase: firebase,
    authEmulator: authEmulator ?? this.authEmulator,
    push: push,
    notificationPollInterval: notificationPollInterval,
  );
}

/// The Firebase project data the app needs to start the SDK.
class FirebaseProject {
  const FirebaseProject({
    required this.apiKey,
    required this.appId,
    required this.senderId,
    required this.projectId,
  });

  factory FirebaseProject.fromEnvironment() {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    if ([apiKey, appId, senderId, projectId].any((v) => v.isEmpty)) {
      throw StateError(
        'Faltan --dart-define FIREBASE_API_KEY, FIREBASE_APP_ID, '
        'FIREBASE_SENDER_ID y FIREBASE_PROJECT_ID, o AUTH_EMULADOR',
      );
    }
    return const FirebaseProject(
      apiKey: apiKey,
      appId: appId,
      senderId: senderId,
      projectId: projectId,
    );
  }

  /// The emulator accepts any key; the `demo-` project does not exist in the cloud.
  static const emulator = FirebaseProject(
    apiKey: 'clave-del-emulador',
    appId: '1:1:android:1',
    senderId: '1',
    projectId: 'demo-clubnahuelmosse',
  );

  final String apiKey;
  final String appId;
  final String senderId;
  final String projectId;
}
