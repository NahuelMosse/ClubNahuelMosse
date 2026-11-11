// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import '../../../theme/tokens.dart';
import '../../venues/domain/venue.dart';
import '../../venues/presentation/cover_with_title.dart';
import '../../venues/presentation/photos.dart';

/// The photo of the sport with the way back, the type and the venue.
class AvailabilityCover extends StatelessWidget {
  const AvailabilityCover({
    super.key,
    required this.venue,
    required this.kind,
    required this.sport,
    required this.backLabel,
    required this.onBack,
  });

  final Venue venue;
  final String kind;
  final String sport;

  /// The name of the screen it goes back to.
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return CoverWithTitle(
      image: sportPhoto(sport),
      backTo: backLabel,
      onBack: onBack,
      gap: Spacing.s32,
      overline: kind,
      name: venue.name,
    );
  }
}
