import '../comun/fechas.dart';
import '../comun/zona_club.dart';

/// Qué avisa una notificación: el recordatorio de una reserva próxima, la cancelación que
/// hizo el club o la confirmación de la que hizo la propia persona.
enum TipoDeNotificacion {
  recordatorio('recordatorio'),
  cancelacionForzosa('cancelacion_forzosa'),
  cancelacionUsuario('cancelacion_usuario');

  const TipoDeNotificacion(this.clave);
  final String clave;

  static TipoDeNotificacion? de(String clave) =>
      values.where((t) => t.clave == clave).firstOrNull;
}

/// A dónde lleva tocar un aviso: Mis reservas con la reserva resaltada. Las cancelaciones —del
/// club o de la propia persona— dejaron la reserva en el historial, así que abren esa pestaña.
String rutaDelAviso(TipoDeNotificacion? tipo, String? reservaId) {
  final historial =
      tipo == TipoDeNotificacion.cancelacionForzosa ||
      tipo == TipoDeNotificacion.cancelacionUsuario;
  final parametros = [
    if (historial) 'historial=1',
    if (reservaId != null) 'reserva=$reservaId',
  ];
  return parametros.isEmpty ? '/reservas' : '/reservas?${parametros.join('&')}';
}

/// Una entrada del centro de notificaciones.
class Notificacion {
  const Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.cuerpo,
    required this.reservaId,
    required this.creada,
    required this.leida,
  });

  final String id;
  final TipoDeNotificacion tipo;
  final String titulo;
  final String cuerpo;
  final String? reservaId;

  /// En la hora del club.
  final DateTime creada;
  final bool leida;

  Notificacion comoLeida() => Notificacion(
    id: id,
    tipo: tipo,
    titulo: titulo,
    cuerpo: cuerpo,
    reservaId: reservaId,
    creada: creada,
    leida: true,
  );

  static Notificacion? desdeJson(Object? json) {
    if (json case {
      'id': final String id,
      'tipo': final String tipo,
      'titulo': final String titulo,
      'cuerpo': final String cuerpo,
      'creada_en': final String creada,
      'leida': final bool leida,
    }) {
      final t = TipoDeNotificacion.de(tipo);
      final cuando = DateTime.tryParse(creada);
      if (t == null || cuando == null) return null;
      return Notificacion(
        id: id,
        tipo: t,
        titulo: titulo,
        cuerpo: cuerpo,
        reservaId: json['reserva_id'] is String
            ? json['reserva_id'] as String
            : null,
        creada: enDelClub(cuando),
        leida: leida,
      );
    }
    return null;
  }
}

/// Los días se cuentan en el club, sea cual sea la zona del teléfono.
DateTime enDelClub(DateTime momento) => enElClub(momento);

/// Las notificaciones de un mismo día, con su rótulo: HOY, AYER o `dd/mm`.
class GrupoDeDia {
  const GrupoDeDia(this.rotulo, this.notificaciones);
  final String rotulo;
  final List<Notificacion> notificaciones;
}

DateTime _dia(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// HOY, AYER o `dd/mm`, según [ahora] en la hora del club.
String rotuloDeDia(DateTime creada, DateTime ahora) {
  final dias = _dia(ahora).difference(_dia(creada)).inDays;
  return switch (dias) {
    0 => 'HOY',
    1 => 'AYER',
    _ => diaYMes(creada),
  };
}

/// Cuándo llegó: AHORA, HACE 2 MIN, HACE 3 H, AYER o `dd/mm`.
String cuandoLlego(DateTime creada, DateTime ahora) {
  final pasado = ahora.difference(creada);
  final rotulo = rotuloDeDia(creada, ahora);
  if (rotulo != 'HOY') return rotulo;
  if (pasado.inMinutes < 1) return 'AHORA';
  if (pasado.inMinutes < 60) return 'HACE ${pasado.inMinutes} MIN';
  return 'HACE ${pasado.inHours} H';
}

/// Agrupa por día conservando el orden de [lista], de la más nueva a la más vieja.
List<GrupoDeDia> agruparPorDia(List<Notificacion> lista, DateTime ahora) {
  final grupos = <GrupoDeDia>[];
  for (final n in lista) {
    final rotulo = rotuloDeDia(n.creada, ahora);
    if (grupos.isNotEmpty && grupos.last.rotulo == rotulo) {
      grupos.last.notificaciones.add(n);
    } else {
      grupos.add(GrupoDeDia(rotulo, [n]));
    }
  }
  return grupos;
}
