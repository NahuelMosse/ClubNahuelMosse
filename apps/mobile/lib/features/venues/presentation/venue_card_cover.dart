import 'package:flutter/material.dart';

import '../../../common/bib.dart';
import '../../../common/dates.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/venue.dart';
import 'photos.dart';
import 'venue_texts.dart';

/// La portada de la sede con su cantidad de canchas, el nombre, la dirección y el horario.
class VenueCardCover extends StatelessWidget {
  const VenueCardCover({super.key, required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return ConstrainedBox(
      // Un nombre largo pasa a dos líneas y la portada crece con él.
      constraints: const BoxConstraints(minHeight: 158),
      child: PhotoWithScrim(
        image: venueCover(venue.id),
        child: Stack(
          children: [
            Positioned(
              top: Spacing.s12,
              right: Spacing.s16,
              child: _SpaceCount(count: venue.spaceCount),
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
                          // El rango no se parte entre líneas.
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

/// The giant number of courts with its noun under it.
class _SpaceCount extends StatelessWidget {
  const _SpaceCount({required this.count});

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
