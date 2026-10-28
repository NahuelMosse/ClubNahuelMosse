import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/text_field.dart';
import '../../../theme/tokens.dart';

/// The history search field and the button that opens the filters.
class BookingSearch extends StatelessWidget {
  const BookingSearch({
    super.key,
    required this.controller,
    required this.onOpenFilters,
  });

  final TextEditingController controller;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: FormTextField(
            semanticLabel: 'Buscar reserva',
            // With the Filtros button next to it, «Buscar reserva» does not fit whole at 360.
            placeholder: MediaQuery.sizeOf(context).width < 400
                ? 'Buscar'
                : 'Buscar reserva',
            controller: controller,
            trailing: Icon(Icons.search_rounded, color: p.textMuted),
          ),
        ),
        const SizedBox(width: Spacing.s8),
        Flexible(
          child: OutlineButton(
            label: 'Filtros',
            icon: Icons.tune_rounded,
            compact: true,
            expand: false,
            onTap: onOpenFilters,
          ),
        ),
      ],
    );
  }
}
