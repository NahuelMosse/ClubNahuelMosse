import 'package:flutter/foundation.dart';

import '../api/cliente_api.dart';
import '../sesion/sesion.dart';
import 'eleccion.dart';
import 'horarios.dart';

/// Otra reserva activa tomó ese horario antes.
class HorarioOcupado implements Exception {
  const HorarioOcupado();
}

/// La reserva ya no estaba como se la veía: anulada, cancelada desde otro lado o ya
/// empezada.
class ReservaCambiada implements Exception {
  const ReservaCambiada();
}

/// La API rechazó el horario elegido: cada campo con su mensaje.
class ReservaRechazada implements Exception {
  const ReservaRechazada(this.errores);
  final Map<String, String> errores;
}

enum EstadoDeReserva { activa, completada, cancelada, anulada }

/// Una reserva de quien consulta, con el total que se guardó al reservar.
class Reserva {
  const Reserva({
    required this.id,
    required this.espacioId,
    required this.sedeId,
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
    this.cancelable = false,
  });

  final int id;
  final int espacioId;
  final int sedeId;

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

  /// Activa y sin empezar, según el servidor.
  final bool cancelable;

  static Reserva? desdeJson(Object? json) {
    if (json case {
      'id': final int id,
      'espacio_id': final int espacioId,
      'sede_id': final int sedeId,
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
        sedeId: sedeId,
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
        cancelable: json['cancelable'] == true,
      );
    }
    return null;
  }

  /// El club está en UTC−3, sin horario de verano: la hora se muestra así sea cual sea la
  /// zona del teléfono.
  static DateTime? _enElClub(String iso) =>
      DateTime.tryParse(iso)?.toUtc().subtract(const Duration(hours: 3));
}

/// Una tanda de reservas y, si hay más después de ella, lo que se manda para pedirlas.
class TandaDeReservas {
  const TandaDeReservas(this.reservas, this.siguiente);

  final List<Reserva> reservas;
  final String? siguiente;
}

/// Las reservas de quien inició sesión, leídas en la API. Avisa a quien escucha cada vez
/// que se reserva, se cancela o se modifica una.
class Reservas extends ChangeNotifier {
  Reservas({required ClienteApi api, required Sesion sesion})
    : _api = api,
      _sesion = sesion;

  final ClienteApi _api;
  final Sesion _sesion;

  /// Las primeras próximas (de la más cercana) o las primeras del historial (de la más
  /// reciente).
  ///
  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<List<Reserva>> mias({required bool historial}) async =>
      (await tanda(historial: historial)).reservas;

  /// Una tanda de las próximas o del historial: la primera, o la que sigue a la que trajo
  /// [despues] como `siguiente`.
  ///
  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<TandaDeReservas> tanda({
    required bool historial,
    String? despues,
  }) async {
    final cuando = historial ? 'historial' : 'proximas';
    final r = await _api.get(
      '/reservas?cuando=$cuando'
      '${despues == null ? '' : '&despues=${Uri.encodeQueryComponent(despues)}'}',
      token: await _sesion.token(),
    );
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 200) {
      if (r.cuerpo case {'reservas': final List<Object?> lista}) {
        final leidas = [for (final e in lista) Reserva.desdeJson(e)];
        if (!leidas.contains(null)) {
          return TandaDeReservas(
            [...leidas.nonNulls],
            switch (r.cuerpo) {
              {'siguiente': final String marcador} => marcador,
              _ => null,
            },
          );
        }
      }
    }
    throw ErrorDelServidor(r.codigo);
  }

  /// Reserva lo que se eligió en los horarios.
  ///
  /// Lanza [HorarioOcupado], [CanchaNoDisponible], [ReservaRechazada], [SesionVencida],
  /// [SinConexion] o [ErrorDelServidor].
  Future<Reserva> reservar(Eleccion eleccion) async {
    final f = eleccion.fecha;
    final r = await _api.post('/reservas', {
      'espacio_id': eleccion.cancha.id,
      'fecha':
          '${f.year}-${f.month.toString().padLeft(2, '0')}-'
          '${f.day.toString().padLeft(2, '0')}',
      'desde': eleccion.inicio,
      'horas': eleccion.horas,
    }, token: await _sesion.token());
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 409) throw const HorarioOcupado();
    if (r.cuerpo case {
      'errores': final Map<String, Object?> errores,
    } when r.codigo == 422) {
      if (errores.containsKey('espacio_id')) throw const CanchaNoDisponible();
      throw ReservaRechazada({
        for (final MapEntry(:key, :value) in errores.entries)
          if (value is String) key: value,
      });
    }
    final reserva = r.codigo == 201 ? Reserva.desdeJson(r.cuerpo) : null;
    if (reserva == null) throw ErrorDelServidor(r.codigo);
    notifyListeners();
    return reserva;
  }

  /// Cancela [reserva]; el horario vuelve a quedar libre.
  ///
  /// Lanza [ReservaCambiada], [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<Reserva> cancelar(Reserva reserva) async {
    final r = await _api.post(
      '/reservas/${reserva.id}/cancelar',
      const {},
      token: await _sesion.token(),
    );
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 404 || r.codigo == 409) throw const ReservaCambiada();
    final cancelada = r.codigo == 200 ? Reserva.desdeJson(r.cuerpo) : null;
    if (cancelada == null) throw ErrorDelServidor(r.codigo);
    notifyListeners();
    return cancelada;
  }

  /// Pasa [reserva] a la cancha, el día y la hora de [nueva], con la misma duración.
  ///
  /// Lanza [HorarioOcupado], [ReservaCambiada], [CanchaNoDisponible], [ReservaRechazada],
  /// [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<Reserva> modificar(Reserva reserva, Eleccion nueva) async {
    final f = nueva.fecha;
    final r = await _api.post('/reservas/${reserva.id}/modificar', {
      'espacio_id': nueva.cancha.id,
      'fecha':
          '${f.year}-${f.month.toString().padLeft(2, '0')}-'
          '${f.day.toString().padLeft(2, '0')}',
      'desde': nueva.inicio,
    }, token: await _sesion.token());
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 404) throw const ReservaCambiada();
    if (r.cuerpo case {'errores': final Map<String, Object?> errores}) {
      if (r.codigo == 409) {
        throw errores.containsKey('horario')
            ? const HorarioOcupado()
            : const ReservaCambiada();
      }
      if (r.codigo == 422) {
        if (errores.containsKey('espacio_id')) throw const CanchaNoDisponible();
        throw ReservaRechazada({
          for (final MapEntry(:key, :value) in errores.entries)
            if (value is String) key: value,
        });
      }
    }
    final modificada = r.codigo == 200 ? Reserva.desdeJson(r.cuerpo) : null;
    if (modificada == null) throw ErrorDelServidor(r.codigo);
    notifyListeners();
    return modificada;
  }
}
