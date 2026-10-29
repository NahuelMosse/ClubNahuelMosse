import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/selector.dart';
import '../../../common/snackbar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../domain/new_space_field.dart';
import 'field_pair.dart';
import 'generated_name.dart';
import 'new_space_form.dart';
import 'price_per_hour_field.dart';
import 'space_form_fields.dart';

/// The form for creating a space: the notice, the selectors, the price, the composed name
/// and the buttons.
class NewSpaceBody extends StatelessWidget {
  const NewSpaceBody({
    super.key,
    required this.form,
    required this.onPickVenue,
    required this.onPickSport,
    required this.onPickType,
    required this.onPickYesNo,
    required this.onRetryName,
    required this.onSave,
  });

  final NewSpaceForm form;
  final VoidCallback onPickVenue;
  final VoidCallback onPickSport;
  final VoidCallback onPickType;
  final void Function(NewSpaceField) onPickYesNo;
  final VoidCallback onRetryName;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final f = form;
    final l10n = AppLocalizations.of(context);
    final notice = f.notice;
    return SingleChildScrollView(
      padding: Spacing.formPagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (notice != null) ...[
            ErrorSnackbar(
              key: f.noticeKey,
              message: notice,
              onClose: f.closeNotice,
            ),
            const SizedBox(height: Spacing.s16),
          ],
          ...spaceFormHeading(context, l10n.adminNewSpaceHeading),
          ..._selectors(l10n),
          PricePerHourField(
            controller: f.price,
            error: f.error(NewSpaceField.price, l10n),
            enabled: !f.submitting && !f.loading,
          ),
          const SizedBox(height: Spacing.s16),
          GeneratedName(
            name: f.suggested?.$1,
            computing: f.computing,
            missing: nameMissingText(l10n, f.missingForName),
            onRetry: f.nameFailure == null || f.submitting ? null : onRetryName,
          ),
          const SizedBox(height: Spacing.s16),
          PrimaryButton(
            label: l10n.adminSaveSpace,
            loading: f.submitting,
            dimmed: !f.isComplete,
            onTap: onSave,
          ),
          const SizedBox(height: Spacing.s12),
          OutlineButton(
            label: l10n.adminCancel,
            onTap: f.submitting ? null : () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  List<Widget> _selectors(AppLocalizations l10n) {
    final f = form;
    final venues = f.venueOptions;
    final enabled = !f.submitting && !f.loading;
    return [
      SelectorField(
        label: l10n.adminVenueUpper,
        semanticLabel: l10n.adminVenue,
        value: f.venue?.name,
        placeholder: venues == null || venues.isNotEmpty
            ? l10n.adminSelectVenue
            : l10n.adminNoVenues,
        icon: Icons.expand_more_rounded,
        error: f.error(NewSpaceField.venue, l10n),
        onTap: enabled && (venues?.isNotEmpty ?? false) ? onPickVenue : null,
      ),
      const SizedBox(height: Spacing.s12),
      SelectorField(
        label: l10n.adminSportUpper,
        semanticLabel: l10n.adminSport,
        value: f.sport?.name,
        placeholder: l10n.adminSelectSport,
        icon: Icons.expand_more_rounded,
        error: f.error(NewSpaceField.sport, l10n),
        onTap: enabled ? onPickSport : null,
      ),
      const SizedBox(height: Spacing.s12),
      SelectorField(
        label: l10n.adminTypeUpper,
        semanticLabel: l10n.adminType,
        value: f.type?.name,
        placeholder: l10n.adminSelectType,
        icon: Icons.expand_more_rounded,
        error: f.error(NewSpaceField.type, l10n),
        onTap: enabled && f.sport != null ? onPickType : null,
      ),
      const SizedBox(height: Spacing.s12),
      FieldPair(
        left: SelectorField(
          label: l10n.adminConditionUpper,
          semanticLabel: l10n.adminCondition,
          value: switch (f.roofed) {
            true => l10n.adminCovered,
            false => l10n.adminOpenAir,
            null => null,
          },
          placeholder: l10n.adminSelect,
          icon: Icons.expand_more_rounded,
          error: f.error(NewSpaceField.roofing, l10n),
          onTap: enabled ? () => onPickYesNo(NewSpaceField.roofing) : null,
        ),
        right: SelectorField(
          label: l10n.adminLightingUpper,
          semanticLabel: l10n.adminLighting,
          value: switch (f.lit) {
            true => l10n.adminLit,
            false => l10n.adminUnlit,
            null => null,
          },
          placeholder: l10n.adminSelect,
          icon: Icons.expand_more_rounded,
          error: f.error(NewSpaceField.lighting, l10n),
          onTap: enabled ? () => onPickYesNo(NewSpaceField.lighting) : null,
        ),
      ),
      const SizedBox(height: Spacing.s12),
    ];
  }
}
