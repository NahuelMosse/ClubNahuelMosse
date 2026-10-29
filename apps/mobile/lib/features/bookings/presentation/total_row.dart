import 'package:flutter/material.dart';
import '../../../common/price_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// TOTAL y el monto en lima.
class TotalRow extends StatelessWidget {
  const TotalRow({super.key, required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Spacing.s8,
      children: [
        Text(
          AppLocalizations.of(context).bookingTotal,
          style: Texts.overline.copyWith(color: p.textMuted),
        ),
        Text(formatPesos(total), style: Texts.h1.copyWith(color: p.accentInk)),
      ],
    );
  }
}
