import 'package:shared_preferences/shared_preferences.dart';

import 'notificacion.dart';

/// Qué avisó el aviso que la persona tocó en la bandeja del sistema: lo que hace falta para
/// abrir la pantalla que corresponde.
class AvisoTocado {
  const AvisoTocado({this.tipo, this.reservaId});

  final TipoDeNotificacion? tipo;
  final int? reservaId;
}

/// El sistema de notificaciones del teléfono: el permiso, el token del dispositivo y lo que
/// llega mientras la app está abierta o se abre tocando un aviso de la bandeja.
abstract interface class SistemaDeNotificaciones {
  /// `ios` o `android`, como lo registra la API.
  String get plataforma;

  Future<bool> permitido();

  /// Si el sistema operativo ya le preguntó a la persona por las notificaciones.
  Future<bool> preguntado();

  /// Pide el permiso al sistema operativo y dice si quedó concedido.
  Future<bool> solicitarPermiso();

  Future<String?> token();

  /// Borra el token del dispositivo: lo que la API todavía le mande a ese token deja de llegar.
  /// El próximo [token] es otro.
  Future<void> olvidarToken();

  /// Un aviso llegó con la app abierta.
  Stream<void> get alLlegar;

  /// La persona tocó un aviso de la bandeja y la app se abrió (o volvió al frente).
  Stream<AvisoTocado> get alTocar;

  /// El aviso que abrió la app desde cero, si la abrió uno.
  Future<AvisoTocado?> abiertaPor();
}

/// El sistema de un dispositivo de prueba, sin Firebase Cloud Messaging.
///
/// La respuesta al permiso la guarda la app en el dispositivo (los escenarios la fijan); sin
/// respuesta guardada, todavía no preguntó. Pedirlo guarda y devuelve la respuesta fijada,
/// concedido si no hay otra. Nada llega por acá: con la app abierta la lista se entera
/// consultando la API.
class SistemaSimulado implements SistemaDeNotificaciones {
  static const _clavePermiso = 'permiso_notificaciones_simulado';
  static const _claveToken = 'token_notificaciones_simulado';

  @override
  String get plataforma => 'android';

  @override
  Future<bool> permitido() async =>
      (await SharedPreferences.getInstance()).getString(_clavePermiso) ==
      'concedido';

  @override
  Future<bool> preguntado() async =>
      (await SharedPreferences.getInstance()).getString(_clavePermiso) != null;

  @override
  Future<bool> solicitarPermiso() async {
    final prefs = await SharedPreferences.getInstance();
    final respuesta = prefs.getString(_clavePermiso) ?? 'concedido';
    await prefs.setString(_clavePermiso, respuesta);
    return respuesta == 'concedido';
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
  Future<void> olvidarToken() async {
    await (await SharedPreferences.getInstance()).remove(_claveToken);
  }

  @override
  Stream<void> get alLlegar => const Stream.empty();

  @override
  Stream<AvisoTocado> get alTocar => const Stream.empty();

  @override
  Future<AvisoTocado?> abiertaPor() async => null;
}
