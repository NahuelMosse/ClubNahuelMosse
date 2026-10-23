/// Por dónde le llegan los avisos a la app.
enum Push {
  /// Firebase Cloud Messaging, con el proyecto real.
  fcm,

  /// Sin Firebase Cloud Messaging: el permiso y el token son de un dispositivo de prueba.
  simulado,
}

/// Lo que cambia entre ambientes llega por `--dart-define`.
class Configuracion {
  const Configuracion({
    required this.apiUrl,
    required this.firebase,
    this.authEmulador,
    this.push = Push.fcm,
    this.avisosCada = const Duration(seconds: 20),
  });

  factory Configuracion.desdeEntorno() {
    const apiUrl = String.fromEnvironment('API_URL');
    if (apiUrl.isEmpty) {
      throw StateError(
        'Falta --dart-define=API_URL con la dirección de la API',
      );
    }
    const authEmulador = String.fromEnvironment('AUTH_EMULADOR');
    // Con el emulador no hay proyecto de Firebase: los avisos son simulados y la app los
    // consulta seguido, para que los escenarios no esperen.
    const segundos = int.fromEnvironment(
      'AVISOS_SEGUNDOS',
      defaultValue: authEmulador == '' ? 20 : 2,
    );
    const push = String.fromEnvironment('PUSH');
    if (authEmulador.isNotEmpty) {
      return const Configuracion(
        apiUrl: apiUrl,
        firebase: ProyectoFirebase.emulador,
        authEmulador: authEmulador,
        push: Push.simulado,
        avisosCada: Duration(seconds: segundos),
      );
    }
    return Configuracion(
      apiUrl: apiUrl,
      firebase: ProyectoFirebase.desdeEntorno(),
      push: push == 'simulado' ? Push.simulado : Push.fcm,
      avisosCada: const Duration(seconds: segundos),
    );
  }

  final String apiUrl;
  final ProyectoFirebase firebase;

  /// `host:puerto` del emulador de Firebase Auth; sin él, se usa el proyecto real.
  final String? authEmulador;
  final Push push;

  /// Cada cuánto la app abierta consulta si llegó algún aviso.
  final Duration avisosCada;

  Configuracion con({String? apiUrl, String? authEmulador}) => Configuracion(
    apiUrl: apiUrl ?? this.apiUrl,
    firebase: firebase,
    authEmulador: authEmulador ?? this.authEmulador,
    push: push,
    avisosCada: avisosCada,
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
