import 'package:flutter/material.dart';

import '../../../common/empty_state.dart';
import '../../../theme/tokens.dart';

/// The sliver of the history without bookings: no results for the filters, or no bookings.
class AdminBookingsEmpty extends StatelessWidget {
  const AdminBookingsEmpty({
    super.key,
    required this.hasFilters,
    required this.onClearFilters,
  });

  final bool hasFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
      sliver: SliverToBoxAdapter(
        child: hasFilters
            ? EmptyState(
                title: 'Sin resultados',
                text:
                    'Ninguna reserva coincide con los filtros '
                    'aplicados.',
                action: 'LIMPIAR FILTROS',
                onTap: onClearFilters,
              )
            : const EmptyState(
                title: 'No hay reservas',
                text:
                    'Todavía no se registró ninguna reserva en '
                    'el sistema.',
              ),
      ),
    );
  }
}
