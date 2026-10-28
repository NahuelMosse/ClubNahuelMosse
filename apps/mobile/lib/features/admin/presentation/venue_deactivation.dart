// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../session/presentation/session.dart';
import '../../venues/domain/venue.dart';
import '../../venues/domain/venue_exceptions.dart';
import '../../venues/presentation/venues.dart';
import 'deactivation.dart';
import 'deactivation_dialogs.dart';

/// Confirms and deactivates [venue] and its spaces (CU-19). With [returnToList] (it was
/// reached from editing), it ends at the panel's venue list.
Future<void> deactivateVenue(
  BuildContext context, {
  required Venue venue,
  required Venues venues,
  required Session session,
  required ValueChanged<bool> submitting,
  bool returnToList = false,
}) => deactivate(
  context,
  confirm: () => confirmVenueDeactivation(
    context,
    '${venue.name} · ${venue.address}. Sus espacios deportivos dejan de '
    'estar disponibles.',
  ),
  request: () async {
    try {
      await venues.deactivate(venue.id);
      return DeactivationResult.done;
    } on VenueUnavailable {
      return DeactivationResult.gone;
    } on VenueHasBookings {
      return DeactivationResult.withBookings;
    }
  },
  showWithBookings: () => showVenueWithBookings(context),
  success: 'La sede fue dada de baja correctamente',
  notifyChange: venues.notifyChange,
  session: session,
  submitting: submitting,
  returnTo: returnToList ? '/admin/sedes' : null,
);
