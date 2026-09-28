import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/boton.dart';
import '../comun/dialogo_error.dart';
import '../comun/estado_vacio.dart';
import '../comun/formato_precio.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../espacios/iconos.dart';
import '../sedes/fotos.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'fechas.dart';
import 'reservas.dart';

/// «Mis reservas»: las próximas y el historial de quien inició sesión.
class PantallaMisReservas extends StatefulWidget {
  const PantallaMisReservas({
    super.key,
    required this.reservas,
    required this.espacios,
    required this.sesion,
  });

  final Reservas reservas;
  final Espacios espacios;
  final Sesion sesion;

  @override
  State<PantallaMisReservas> createState() => _PantallaMisReservasState();
}

class _PantallaMisReservasState extends State<PantallaMisReservas> {
  bool _historial = false;
  (List<Reserva>, Catalogo)? _datos;
  bool _fallo = false;

  /// Sube con cada lectura: la respuesta de una pestaña que ya no se mira se descarta.
  int _pedido = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Con [deCero] (otra pestaña) la lista se vacía mientras llega la nueva; al refrescar
  /// queda la que había hasta que llega la nueva, y se quita si la lectura falla.
  Future<void> _cargar({bool deCero = true}) async {
    final pedido = ++_pedido;
    setState(() {
      if (deCero) _datos = null;
      _fallo = false;
    });
    Object? fallo;
    var vencida = false;
    try {
      final catalogo = await widget.espacios.catalogo();
      final lista = await widget.reservas.mias(historial: _historial);
      if (mounted && pedido == _pedido) {
        setState(() => _datos = (lista, catalogo));
      }
      return;
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    }
    if (!mounted || pedido != _pedido) return;
    setState(() {
      _datos = null;
      _fallo = true;
    });
    if (ModalRoute.of(context)?.isCurrent == false) return;
    if (vencida) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    } else if (fallo != null) {
      final reintentar = await mostrarErrorDeRed(context, fallo);
      if (reintentar && mounted) await _cargar();
    }
  }

  void _elegir(bool historial) {
    if (historial == _historial) return;
    setState(() => _historial = historial);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final datos = _datos;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BarraInferior(actual: Seccion.reservas),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _cargar(deCero: false),
          // Una persona tiene pocas reservas: se construyen todas, así el lector de
          // pantalla llega a cada una sin tener que deslizar primero.
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              Medidas.s24,
              Medidas.s24,
              Medidas.s24,
              Medidas.s40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Mis reservas',
                          style: Textos.h1.copyWith(color: p.textPrimary),
                        ),
                      ),
                    ),
                    BotonCuenta(sesion: widget.sesion),
                  ],
                ),
                const SizedBox(height: Medidas.s16),
                _Pestanas(historial: _historial, alElegir: _elegir),
                const SizedBox(height: Medidas.s16),
                if (datos == null && !_fallo)
                  const Padding(
                    padding: EdgeInsets.all(Medidas.s40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (datos == null && _fallo)
                  Padding(
                    padding: const EdgeInsets.all(Medidas.s24),
                    child: Center(
                      child: BotonTexto(texto: 'REINTENTAR', alTocar: _cargar),
                    ),
                  ),
                if (datos != null && datos.$1.isEmpty)
                  EstadoVacio(
                    titulo: _historial
                        ? 'No hay reservas pasadas'
                        : 'No hay próximas reservas',
                    texto: _historial
                        ? 'No se encontraron reservas pasadas asociadas a tu cuenta.'
                        : 'No se encontraron próximas reservas asociadas a tu cuenta.',
                  ),
                if (datos != null)
                  for (final r in datos.$1) ...[
                    TarjetaReserva(reserva: r, catalogo: datos.$2),
                    const SizedBox(height: Medidas.s12),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `Segmented-Tab`: Próximas o Historial.
class _Pestanas extends StatelessWidget {
  const _Pestanas({required this.historial, required this.alElegir});

  final bool historial;
  final ValueChanged<bool> alElegir;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    Widget pestana(String texto, bool esHistorial) {
      final elegida = historial == esHistorial;
      return Expanded(
        child: Semantics(
          container: true,
          button: true,
          selected: elegida,
          label: texto,
          excludeSemantics: true,
          onTap: () => alElegir(esHistorial),
          child: Material(
            color: elegida ? p.accentBase : Colors.transparent,
            shape: const StadiumBorder(),
            child: InkWell(
              onTap: () => alElegir(esHistorial),
              customBorder: const StadiumBorder(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: Medidas.s48),
                child: Center(
                  child: Text(
                    texto,
                    style: Textos.cuerpoFuerte.copyWith(
                      color: elegida ? p.accentOn : p.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Medidas.s4),
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Medidas.radioPill),
      ),
      child: Row(
        children: [
          pestana('Próximas', false),
          const SizedBox(width: Medidas.s4),
          pestana('Historial', true),
        ],
      ),
    );
  }
}

/// `Card-Reserva`: deporte, sede y dirección, precio y estado arriba; el espacio, la fecha
/// y el horario abajo, con el porqué si se canceló o se anuló.
class TarjetaReserva extends StatelessWidget {
  const TarjetaReserva({
    super.key,
    required this.reserva,
    required this.catalogo,
  });

  final Reserva reserva;
  final Catalogo catalogo;

  String get _horario {
    String dos(int n) => n.toString().padLeft(2, '0');
    final r = reserva;
    return '${dos(r.inicio.hour)}:${dos(r.inicio.minute)} – '
        '${dos(r.fin.hour)}:${dos(r.fin.minute)}';
  }

  String? get _porque => switch (reserva.estado) {
    EstadoDeReserva.cancelada =>
      'Cancelada por vos · el horario quedó liberado',
    EstadoDeReserva.anulada => switch (reserva.motivo) {
      final m? when m.trim().isNotEmpty => 'Anulada por el administrador · $m',
      _ => 'Anulada por el administrador',
    },
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    final porque = _porque;
    final anulada = r.estado == EstadoDeReserva.anulada;
    final grande = MediaQuery.textScalerOf(context).scale(10) > 13;
    final precioYEstado = Column(
      crossAxisAlignment: grande
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          pesos(r.total),
          style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
        ),
        const SizedBox(height: Medidas.s8),
        _Estado(estado: r.estado),
      ],
    );
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: [
        catalogo.tipoCorto(r.deporte, r.tipo),
        '${r.sede}, ${r.direccion}',
        r.estado.name,
        fechaLarga(r.inicio),
        _horario,
        '${pesos(r.total).replaceFirst('\$\u00A0', '')} pesos',
        r.espacio,
        ?porque,
      ].join(', '),
      child: Container(
        decoration: BoxDecoration(
          color: p.bgSurfaceRaised,
          borderRadius: BorderRadius.circular(Medidas.radioLg),
          border: Border.all(color: p.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(Medidas.s16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Medidas.radioMd),
                    child: Image(
                      image: fotoDeDeporte(r.deporte),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(width: Medidas.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              iconoDeDeporte(r.deporte),
                              size: 16,
                              color: p.textSecondary,
                            ),
                            const SizedBox(width: Medidas.s4),
                            Flexible(
                              child: Text(
                                catalogo.tipoCorto(r.deporte, r.tipo),
                                style: Textos.titulo.copyWith(
                                  color: p.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Medidas.s4),
                        Text(
                          '${r.sede} · ${r.direccion}',
                          style: Textos.leyenda.copyWith(
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!grande) ...[
                    const SizedBox(width: Medidas.s8),
                    precioYEstado,
                  ],
                ],
              ),
            ),
            if (grande)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.s16,
                  0,
                  Medidas.s16,
                  Medidas.s16,
                ),
                child: precioYEstado,
              ),
            Divider(height: 1, color: p.borderDefault),
            Padding(
              padding: const EdgeInsets.all(Medidas.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.espacio,
                    style: Textos.mono.copyWith(color: p.textMuted),
                  ),
                  const SizedBox(height: Medidas.s8),
                  Wrap(
                    spacing: Medidas.s16,
                    runSpacing: Medidas.s8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: p.textSecondary,
                          ),
                          const SizedBox(width: Medidas.s8),
                          Flexible(
                            child: Text(
                              fechaLarga(r.inicio),
                              style: Textos.leyenda.copyWith(
                                color: p.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 18,
                            color: p.accentInk,
                          ),
                          const SizedBox(width: Medidas.s8),
                          Flexible(
                            child: Text(
                              _horario,
                              style: Textos.cuerpoFuerte.copyWith(
                                color: p.accentInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (porque != null) ...[
                    const SizedBox(height: Medidas.s8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: anulada ? p.stateDangerInk : p.textSecondary,
                        ),
                        const SizedBox(width: Medidas.s8),
                        Expanded(
                          child: Text(
                            porque,
                            style: Textos.leyenda.copyWith(
                              color: anulada
                                  ? p.stateDangerInk
                                  : p.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `Badge-Estado`.
class _Estado extends StatelessWidget {
  const _Estado({required this.estado});

  final EstadoDeReserva estado;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final (fondo, tinta) = switch (estado) {
      EstadoDeReserva.activa => (p.bgSurface, p.stateSuccessInk),
      EstadoDeReserva.anulada => (p.stateDangerMuted, p.stateDangerInk),
      _ => (p.bgSurface, p.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Medidas.s8,
        vertical: Medidas.s4,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Medidas.radioPill),
      ),
      child: Text(
        estado.name.toUpperCase(),
        style: Textos.sobretitulo.copyWith(color: tinta),
      ),
    );
  }
}
