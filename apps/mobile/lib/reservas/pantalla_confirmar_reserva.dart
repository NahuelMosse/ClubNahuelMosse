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
import '../comun/reserva_pendiente.dart';
import 'reservas.dart';
import 'esqueleto_de_confirmacion.dart';
import 'tarjeta_de_eleccion.dart';
import 'fila_de_dato.dart';

/// Lo que la confirmación le devuelve a los horarios al cerrarse: si el horario se ocupó,
/// la grilla se vuelve a leer.
enum ResultadoDeConfirmar { ocupado }

/// «Confirmá tu reserva»: la cancha, la fecha, el horario y el total que se eligieron, y
/// CONFIRMAR RESERVA, que la guarda.
class PantallaConfirmarReserva extends StatefulWidget {
  const PantallaConfirmarReserva({
    super.key,
    required this.eleccion,
    required this.reservas,
    required this.pendiente,
    required this.sesion,
  });

  final Eleccion eleccion;
  final Reservas reservas;
  final ReservaPendiente<Eleccion> pendiente;
  final Sesion sesion;

  @override
  State<PantallaConfirmarReserva> createState() =>
      _PantallaConfirmarReservaState();
}

class _PantallaConfirmarReservaState extends State<PantallaConfirmarReserva> {
  bool _enviando = false;

  /// Vuelve a los horarios tal como quedaron. Sin nada debajo (se llegó al volver a
  /// iniciar sesión), a los horarios de esa cancha si hay que elegir otro, o a la sede.
  void _volver([ResultadoDeConfirmar? resultado]) {
    if (_enviando) return;
    final e = widget.eleccion;
    if (context.canPop()) {
      context.pop(resultado);
    } else if (resultado == ResultadoDeConfirmar.ocupado) {
      context.go('/sedes/${e.sede.id}/canchas/${e.cancha.id}');
    } else {
      context.go('/sedes/${e.sede.id}');
    }
  }

  Future<void> _confirmar() async {
    if (_enviando) return;
    setState(() => _enviando = true);
    final e = widget.eleccion;
    Object? fallo;
    try {
      final reserva = await widget.reservas.reservar(e);
      if (mounted) context.go('/reservas/confirmada', extra: reserva);
      return;
    } on HorarioOcupado {
      if (!mounted) return;
      setState(() => _enviando = false);
      await mostrarHorarioOcupado(
        context,
        'Mientras confirmabas, otra persona reservó Cancha ${e.cancha.numero} · '
        '${diaCorto(e.fecha)}, ${e.inicio} – ${e.fin}. '
        'Elegí otro horario disponible.',
      );
      if (mounted) _volver(ResultadoDeConfirmar.ocupado);
      return;
    } on CanchaNoDisponible {
      if (!mounted) return;
      setState(() => _enviando = false);
      await mostrarCambioMientrasTanto(context);
      if (!mounted) return;
      context.go('/sedes/${e.sede.id}');
      return;
    } on ReservaRechazada catch (r) {
      if (!mounted) return;
      setState(() => _enviando = false);
      await mostrarHorarioRechazado(context, r.errores.values.first);
      if (mounted) _volver(ResultadoDeConfirmar.ocupado);
      return;
    } on SesionVencida {
      final correo = widget.sesion.perfil?.correo;
      if (correo != null) widget.pendiente.guardar(e, correo);
      if (!mounted) return;
      setState(() => _enviando = false);
      await avisarSesionVencida(context, widget.sesion);
      return;
    } on SinConexion catch (x) {
      fallo = x;
    } on ErrorDelServidor catch (x) {
      fallo = x;
    }
    if (!mounted) return;
    setState(() => _enviando = false);
    await avisarFalloDeEnvio(
      context,
      sesion: widget.sesion,
      vencida: false,
      error: fallo,
      reintentar: _confirmar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.eleccion;
    // Mientras se guarda no se sale: la reserva podría quedar hecha sin comprobante.
    return EsqueletoDeConfirmacion(
      titulo: 'Confirmá tu reserva',
      enviando: _enviando,
      alVolver: _volver,
      textoPrimario: 'CONFIRMAR RESERVA',
      alPrimario: _confirmar,
      textoSecundario: 'CANCELAR',
      alSecundario: _volver,
      peligro: true,
      tarjeta: TarjetaDeEleccion(
        eleccion: e,
        filas: [
          FilaDeDato(
            dato: 'Cancha',
            valor: 'Cancha ${e.cancha.numero} · ${e.cancha.condicion}',
          ),
          FilaDeDato(dato: 'Fecha', valor: fechaLarga(e.fecha)),
          FilaDeDato(dato: 'Horario', valor: e.horario, destacado: true),
          const SizedBox(height: Medidas.s8),
        ],
      ),
    );
  }
}
