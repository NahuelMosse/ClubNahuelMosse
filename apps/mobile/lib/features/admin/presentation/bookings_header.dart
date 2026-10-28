import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../bookings/domain/booking_status.dart';
import '../../session/presentation/session.dart';
import '../domain/history_filters.dart';
import '../domain/history_page.dart';
import 'admin_header.dart';
import 'admin_tab_bar.dart';
import 'booking_search.dart';

/// The top sliver of the history: title, search, tabs by status and the total.
class BookingsHeader extends StatelessWidget {
  const BookingsHeader({
    super.key,
    required this.session,
    required this.search,
    required this.filters,
    required this.result,
    required this.onOpenFilters,
    required this.onSelectStatus,
    required this.onClearFilters,
  });

  final Session session;
  final TextEditingController search;
  final HistoryFilters filters;
  final HistoryPage? result;
  final VoidCallback onOpenFilters;
  final ValueChanged<BookingStatus?> onSelectStatus;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final result = this.result;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.s24,
        Spacing.s24,
        Spacing.s16,
        0,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminHeader(title: 'Reservas', session: session),
            const SizedBox(height: Spacing.s16),
            BookingSearch(controller: search, onOpenFilters: onOpenFilters),
            const SizedBox(height: Spacing.s16),
            AdminTabBar(
              selected: filters.status,
              counters: result?.counters,
              onSelect: onSelectStatus,
            ),
            const SizedBox(height: Spacing.s12),
            if (result != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      filters.hasFilters
                          ? '${result.total} '
                                '${result.total == 1 ? 'RESULTADO' : 'RESULTADOS'}'
                          : '${result.total} '
                                '${result.total == 1 ? 'RESERVA EN TOTAL' : 'RESERVAS EN TOTAL'}',
                      style: Texts.overline.copyWith(color: p.textMuted),
                    ),
                  ),
                  // With zero results, «Limpiar filtros» is already in the empty
                  // state below: the button is not duplicated.
                  if (filters.hasFilters && result.total > 0)
                    TextActionButton(
                      label: 'LIMPIAR FILTROS',
                      onTap: onClearFilters,
                    ),
                ],
              ),
            const SizedBox(height: Spacing.s8),
          ],
        ),
      ),
    );
  }
}
