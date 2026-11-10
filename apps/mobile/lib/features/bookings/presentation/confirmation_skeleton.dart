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
    required this.title,
    required this.sending,
    required this.onBack,
    required this.primaryText,
    required this.onPrimary,
    required this.secondaryText,
    required this.onSecondary,
    required this.card,
    this.danger = false,
  });

  final String title;
  final bool sending;
  final VoidCallback onBack;
  final String primaryText;
  final VoidCallback onPrimary;
  final String secondaryText;
  final VoidCallback onSecondary;
  final bool danger;
  final Widget card;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PopScope(
      canPop: !sending,
      child: Scaffold(
        backgroundColor: p.bgBase,
        appBar: TopBar(title: title, onBack: onBack),
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
                    label: primaryText,
                    onTap: onPrimary,
                    loading: sending,
                  ),
                  const SizedBox(height: Spacing.s12),
                  OutlineButton(
                    label: secondaryText,
                    onTap: sending ? null : onSecondary,
                    danger: danger,
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
            card,
          ],
        ),
      ),
    );
  }
}
