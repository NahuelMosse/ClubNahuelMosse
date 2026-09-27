/// Lo que cambia entre ambientes llega por `--dart-define`.
class Configuracion {
  const Configuracion({required this.apiUrl});

  factory Configuracion.desdeEntorno() {
    const apiUrl = String.fromEnvironment('API_URL');
    if (apiUrl.isEmpty) {
      throw StateError(
        'Falta --dart-define=API_URL con la dirección de la API',
      );
    }
    return const Configuracion(apiUrl: apiUrl);
  }

  final String apiUrl;
}
