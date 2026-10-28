import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/top_bar.dart';
import '../../../theme/tokens.dart';
import 'booking_steps.dart';

/// La estructura común de «Confirmá…»: la barra, los pasos, la tarjeta y el pie con la
/// acción principal y la secundaria.
class ConfirmationSkeleton extends StatelessWidget {
  const ConfirmationSkeleton({
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
    final p = context.palette;
    return PopScope(
      canPop: !enviando,
      child: Scaffold(
        backgroundColor: p.bgBase,
        appBar: TopBar(title: titulo, onBack: alVolver),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: p.bgSurface,
            border: Border(top: BorderSide(color: p.borderDefault)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.s24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    label: textoPrimario,
                    onTap: alPrimario,
                    loading: enviando,
                  ),
                  const SizedBox(height: Spacing.s12),
                  OutlineButton(
                    label: textoSecundario,
                    onTap: enviando ? null : alSecundario,
                    danger: peligro,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.s24,
            Spacing.s24,
            Spacing.s24,
            Spacing.s40,
          ),
          children: [
            const BookingSteps(actual: 1),
            const SizedBox(height: Spacing.s24),
            tarjeta,
          ],
        ),
      ),
    );
  }
}
