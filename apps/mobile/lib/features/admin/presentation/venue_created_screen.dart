// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../venues/domain/venue.dart';

/// The creation success: the venue that was saved, and back to the list or create another.
class VenueCreatedScreen extends StatelessWidget {
  const VenueCreatedScreen({super.key, required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ResultScreen(
      icon: Icons.check_circle_outline_rounded,
      tone: ResultTone.success,
      title: l10n.adminVenueCreatedTitle,
      text: l10n.adminVenueCreatedText,
      detail: '${venue.name} · ${venue.address}',
      primary: l10n.adminGoToList,
      onPrimaryTap: () => context.go('/admin/sedes'),
      secondary: l10n.adminCreateAnotherVenue,
      onSecondaryTap: () => context.go('/admin/sedes/nueva'),
    );
  }
}
