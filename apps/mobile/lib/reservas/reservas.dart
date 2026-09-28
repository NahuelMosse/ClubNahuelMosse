import '../api/cliente_api.dart';
import '../sesion/sesion.dart';

enum EstadoDeReserva { activa, completada, cancelada, anulada }

/// Una reserva de quien consulta, con el total que se guardó al reservar.
class Reserva {
  const Reserva({
    required this.id,
    required this.espacioId,
    required this.espacio,
    required this.deporte,
    required this.tipo,
    required this.sede,
    required this.direccion,
    required this.inicio,
    required this.fin,
    required this.total,
    required this.estado,
    required this.motivo,
  });

  final int id;
  final int espacioId;

  /// El nombre compuesto del espacio.
  final String espacio;
  final String deporte;
  final String tipo;
  final String sede;
  final String direccion;

  /// En la hora del club.
  final DateTime inicio;
  final DateTime fin;
  final int total;
  final EstadoDeReserva estado;
  final String? motivo;

  static Reserva? desdeJson(Object? json) {
    if (json case {
      'id': final int id,
      'espacio_id': final int espacioId,
      'espacio': final String espacio,
      'deporte': final String deporte,
      'tipo': final String tipo,
      'sede': final String sede,
      'direccion': final String direccion,
      'inicio': final String inicio,
      'fin': final String fin,
      'total': final int total,
      'estado': final String estado,
      'motivo': final Object? motivo,
    }) {
      final desde = _enElClub(inicio);
      final hasta = _enElClub(fin);
      final est = EstadoDeReserva.values.where((e) => e.name == estado);
      if (desde == null || hasta == null || est.isEmpty) return null;
      return Reserva(
        id: id,
        espacioId: espacioId,
        espacio: espacio,
        deporte: deporte,
        tipo: tipo,
        sede: sede,
        direccion: direccion,
        inicio: desde,
        fin: hasta,
        total: total,
        estado: est.first,
        motivo: motivo is String ? motivo : null,
      );
    }
    return null;
  }

  /// El club está en UTC−3, sin horario de verano: la hora se muestra así sea cual sea la
  /// zona del teléfono.
  static DateTime? _enElClub(String iso) =>
      DateTime.tryParse(iso)?.toUtc().subtract(const Duration(hours: 3));
}

/// Las reservas de quien inició sesión, leídas en la API.
class Reservas {
  Reservas({required ClienteApi api, required Sesion sesion})
    : _api = api,
      _sesion = sesion;

  final ClienteApi _api;
  final Sesion _sesion;

  /// Las próximas (de la más cercana) o el historial (de la más reciente).
  ///
  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<List<Reserva>> mias({required bool historial}) async {
    final r = await _api.get(
      '/reservas?cuando=${historial ? 'historial' : 'proximas'}',
      token: await _sesion.token(),
    );
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 200) {
      if (r.cuerpo case {'reservas': final List<Object?> lista}) {
        final leidas = [for (final e in lista) Reserva.desdeJson(e)];
        if (!leidas.contains(null)) return [...leidas.nonNulls];
      }
    }
    throw ErrorDelServidor(r.codigo);
  }
}
