/// Lo que cambia entre ambientes llega por `--dart-define`.
class Configuracion {
  const Configuracion({
    required this.apiUrl,
    required this.firebase,
    this.authEmulador,
  });

  factory Configuracion.desdeEntorno() {
    const apiUrl = String.fromEnvironment('API_URL');
    if (apiUrl.isEmpty) {
      throw StateError(
        'Falta --dart-define=API_URL con la dirección de la API',
      );
    }
    const authEmulador = String.fromEnvironment('AUTH_EMULADOR');
    if (authEmulador.isNotEmpty) {
      return const Configuracion(
        apiUrl: apiUrl,
        firebase: ProyectoFirebase.emulador,
        authEmulador: authEmulador,
      );
    }
    return Configuracion(
      apiUrl: apiUrl,
      firebase: ProyectoFirebase.desdeEntorno(),
    );
  }

  final String apiUrl;
  final ProyectoFirebase firebase;

  /// `host:puerto` del emulador de Firebase Auth; sin él, se usa el proyecto real.
  final String? authEmulador;

  Configuracion con({String? apiUrl, String? authEmulador}) => Configuracion(
    apiUrl: apiUrl ?? this.apiUrl,
    firebase: firebase,
    authEmulador: authEmulador ?? this.authEmulador,
  );
}

/// Los datos del proyecto de Firebase que la app necesita para iniciar el SDK.
class ProyectoFirebase {
  const ProyectoFirebase({
    required this.apiKey,
    required this.appId,
    required this.senderId,
    required this.projectId,
  });

  factory ProyectoFirebase.desdeEntorno() {
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
    return const ProyectoFirebase(
      apiKey: apiKey,
      appId: appId,
      senderId: senderId,
      projectId: projectId,
    );
  }

  /// El emulador acepta cualquier clave; el proyecto `demo-` no existe en la nube.
  static const emulador = ProyectoFirebase(
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
