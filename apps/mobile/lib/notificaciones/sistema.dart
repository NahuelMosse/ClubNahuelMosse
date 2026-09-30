import 'package:shared_preferences/shared_preferences.dart';

/// El sistema de notificaciones del teléfono: el permiso, el token del dispositivo y lo que
/// llega mientras la app está abierta o se abre tocando un aviso de la bandeja.
abstract interface class SistemaDeNotificaciones {
  /// `ios` o `android`, como lo registra la API.
  String get plataforma;

  Future<bool> permitido();

  /// Pide el permiso al sistema operativo y dice si quedó concedido.
  Future<bool> solicitarPermiso();

  Future<String?> token();

  /// Un aviso llegó con la app abierta; trae el número de reserva si es de una.
  Stream<int?> get alLlegar;

  /// La persona tocó un aviso de la bandeja y la app se abrió (o volvió al frente).
  Stream<int?> get alTocar;

  /// El aviso que abrió la app desde cero, si la abrió uno.
  Future<int?> abiertaPor();
}

/// El sistema de un dispositivo de prueba, sin Firebase Cloud Messaging.
///
/// El permiso lo guarda la app en el dispositivo (los escenarios lo fijan) y arranca
/// concedido; pedirlo lo concede. Nada llega por acá: con la app abierta la lista se entera
/// consultando la API.
class SistemaSimulado implements SistemaDeNotificaciones {
  static const _clavePermiso = 'permiso_notificaciones_simulado';
  static const _claveToken = 'token_notificaciones_simulado';

  @override
  String get plataforma => 'android';

  @override
  Future<bool> permitido() async =>
      (await SharedPreferences.getInstance()).getString(_clavePermiso) !=
      'denegado';

  @override
  Future<bool> solicitarPermiso() async {
    await (await SharedPreferences.getInstance()).setString(
      _clavePermiso,
      'concedido',
    );
    return true;
  }

  @override
  Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_claveToken);
    if (guardado != null) return guardado;
    final nuevo = 'simulado-${DateTime.now().microsecondsSinceEpoch}';
    await prefs.setString(_claveToken, nuevo);
    return nuevo;
  }

  @override
  Stream<int?> get alLlegar => const Stream.empty();

  @override
  Stream<int?> get alTocar => const Stream.empty();

  @override
  Future<int?> abiertaPor() async => null;
}
