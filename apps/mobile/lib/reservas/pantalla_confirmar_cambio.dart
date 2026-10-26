import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/dialogo_error.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'eleccion.dart';
import '../comun/fechas.dart';
import 'horarios.dart';
import 'pantalla_confirmar_reserva.dart';
import 'reservas.dart';

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
    } on SinConexion catch (x) {
      fallo = x;
    } on ErrorDelServidor catch (x) {
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
          _Horario(titulo: 'ANTES', valor: antes, nuevo: false),
          _Horario(titulo: 'AHORA', valor: ahora, nuevo: true),
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

/// El horario de antes, con una cruz, o el de ahora, con un tilde y en lima.
class _Horario extends StatelessWidget {
  const _Horario({
    required this.titulo,
    required this.valor,
    required this.nuevo,
  });

  final String titulo;
  final String valor;
  final bool nuevo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      container: true,
      label: '$titulo: $valor',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Medidas.s8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              nuevo ? Icons.check_rounded : Icons.close_rounded,
              size: 18,
              color: nuevo ? p.stateSuccessInk : p.stateDangerInk,
            ),
            const SizedBox(width: Medidas.s8),
            Text(
              titulo,
              style: Textos.sobretitulo.copyWith(color: p.textMuted),
            ),
            const SizedBox(width: Medidas.s16),
            Expanded(
              child: Text(
                valor,
                textAlign: TextAlign.end,
                style: nuevo
                    ? Textos.cuerpoFuerte.copyWith(color: p.accentInk)
                    : Textos.cuerpo.copyWith(color: p.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
