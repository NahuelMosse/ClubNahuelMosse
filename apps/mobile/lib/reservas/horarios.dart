import '../api/cliente_api.dart';
import '../comun/errores_de_campo.dart';
import '../comun/fechas.dart';
import '../espacios/espacio.dart';
import '../sesion/sesion.dart';

/// La cancha o su sede ya no se pueden reservar.
class CanchaNoDisponible implements Exception {
  const CanchaNoDisponible();
}

/// El día pedido ya no está entre los que se pueden consultar: pasó la medianoche.
class FechaVencida implements Exception {
  const FechaVencida();
}

/// La API rechazó el rango consultado: cada campo con su mensaje.
class RangoRechazado implements Exception {
  const RangoRechazado(this.errores);
  final Map<String, String> errores;
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

  /// Lee [consulta] con el token de la sesión; un 401 es sesión vencida.
  Future<Respuesta> _pedir(Uri consulta) async {
    final r = await _api.get(consulta.toString(), token: await _sesion.token());
    if (r.codigo == 401) throw const SesionVencida();
    return r;
  }

  /// La grilla de la cancha [espacioId] para [fecha] (hoy si no viene) con franjas de
  /// [horas].
  ///
  /// Lanza [CanchaNoDisponible], [FechaVencida], [SesionVencida], [SinConexion] o
  /// [ErrorDelServidor].
  ///
  /// [reservaId] es la reserva que se está modificando: no cuenta como ocupada.
  Future<Grilla> de(
    String espacioId, {
    DateTime? fecha,
    int horas = 1,
    String? reservaId,
  }) async {
    final dia = fecha;
    final consulta = Uri(
      path: '/espacios/$espacioId/horarios',
      queryParameters: {
        'horas': '$horas',
        'reserva_id': ?reservaId,
        if (dia != null) 'fecha': fechaIso(dia),
      },
    );
    final r = await _pedir(consulta);
    final errores = erroresDeCampo(r.cuerpo);
    if (r.codigo == 404 && errores.containsKey('espacio_id')) {
      throw const CanchaNoDisponible();
    }
    if (r.codigo == 422 && errores.containsKey('fecha')) {
      throw const FechaVencida();
    }
    final grilla = r.codigo == 200 ? Grilla.desdeJson(r.cuerpo) : null;
    if (grilla == null) throw ErrorDelServidor(r.codigo);
    return grilla;
  }

  /// Las canchas de [sedeId] y [deporte] (y [tipo] si viene) libres en todo el rango
  /// [desde] a [hasta] (`HH:MM`) el [fecha].
  ///
  /// Lanza [RangoRechazado], [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<List<Espacio>> libres({
    required String sedeId,
    required String deporte,
    String? tipo,
    required DateTime fecha,
    required String desde,
    required String hasta,
  }) async {
    final consulta = Uri(
      path: '/espacios/disponibles',
      queryParameters: {
        'sede_id': sedeId,
        'deporte': deporte,
        'tipo': ?tipo,
        'fecha': fechaIso(fecha),
        'desde': desde,
        'hasta': hasta,
      },
    );
    final r = await _pedir(consulta);
    final errores = erroresDeCampo(r.cuerpo);
    if (r.codigo == 422 && errores.isNotEmpty) throw RangoRechazado(errores);
    final leidos = r.codigo == 200 ? Espacio.listaDesdeCuerpo(r.cuerpo) : null;
    if (leidos != null) return leidos;
    throw ErrorDelServidor(r.codigo);
  }
}
