import 'notificacion.dart';

export 'sistema_simulado.dart';

/// Qué avisó el aviso que la persona tocó en la bandeja del sistema: lo que hace falta para
/// abrir la pantalla que corresponde.
class AvisoTocado {
  const AvisoTocado({this.tipo, this.reservaId, this.antiguo = false});

  /// Lee los datos del mensaje push. Un `reserva_id` que no es un UUID (un aviso numérico
  /// anterior a los UUID) marca el aviso como [antiguo]: no se puede resaltar esa reserva.
  factory AvisoTocado.desdeDatos(Map<String, Object?> datos) {
    final id = datos['reserva_id']?.toString() ?? '';
    final esUuid = _uuid.hasMatch(id);
    return AvisoTocado(
      tipo: TipoDeNotificacion.de(datos['tipo']?.toString() ?? ''),
      reservaId: esUuid ? id : null,
      antiguo: id.isNotEmpty && !esUuid,
    );
  }

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  final TipoDeNotificacion? tipo;
  final String? reservaId;
  final bool antiguo;

  /// A dónde abre tocarlo: el centro de notificaciones si es un aviso antiguo.
  String get ruta =>
      antiguo ? '/notificaciones' : rutaDelAviso(tipo, reservaId);
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
