import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/barra_superior.dart';
import '../comun/boton.dart';
import '../comun/formato_precio.dart';
import '../sedes/fotos.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'eleccion.dart';
import 'fechas.dart';

/// «Confirmá tu reserva»: la cancha, la fecha, el horario y el total que se eligieron.
class PantallaConfirmarReserva extends StatelessWidget {
  const PantallaConfirmarReserva({super.key, required this.eleccion});

  final Eleccion eleccion;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    const foto = Paleta.oscura;
    final e = eleccion;
    // Vuelve a los horarios tal como quedaron; sin nada debajo, a la sede.
    void volver() =>
        context.canPop() ? context.pop() : context.go('/sedes/${e.sede.id}');
    return Scaffold(
      backgroundColor: p.bgBase,
      appBar: BarraSuperior(titulo: 'Confirmá tu reserva', alVolver: volver),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: p.bgSurface,
          border: Border(top: BorderSide(color: p.borderDefault)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Medidas.s24),
            child: BotonContorno(texto: 'CANCELAR', alTocar: volver),
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
          const _Pasos(actual: 1),
          const SizedBox(height: Medidas.s24),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: p.bgSurfaceRaised,
              borderRadius: BorderRadius.circular(Medidas.radioLg),
              border: Border.all(color: p.borderDefault),
            ),
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
                      _Fila(
                        dato: 'Cancha',
                        valor:
                            'Cancha ${e.cancha.numero} · ${e.cancha.condicion}',
                      ),
                      _Fila(dato: 'Fecha', valor: fechaLarga(e.fecha)),
                      _Fila(dato: 'Horario', valor: e.horario, destacado: true),
                      const SizedBox(height: Medidas.s8),
                      Divider(height: 1, color: p.borderDefault),
                      const SizedBox(height: Medidas.s16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'TOTAL',
                              style: Textos.sobretitulo.copyWith(
                                color: p.textMuted,
                              ),
                            ),
                          ),
                          Text(
                            pesos(e.total),
                            style: Textos.h1.copyWith(color: p.accentInk),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.dato,
    required this.valor,
    this.destacado = false,
  });

  final String dato;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
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

/// Los tres pasos de la reserva, con [actual] contado desde cero.
class _Pasos extends StatelessWidget {
  const _Pasos({required this.actual});

  final int actual;

  static const _nombres = ['Elegí cancha', 'Confirmás', '¡Listo!'];

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      label: 'Paso ${actual + 1} de ${_nombres.length}: ${_nombres[actual]}',
      excludeSemantics: true,
      child: Row(
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
