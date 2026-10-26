import '../api/cliente_api.dart';
import '../comun/fechas.dart';
import '../comun/zona_club.dart';
import '../reservas/reservas.dart'
    show EstadoDeReserva, ReservaCambiada, ReservaRechazada;
import '../sesion/sesion.dart';

/// Lo que un administrador eligió para acotar el historial global (CU-14). `null` en
/// cualquier campo significa que ese filtro no se aplica.
class FiltrosDeHistorial {
  const FiltrosDeHistorial({
    this.estado,
    this.sedeId,
    this.deporte,
    this.desde,
    this.hasta,
    this.q,
  });

  /// Las cuatro pestañas del prototipo: nunca [EstadoDeReserva.cancelada], que sólo aparece
  /// dentro de «Todas».
  final EstadoDeReserva? estado;
  final int? sedeId;
  final String? deporte;
  final DateTime? desde;
  final DateTime? hasta;
  final String? q;

  bool get hayFiltros =>
      estado != null ||
      sedeId != null ||
      deporte != null ||
      desde != null ||
      hasta != null ||
      _busqueda != null;

  /// El texto buscado sin espacios en los bordes; `null` si no hay.
  String? get _busqueda {
    final limpio = q?.trim();
    return limpio == null || limpio.isEmpty ? null : limpio;
  }

  /// `true` si `desde` es posterior a `hasta` (FA3): no se consulta al servidor.
  bool get rangoInvalido {
    final d = desde;
    final h = hasta;
    return d != null && h != null && d.isAfter(h);
  }

  FiltrosDeHistorial conEstado(EstadoDeReserva? nuevo) => FiltrosDeHistorial(
    estado: nuevo,
    sedeId: sedeId,
    deporte: deporte,
    desde: desde,
    hasta: hasta,
    q: q,
  );

  FiltrosDeHistorial conBusqueda(String? nueva) => FiltrosDeHistorial(
    estado: estado,
    sedeId: sedeId,
    deporte: deporte,
    desde: desde,
    hasta: hasta,
    q: nueva,
  );

  String get _query {
    final estado = this.estado;
    final deporte = this.deporte;
    final desde = this.desde;
    final hasta = this.hasta;
    final busqueda = _busqueda;
    final partes = <String>[
      if (estado != null) 'estado=${estado.name}',
      if (sedeId != null) 'sede_id=$sedeId',
      if (deporte != null) 'deporte=${Uri.encodeQueryComponent(deporte)}',
      if (desde != null) 'desde=${fechaIso(desde)}',
      if (hasta != null) 'hasta=${fechaIso(hasta)}',
      if (busqueda != null) 'q=${Uri.encodeQueryComponent(busqueda)}',
    ];
    return partes.join('&');
  }
}

/// Cuántas reservas hay en cada pestaña, con los mismos filtros salvo el de estado.
class Contadores {
  const Contadores({
    required this.todas,
    required this.activas,
    required this.completadas,
    required this.anuladas,
  });

  final int todas;
  final int activas;
  final int completadas;
  final int anuladas;

  static Contadores? desdeJson(Object? json) => switch (json) {
    {
      'todas': final int todas,
      'activas': final int activas,
      'completadas': final int completadas,
      'anuladas': final int anuladas,
    } =>
      Contadores(
        todas: todas,
        activas: activas,
        completadas: completadas,
        anuladas: anuladas,
      ),
    _ => null,
  };
}

/// Una reserva como la ve un administrador (CU-14): con quién la hizo y su trazabilidad.
class ReservaHistorial {
  const ReservaHistorial({
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
    required this.usuarioId,
    required this.usuario,
    required this.creadoEn,
    required this.canceladaEn,
    required this.canceladaPorNombre,
    required this.espacioDeBaja,
    this.anulable = false,
    this.avisoEnvio,
    this.avisoEn,
  });

  final int id;
  final int espacioId;
  final int sedeId;
  final String espacio;
  final String deporte;
  final String tipo;
  final String sede;
  final String direccion;
  final DateTime inicio;
  final DateTime fin;
  final int total;
  final EstadoDeReserva estado;
  final String? motivo;
  final int usuarioId;
  final String usuario;
  final DateTime creadoEn;
  final DateTime? canceladaEn;
  final String? canceladaPorNombre;

  /// El espacio o su sede ya no están activos: la reserva sigue en el historial (FA8).
  final bool espacioDeBaja;

  /// Activa y sin empezar, según el reloj del servidor: sólo entonces se ofrece anularla.
  final bool anulable;

  /// Cómo salió el aviso de la anulación a quien reservó (`enviada`, `sin_permiso`,
  /// `sin_canal` o `fallida`) y cuándo; `null` si no hubo aviso o todavía no salió.
  final String? avisoEnvio;
  final DateTime? avisoEn;

  static DateTime? _enElClub(String iso) {
    final momento = DateTime.tryParse(iso);
    return momento == null ? null : enElClub(momento);
  }

  static ReservaHistorial? desdeJson(Object? json) {
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
      'usuario_id': final int usuarioId,
      'usuario': final String usuario,
      'creado_en': final String creadoEn,
      'cancelada_en': final Object? canceladaEn,
      'cancelada_por_nombre': final Object? canceladaPorNombre,
      'espacio_de_baja': final bool espacioDeBaja,
    }) {
      final desde = _enElClub(inicio);
      final hasta = _enElClub(fin);
      final creado = _enElClub(creadoEn);
      final est = EstadoDeReserva.values.where((e) => e.name == estado);
      if (desde == null || hasta == null || creado == null || est.isEmpty) {
        return null;
      }
      return ReservaHistorial(
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
        usuarioId: usuarioId,
        usuario: usuario,
        creadoEn: creado,
        canceladaEn: canceladaEn is String ? _enElClub(canceladaEn) : null,
        canceladaPorNombre: canceladaPorNombre is String
            ? canceladaPorNombre
            : null,
        espacioDeBaja: espacioDeBaja,
        anulable: json['anulable'] == true,
        avisoEnvio: json['aviso_envio'] is String
            ? json['aviso_envio'] as String
            : null,
        avisoEn: json['aviso_en'] is String
            ? _enElClub(json['aviso_en'] as String)
            : null,
      );
    }
    return null;
  }
}

/// Una página del historial global, con el total y los contadores de las pestañas.
class PaginaDeHistorial {
  const PaginaDeHistorial({
    required this.reservas,
    required this.total,
    required this.pagina,
    required this.porPagina,
    required this.contadores,
  });

  final List<ReservaHistorial> reservas;
  final int total;
  final int pagina;
  final int porPagina;
  final Contadores contadores;

  bool get hayMasPaginas => pagina * porPagina < total;
}

/// El historial global de reservas (CU-14), sólo para un administrador.
class HistorialDeReservas {
  HistorialDeReservas({required ClienteApi api, required Sesion sesion})
    : _api = api,
      _sesion = sesion;

  final ClienteApi _api;
  final Sesion _sesion;

  /// El `siguiente` que trajo cada página ya leída, por filtros y número de página: la que
  /// sigue lo manda como `despues`, y el servidor no recorre las anteriores.
  final Map<String, String> _marcadores = {};

  /// La página [pagina] (empieza en 1) que cumple [filtros].
  ///
  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<PaginaDeHistorial> pagina(
    FiltrosDeHistorial filtros, {
    int pagina = 1,
  }) async {
    if (pagina == 1) _marcadores.clear();
    final despues = _marcadores['${filtros._query}|${pagina - 1}'];
    final query = [
      filtros._query,
      'pagina=$pagina',
      if (despues != null) 'despues=${Uri.encodeQueryComponent(despues)}',
    ].where((s) => s.isNotEmpty).join('&');
    final r = await _api.get(
      '/reservas/todas?$query',
      token: await _sesion.token(),
    );
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 200) {
      if (r.cuerpo case {
        'reservas': final List<Object?> lista,
        'total': final int total,
        'pagina': final int p,
        'por_pagina': final int porPagina,
        'contadores': final Object? contadoresJson,
      }) {
        final leidas = [for (final e in lista) ReservaHistorial.desdeJson(e)];
        final contadores = Contadores.desdeJson(contadoresJson);
        if (!leidas.contains(null) && contadores != null) {
          if (r.cuerpo case {'siguiente': final String marcador}) {
            _marcadores['${filtros._query}|$p'] = marcador;
          }
          return PaginaDeHistorial(
            reservas: [...leidas.nonNulls],
            total: total,
            pagina: p,
            porPagina: porPagina,
            contadores: contadores,
          );
        }
      }
    }
    throw ErrorDelServidor(r.codigo);
  }

  /// El detalle de cualquier reserva por [id]. `null` si ya no existe.
  ///
  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<ReservaHistorial?> detalle(int id) async {
    final r = await _api.get(
      '/reservas/todas/$id',
      token: await _sesion.token(),
    );
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 404) return null;
    if (r.codigo == 200) {
      final leida = ReservaHistorial.desdeJson(r.cuerpo);
      if (leida != null) return leida;
    }
    throw ErrorDelServidor(r.codigo);
  }

  /// Anula [reserva] con [motivo], tal como el administrador la vio (cancha y horario); el
  /// horario vuelve a quedar libre. Repetir un pedido que ya se hizo responde igual.
  ///
  /// Lanza [ReservaCambiada], [ReservaRechazada], [SesionVencida], [SinConexion] o
  /// [ErrorDelServidor].
  Future<ReservaHistorial> anular(
    ReservaHistorial reserva,
    String motivo,
  ) async {
    final r = await _api.post('/reservas/${reserva.id}/anular', {
      'motivo': motivo,
      'espacio_id': reserva.espacioId,
      'inicio': instanteDelClub(reserva.inicio).toIso8601String(),
    }, token: await _sesion.token());
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 404 || r.codigo == 409) throw const ReservaCambiada();
    if (r.cuerpo case {
      'errores': final Map<String, Object?> errores,
    } when r.codigo == 422) {
      throw ReservaRechazada({
        for (final MapEntry(:key, :value) in errores.entries)
          if (value is String) key: value,
      });
    }
    final anulada = r.codigo == 200
        ? ReservaHistorial.desdeJson(r.cuerpo)
        : null;
    if (anulada == null) throw ErrorDelServidor(r.codigo);
    return anulada;
  }
}

/// Los filtros del historial global que quedaron aplicados cuando la sesión venció (CU-14
/// FA5): se restauran al volver a entrar al panel, como `ReservaPendiente` con la reserva.
class FiltrosDePanelPendientes {
  FiltrosDeHistorial? _filtros;

  void guardar(FiltrosDeHistorial filtros) => _filtros = filtros;

  /// Los filtros guardados, y los descarta: sólo se restauran una vez.
  FiltrosDeHistorial? sacar() {
    final filtros = _filtros;
    _filtros = null;
    return filtros;
  }
}
