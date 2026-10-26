import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/dialogo_error.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tokens.dart';
import 'eleccion.dart';
import '../comun/fechas.dart';
import 'horarios.dart';
import 'reservas.dart';
import 'horario_de_cambio.dart';
import 'esqueleto_de_confirmacion.dart';
import 'fila_de_dato.dart';
import 'tarjeta_de_eleccion.dart';

/// Cómo terminó la modificación, para los horarios y Mis reservas, que quedan debajo.
enum ResultadoDeModificar {
  /// Se guardó el horario nuevo.
  modificada,

  /// El horario nuevo se ocupó o dejó de valer: se vuelve a la grilla releída.
  ocupado,

  /// La reserva ya no se puede modificar: se vuelve a Mis reservas.
  cambio,

  /// Se desistió: la reserva queda como estaba.
  desistida,
}

/// «Confirmá el cambio»: el horario de antes, el de ahora y el total nuevo, y GUARDAR EL
/// CAMBIO, que mueve la reserva.
class PantallaConfirmarCambio extends StatefulWidget {
  const PantallaConfirmarCambio({
    super.key,
    required this.reserva,
    required this.eleccion,
    required this.reservas,
    required this.sesion,
  });

  final Reserva reserva;
  final Eleccion eleccion;
  final Reservas reservas;
  final Sesion sesion;

  @override
  State<PantallaConfirmarCambio> createState() =>
      _PantallaConfirmarCambioState();
}

class _PantallaConfirmarCambioState extends State<PantallaConfirmarCambio> {
  bool _enviando = false;

  void _volver([ResultadoDeModificar? resultado]) {
    if (_enviando) return;
    if (context.canPop()) {
      context.pop(resultado);
    } else {
      context.go('/reservas');
    }
  }

  Future<void> _guardar() async {
    if (_enviando) return;
    setState(() => _enviando = true);
    Object? fallo;
    ResultadoDeModificar? cambio;
    try {
      await widget.reservas.modificar(widget.reserva, widget.eleccion);
      if (!mounted) return;
      setState(() => _enviando = false);
      _volver(ResultadoDeModificar.modificada);
      return;
    } on HorarioOcupado {
      cambio = ResultadoDeModificar.ocupado;
    } on ReservaCambiada {
      cambio = ResultadoDeModificar.cambio;
    } on CanchaNoDisponible {
      cambio = ResultadoDeModificar.cambio;
    } on ReservaRechazada catch (r) {
      if (!mounted) return;
      setState(() => _enviando = false);
      await mostrarHorarioRechazado(context, r.errores.values.first);
      if (mounted) _volver(ResultadoDeModificar.ocupado);
      return;
    } on SesionVencida {
      if (!mounted) return;
      setState(() => _enviando = false);
      await avisarSesionVencida(context, widget.sesion);
      return;
    } on FalloDeRed catch (x) {
      fallo = x;
    }
    if (!mounted) return;
    setState(() => _enviando = false);
    if (fallo != null) {
      await avisarFalloDeEnvio(
        context,
        sesion: widget.sesion,
        vencida: false,
        error: fallo,
        reintentar: _guardar,
      );
      return;
    }
    await mostrarCambioMientrasTanto(context);
    if (mounted) _volver(cambio);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = widget.reserva;
    final e = widget.eleccion;
    final antes = '${diaCorto(r.inicio)} · ${rangoDeHoras(r.inicio, r.fin)}';
    final ahora = '${diaCorto(e.fecha)} · ${e.inicio} – ${e.fin}';
    // Mientras se guarda no se sale: el cambio podría quedar hecho sin que se vea.
    return EsqueletoDeConfirmacion(
      titulo: 'Confirmá el cambio',
      enviando: _enviando,
      alVolver: _volver,
      textoPrimario: 'GUARDAR EL CAMBIO',
      alPrimario: _guardar,
      textoSecundario: 'DEJAR LA RESERVA COMO ESTÁ',
      alSecundario: () => _volver(ResultadoDeModificar.desistida),
      tarjeta: TarjetaDeEleccion(
        eleccion: e,
        filas: [
          HorarioDeCambio(titulo: 'ANTES', valor: antes, nuevo: false),
          HorarioDeCambio(titulo: 'AHORA', valor: ahora, nuevo: true),
          Divider(height: Medidas.s16, color: p.borderDefault),
          FilaDeDato(
            dato: 'Cancha',
            valor: 'Cancha ${e.cancha.numero} · ${e.cancha.condicion}',
          ),
          FilaDeDato(dato: 'Fecha', valor: fechaLarga(e.fecha)),
          const SizedBox(height: Medidas.s8),
        ],
      ),
    );
  }
}
