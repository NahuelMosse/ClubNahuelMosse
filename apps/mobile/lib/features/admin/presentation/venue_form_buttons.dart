import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/in_progress.dart';
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
    if (!f.isEditing) {
      return PrimaryButton(
        label: 'GUARDAR SEDE',
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
          label: 'GUARDAR CAMBIOS',
          loading: f.submitting,
          dimmed: !f.isComplete,
          onTap: f.deactivating ? null : onSave,
        ),
        const SizedBox(height: Spacing.s12),
        if (f.deactivating)
          const InProgress('Dando de baja la sede')
        else
          OutlineButton(
            label: 'DAR DE BAJA LA SEDE',
            danger: true,
            onTap: f.submitting ? null : onDeactivate,
          ),
      ],
    );
  }
}
