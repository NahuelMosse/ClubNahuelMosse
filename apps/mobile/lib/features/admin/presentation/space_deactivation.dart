// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../session/presentation/session.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/domain/space_exceptions.dart';
import '../../spaces/presentation/spaces.dart';
import 'deactivation.dart';
import 'deactivation_dialogs.dart';

/// Confirms and deactivates [space] (CU-23). With [returnToList] (it was reached from
/// editing), it ends at the panel's space list.
Future<void> deactivateSpace(
  BuildContext context, {
  required Space space,
  required Spaces spaces,
  required Session session,
  required ValueChanged<bool> submitting,
  bool returnToList = false,
}) {
  final l10n = AppLocalizations.of(context);
  return deactivate(
  context,
  confirm: () => confirmSpaceDeactivation(context, space.name),
  request: () async {
    try {
      await spaces.deactivate(space.id);
      return DeactivationResult.done;
    } on SpaceUnavailable {
      return DeactivationResult.gone;
    } on SpaceHasBookings {
      return DeactivationResult.withBookings;
    }
  },
  showWithBookings: () => showSpaceWithBookings(context),
  success: l10n.adminSpaceDeactivatedDone,
  notifyChange: spaces.notifyChange,
  session: session,
  submitting: submitting,
  returnTo: returnToList ? '/admin/espacios' : null,
  );
}
