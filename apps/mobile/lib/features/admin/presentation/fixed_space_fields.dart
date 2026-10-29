// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import 'read_only_field.dart';

/// The venue, sport and type of [space], shown but unchangeable; the sport and type by
/// name if there is a [catalog], otherwise by key.
List<Widget> fixedSpaceFields(
  BuildContext context,
  Space space,
  Catalog? catalog,
) {
  final l10n = AppLocalizations.of(context);
  final sport = catalog?.sport(space.sport)?.name ?? space.sport;
  final type = catalog?.shortKind(space.sport, space.kind) ?? space.kind;
  return [
    ReadOnlyField(
      label: l10n.adminVenueUpper,
      semanticLabel: l10n.adminVenue,
      value: space.venue,
    ),
    const SizedBox(height: Spacing.s12),
    ReadOnlyField(
      label: l10n.adminSportUpper,
      semanticLabel: l10n.adminSport,
      value: sport,
    ),
    const SizedBox(height: Spacing.s12),
    ReadOnlyField(
      label: l10n.adminTypeUpper,
      semanticLabel: l10n.adminType,
      value: type,
    ),
    const SizedBox(height: Spacing.s12),
  ];
}
