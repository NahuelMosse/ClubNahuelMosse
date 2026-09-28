import '../api/cliente_api.dart';
import '../sesion/sesion.dart';

/// La cancha o su sede ya no se pueden reservar.
class CanchaNoDisponible implements Exception {
  const CanchaNoDisponible();
}

/// El día pedido ya no está entre los que se pueden consultar: pasó la medianoche.
class FechaVencida implements Exception {
  const FechaVencida();
}

/// Una hora de inicio de la grilla, con su fin según la duración consultada.
class Franja {
  const Franja({
    required this.inicio,
    required this.fin,
    required this.disponible,
  });

  /// `HH:MM` en la hora del club.
  final String inicio;
  final String fin;
  final bool disponible;

  /// «18:00 – 19:00».
  String get texto => '$inicio – $fin';

  static Franja? desdeJson(Object? json) => switch (json) {
    {
      'inicio': final String inicio,
      'fin': final String fin,
      'disponible': final bool disponible,
    } =>
      Franja(inicio: inicio, fin: fin, disponible: disponible),
    _ => null,
  };
}

/// Las franjas de una cancha para un día y una duración, como las calcula la API.
class Grilla {
  const Grilla({
    required this.fecha,
    required this.hoy,
    required this.abre,
    required this.franjas,
    required this.noDisponibles,
  });

  /// Fechas sin hora, en UTC: el día del club.
  final DateTime fecha;
  final DateTime hoy;

  /// Falso si la sede no abre ese día.
  final bool abre;
  final List<Franja> franjas;
  final int noDisponibles;

  bool get hayLibres => franjas.any((f) => f.disponible);

  static Grilla? desdeJson(Object? json) {
    if (json case {
      'fecha': final String fecha,
      'hoy': final String hoy,
      'abre': final bool abre,
      'franjas': final List<Object?> lista,
      'no_disponibles': final int noDisponibles,
    }) {
      final dia = _dia(fecha);
      final deHoy = _dia(hoy);
      final franjas = [for (final f in lista) Franja.desdeJson(f)];
      if (dia == null || deHoy == null || franjas.contains(null)) return null;
      return Grilla(
        fecha: dia,
        hoy: deHoy,
        abre: abre,
        franjas: [...franjas.nonNulls],
        noDisponibles: noDisponibles,
      );
    }
    return null;
  }

  static DateTime? _dia(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? null : DateTime.utc(d.year, d.month, d.day);
  }
}

/// Los horarios de las canchas, leídos en la API con la sesión abierta.
class Horarios {
  Horarios({required ClienteApi api, required Sesion sesion})
    : _api = api,
      _sesion = sesion;

  final ClienteApi _api;
  final Sesion _sesion;

  /// La grilla de la cancha [espacioId] para [fecha] (hoy si no viene) con franjas de
  /// [horas].
  ///
  /// Lanza [CanchaNoDisponible], [FechaVencida], [SesionVencida], [SinConexion] o
  /// [ErrorDelServidor].
  Future<Grilla> de(int espacioId, {DateTime? fecha, int horas = 1}) async {
    final dia = fecha;
    final consulta = Uri(
      path: '/espacios/$espacioId/horarios',
      queryParameters: {
        'horas': '$horas',
        if (dia != null)
          'fecha':
              '${dia.year}-${dia.month.toString().padLeft(2, '0')}-'
              '${dia.day.toString().padLeft(2, '0')}',
      },
    );
    final r = await _api.get(consulta.toString(), token: await _sesion.token());
    if (r.codigo == 401) throw const SesionVencida();
    if (r.cuerpo case {
      'errores': {'espacio_id': String _},
    } when r.codigo == 404) {
      throw const CanchaNoDisponible();
    }
    if (r.cuerpo case {'errores': {'fecha': String _}} when r.codigo == 422) {
      throw const FechaVencida();
    }
    final grilla = r.codigo == 200 ? Grilla.desdeJson(r.cuerpo) : null;
    if (grilla == null) throw ErrorDelServidor(r.codigo);
    return grilla;
  }
}
