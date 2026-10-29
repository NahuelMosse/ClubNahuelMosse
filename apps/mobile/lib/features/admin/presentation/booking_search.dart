import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/text_field.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: FormTextField(
            semanticLabel: l10n.adminSearchBooking,
            // With the Filters button next to it, the whole text does not fit at 360.
            placeholder: MediaQuery.sizeOf(context).width < 400
                ? l10n.adminSearchShort
                : l10n.adminSearchBooking,
            controller: controller,
            trailing: Icon(Icons.search_rounded, color: p.textMuted),
          ),
        ),
        const SizedBox(width: Spacing.s8),
        Flexible(
          child: OutlineButton(
            label: l10n.adminFilters,
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
