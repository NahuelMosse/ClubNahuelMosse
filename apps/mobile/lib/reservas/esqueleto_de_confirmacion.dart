import 'package:flutter/material.dart';
import '../comun/barra_superior.dart';
import '../comun/boton.dart';
import '../tema/tokens.dart';
import 'pasos_de_reserva.dart';

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
