import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// The detail bar: the back arrow and the title. A `null` [onBack] disables it.
class BookingDetailHeader extends StatelessWidget {
  const BookingDetailHeader({super.key, required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.s8,
        Spacing.s16,
        Spacing.s24,
        Spacing.s8,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back_rounded),
            color: p.textPrimary,
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                'Detalle de reserva',
                style: Texts.h2.copyWith(color: p.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
