import 'package:flutter/material.dart';

import '../../../common/date_format.dart';
import '../../../common/text_field.dart';
import '../../../theme/tokens.dart';

/// The «Desde» and «Hasta» fields of the filter panel: side by side, or stacked if they do not fit.
class FilterDateRange extends StatelessWidget {
  const FilterDateRange({
    super.key,
    required this.since,
    required this.until,
    required this.invalidSince,
    required this.invalidUntil,
    required this.invalidRange,
  });

  final TextEditingController since;
  final TextEditingController until;

  /// There is text in the field and it is not a date that exists.
  final bool invalidSince;
  final bool invalidUntil;

  /// «Desde» is later than «Hasta».
  final bool invalidRange;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, box) {
        final sinceField = FormTextField(
          label: 'Desde',
          semanticLabel: 'Desde',
          placeholder: 'DD / MM / AAAA',
          controller: since,
          keyboardType: TextInputType.number,
          inputFormatters: const [DateInputFormatter()],
          trailing: Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: p.textMuted,
          ),
          error: invalidSince
              ? 'Fecha inválida'
              : invalidRange
              ? 'Desde no puede ser posterior a Hasta'
              : null,
        );
        final untilField = FormTextField(
          label: 'Hasta',
          semanticLabel: 'Hasta',
          placeholder: 'DD / MM / AAAA',
          controller: until,
          keyboardType: TextInputType.number,
          inputFormatters: const [DateInputFormatter()],
          trailing: Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: p.textMuted,
          ),
          error: invalidUntil
              ? 'Fecha inválida'
              : invalidRange
              ? (box.maxWidth < 330
                    ? 'Hasta no puede ser anterior a Desde'
                    : ' ')
              : null,
        );
        if (box.maxWidth < 330) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sinceField,
              const SizedBox(height: Spacing.s12),
              untilField,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: sinceField),
            const SizedBox(width: Spacing.s12),
            Expanded(child: untilField),
          ],
        );
      },
    );
  }
}
