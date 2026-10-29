import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/in_progress.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import 'venue_form.dart';

/// The buttons at the foot of a venue form: save and, when editing, deactivate.
class VenueFormButtons extends StatelessWidget {
  const VenueFormButtons({
    super.key,
    required this.form,
    required this.onSave,
    required this.onDeactivate,
  });

  final VenueForm form;
  final VoidCallback onSave;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final f = form;
    final l10n = AppLocalizations.of(context);
    if (!f.isEditing) {
      return PrimaryButton(
        label: l10n.adminSaveVenue,
        loading: f.submitting,
        dimmed: !f.isComplete,
        onTap: onSave,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          label: l10n.adminSaveChanges,
          loading: f.submitting,
          dimmed: !f.isComplete,
          onTap: f.deactivating ? null : onSave,
        ),
        const SizedBox(height: Spacing.s12),
        if (f.deactivating)
          InProgress(l10n.adminDeactivatingVenue)
        else
          OutlineButton(
            label: l10n.adminDeactivateVenueButton,
            danger: true,
            onTap: f.submitting ? null : onDeactivate,
          ),
      ],
    );
  }
}
