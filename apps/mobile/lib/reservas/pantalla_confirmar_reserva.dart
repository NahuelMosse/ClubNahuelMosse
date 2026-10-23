import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_superior.dart';
import '../comun/boton.dart';
import '../comun/dialogo_error.dart';
import '../comun/formato_precio.dart';
import '../comun/marco_de_tarjeta.dart';
import '../sedes/fotos.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'eleccion.dart';
import 'fechas.dart';
import 'horarios.dart';
import '../comun/reserva_pendiente.dart';
import 'reservas.dart';

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
        '${fechaLarga(e.fecha).split(' de ').first}, ${e.inicio} – ${e.fin}. '
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
      avisarReservaRechazada(context, r);
      _volver(ResultadoDeConfirmar.ocupado);
      return;
    } on SesionVencida {
      final correo = widget.sesion.perfil?.correo;
      if (correo != null) widget.pendiente.guardar(e, correo);
      if (!mounted) return;
      setState(() => _enviando = false);
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
      return;
    } on SinConexion catch (x) {
      fallo = x;
    } on ErrorDelServidor catch (x) {
      fallo = x;
    }
    if (!mounted) return;
    setState(() => _enviando = false);
    final reintentar = await mostrarErrorDeRed(context, fallo);
    if (reintentar && mounted) await _confirmar();
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

/// Avisa con un snackbar que el horario dejó de valer mientras se confirmaba
/// (por ejemplo, ya empezó).
void avisarReservaRechazada(BuildContext context, ReservaRechazada r) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(r.errores.values.first)));
}

/// La estructura común de «Confirmá…»: la barra, los pasos, la tarjeta y el pie con la
/// acción principal y la secundaria.
class EsqueletoDeConfirmacion extends StatelessWidget {
  const EsqueletoDeConfirmacion({
    super.key,
    required this.titulo,
    required this.enviando,
    required this.alVolver,
    required this.textoPrimario,
    required this.alPrimario,
    required this.textoSecundario,
    required this.alSecundario,
    required this.tarjeta,
    this.peligro = false,
  });

  final String titulo;
  final bool enviando;
  final VoidCallback alVolver;
  final String textoPrimario;
  final VoidCallback alPrimario;
  final String textoSecundario;
  final VoidCallback alSecundario;
  final bool peligro;
  final Widget tarjeta;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return PopScope(
      canPop: !enviando,
      child: Scaffold(
        backgroundColor: p.bgBase,
        appBar: BarraSuperior(titulo: titulo, alVolver: alVolver),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: p.bgSurface,
            border: Border(top: BorderSide(color: p.borderDefault)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(Medidas.s24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BotonPrimario(
                    texto: textoPrimario,
                    alTocar: alPrimario,
                    cargando: enviando,
                  ),
                  const SizedBox(height: Medidas.s12),
                  BotonContorno(
                    texto: textoSecundario,
                    alTocar: enviando ? null : alSecundario,
                    peligro: peligro,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s24,
            Medidas.s24,
            Medidas.s40,
          ),
          children: [
            const PasosDeReserva(actual: 1),
            const SizedBox(height: Medidas.s24),
            tarjeta,
          ],
        ),
      ),
    );
  }
}

/// La tarjeta de la elección: la foto con el tipo y la sede, las [filas] y el total.
class TarjetaDeEleccion extends StatelessWidget {
  const TarjetaDeEleccion({
    super.key,
    required this.eleccion,
    required this.filas,
  });

  final Eleccion eleccion;
  final List<Widget> filas;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    const foto = Paleta.oscura;
    final e = eleccion;
    return MarcoDeTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: FotoConVelo(
              imagen: fotoDeDeporte(e.cancha.deporte),
              child: Padding(
                padding: const EdgeInsets.all(Medidas.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.tipo,
                      style: Textos.sobretitulo.copyWith(
                        color: foto.accentBase,
                      ),
                    ),
                    Text(
                      e.sede.nombre.toUpperCase(),
                      style: Textos.h2.copyWith(color: foto.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Medidas.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...filas,
                Divider(height: 1, color: p.borderDefault),
                const SizedBox(height: Medidas.s16),
                FilaDeTotal(total: e.total),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Un dato de la reserva: el nombre a la izquierda y el valor a la derecha.
class FilaDeDato extends StatelessWidget {
  const FilaDeDato({
    super.key,
    required this.dato,
    required this.valor,
    this.destacado = false,
    this.codigo = false,
  });

  final String dato;
  final String valor;
  final bool destacado;

  /// Un código largo sin espacios (el nombre compuesto del espacio): va debajo del dato,
  /// en la fuente mono, para no partirse a mitad de palabra.
  final bool codigo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    if (codigo) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Medidas.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dato, style: Textos.cuerpo.copyWith(color: p.textSecondary)),
            const SizedBox(height: Medidas.s4),
            Text(valor, style: Textos.mono.copyWith(color: p.textPrimary)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Medidas.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dato, style: Textos.cuerpo.copyWith(color: p.textSecondary)),
          const SizedBox(width: Medidas.s16),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: (destacado ? Textos.cuerpoFuerte : Textos.cuerpo).copyWith(
                color: destacado ? p.accentInk : p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// TOTAL y el monto en lima.
class FilaDeTotal extends StatelessWidget {
  const FilaDeTotal({super.key, required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Medidas.s8,
      children: [
        Text('TOTAL', style: Textos.sobretitulo.copyWith(color: p.textMuted)),
        Text(pesos(total), style: Textos.h1.copyWith(color: p.accentInk)),
      ],
    );
  }
}

/// Los tres pasos de la reserva, con [actual] contado desde cero.
class PasosDeReserva extends StatelessWidget {
  const PasosDeReserva({super.key, required this.actual});

  final int actual;

  static const _nombres = ['Elegí cancha', 'Confirmás', '¡Listo!'];

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      label: 'Paso ${actual + 1} de ${_nombres.length}: ${_nombres[actual]}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _nombres.length; i++) ...[
            if (i > 0) const SizedBox(width: Medidas.s8),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= actual ? p.accentBase : p.bgSurfaceRaised,
                      borderRadius: BorderRadius.circular(Medidas.radioPill),
                    ),
                  ),
                  const SizedBox(height: Medidas.s8),
                  Text(
                    _nombres[i],
                    textAlign: TextAlign.center,
                    style: Textos.leyenda.copyWith(
                      color: i == actual ? p.textPrimary : p.textMuted,
                      fontWeight: i == actual ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
