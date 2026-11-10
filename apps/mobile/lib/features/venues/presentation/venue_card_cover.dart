import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/venue.dart';
import 'photos.dart';
import 'venue_space_count.dart';
import 'venue_texts.dart';

/// The cover of the venue with its number of courts, the name, the address and the
/// schedule.
class VenueCardCover extends StatelessWidget {
  const VenueCardCover({super.key, required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return ConstrainedBox(
      // A long name goes onto two lines and the cover grows with it.
      constraints: const BoxConstraints(minHeight: 158),
      child: PhotoWithScrim(
        image: venueCover(venue.id),
        child: Stack(
          children: [
            Positioned(
              top: Spacing.s12,
              right: Spacing.s16,
              child: VenueSpaceCount(count: venue.spaceCount),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.s16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venue.name.toUpperCase(),
                          style: Texts.h1.copyWith(color: p.textOnMedia),
                        ),
                        const SizedBox(height: Spacing.s4),
                        Text(
                          venue.address,
                          style: Texts.caption.copyWith(
                            color: p.textOnMediaMuted,
                          ),
                        ),
                        Text(
                          // The range is not split between lines.
                          l.venueDaysHours(
                            venue.closing,
                            weekdaysText(l, venue.daysLabel),
                            venue.opening,
                          ),
                          style: Texts.caption.copyWith(
                            fontSize: 12,
                            color: p.textOnMediaMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
