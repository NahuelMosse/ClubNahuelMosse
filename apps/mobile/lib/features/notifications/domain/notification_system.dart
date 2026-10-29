import 'app_notification.dart';
import 'notification_kind.dart';

/// Qué avisó el aviso que la persona tocó en la bandeja del sistema: lo que hace falta para
/// abrir la pantalla que corresponde.
class NoticeTapped {
  const NoticeTapped({this.kind, this.bookingId, this.legacy = false});

  /// Lee los datos del mensaje push. Un `booking_id` que no es un UUID (un aviso numérico
  /// anterior a los UUID) marca el aviso como [legacy]: no se puede resaltar esa reserva.
  factory NoticeTapped.fromData(Map<String, Object?> data) {
    final id = data['booking_id']?.toString() ?? '';
    final isUuid = _uuid.hasMatch(id);
    return NoticeTapped(
      kind: NotificationKind.fromApi(data['kind']?.toString() ?? ''),
      bookingId: isUuid ? id : null,
      legacy: id.isNotEmpty && !isUuid,
    );
  }

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  final NotificationKind? kind;
  final String? bookingId;
  final bool legacy;

  /// A dónde abre tocarlo: el centro de notificaciones si es un aviso antiguo.
  String get route => legacy ? '/notificaciones' : noticeRoute(kind, bookingId);
}

/// El sistema de notificaciones del teléfono: el permiso, el token del dispositivo y lo que
/// llega mientras la app está abierta o se abre tocando un aviso de la bandeja.
abstract interface class NotificationSystem {
  /// `ios` o `android`, como lo registra la API.
  String get platform;

  Future<bool> isAllowed();

  /// Si el sistema operativo ya le preguntó a la persona por las notificaciones.
  Future<bool> wasAsked();

  /// Pide el permiso al sistema operativo y dice si quedó concedido.
  Future<bool> requestPermission();

  Future<String?> token();

  /// Borra el token del dispositivo: lo que la API todavía le mande a ese token deja de llegar.
  /// El próximo [token] es otro.
  Future<void> forgetToken();

  /// Un aviso llegó con la app abierta.
  Stream<void> get onArrive;

  /// La persona tocó un aviso de la bandeja y la app se abrió (o volvió al frente).
  Stream<NoticeTapped> get onTap;

  /// El aviso que abrió la app desde cero, si la abrió uno.
  Future<NoticeTapped?> openedBy();
}
