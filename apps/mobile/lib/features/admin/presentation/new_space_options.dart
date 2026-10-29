// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/selector.dart';
import '../../../l10n/app_localizations.dart';
import '../../spaces/domain/space.dart';
import '../../venues/domain/venue.dart';
import 'new_space_form.dart';

/// Asks to choose the venue of the space among the active ones; `null` if closed without choosing.
Future<Venue?> pickVenueForNewSpace(BuildContext context, NewSpaceForm form) {
  final options = form.venueOptions ?? const <Venue>[];
  return pickOption<Venue>(
    context,
    title: AppLocalizations.of(context).adminVenue,
    options: [for (final v in options) (v, v.name)],
    selected: form.venue,
  );
}

/// Asks to choose the sport of the space; `null` if closed without choosing or there is no catalog yet.
Future<Sport?> pickSportForNewSpace(
  BuildContext context,
  NewSpaceForm form,
) async {
  final catalog = form.catalog;
  if (catalog == null) return null;
  return pickOption<Sport>(
    context,
    title: AppLocalizations.of(context).adminSport,
    options: [for (final d in catalog.sports) (d, d.name)],
    selected: form.sport,
  );
}

/// Asks to choose the court type among those of the chosen sport; `null` if closed without
/// choosing or there is no sport yet.
Future<SpaceKind?> pickTypeForNewSpace(
  BuildContext context,
  NewSpaceForm form,
) async {
  final sport = form.sport;
  if (sport == null) return null;
  return pickOption<SpaceKind>(
    context,
    title: AppLocalizations.of(context).adminType,
    options: [for (final t in sport.kinds) (t, t.name)],
    selected: form.type,
  );
}
