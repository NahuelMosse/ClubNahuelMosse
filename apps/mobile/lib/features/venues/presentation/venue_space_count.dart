import 'package:flutter/material.dart';

import '../../../common/bib.dart';
import '../../../common/dates.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

/// The giant number of courts with its noun under it.
class VenueSpaceCount extends StatelessWidget {
  const VenueSpaceCount({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GiantBib(text: twoDigits(count), size: 92, color: p.textOnMedia),
        Text(
          // The number is the giant bib above: only the noun is left.
          AppLocalizations.of(context)
              .venueSpaceCount(count)
              .replaceFirst(RegExp(r'^\d+\s*'), '')
              .toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 11 * 0.08,
            color: p.textOnMedia,
          ),
        ),
      ],
    );
  }
}
