// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/dates.dart';
import '../../../common/selector.dart';
import '../../../common/text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../venues/domain/venue.dart';
import '../../venues/presentation/venue_texts.dart';
import '../domain/venue_field.dart';
import '../domain/venue_rules.dart';
import 'venue_form.dart';

/// The fields of a venue form: name, address, opening, closing and days.
class VenueFormBody extends StatelessWidget {
  const VenueFormBody({
    super.key,
    required this.form,
    required this.onPickHour,
    required this.onPickDays,
  });

  final VenueForm form;
  final void Function(VenueField) onPickHour;
  final VoidCallback onPickDays;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final f = form;
    final editing = f.editing;
    return SingleChildScrollView(
      padding: Spacing.formPagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              editing?.name ?? l10n.adminNewVenueHeading,
              style: Texts.h1.copyWith(color: p.textPrimary),
            ),
          ),
          const SizedBox(height: Spacing.s4),
          Text(
            l10n.adminVenueFormHint,
            style: Texts.body.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: Spacing.s16),
          FormTextField(
            label: l10n.adminVenueNameUpper,
            semanticLabel: l10n.adminVenueName,
            controller: f.name,
            focusNode: f.nameFocus,
            placeholder: l10n.adminVenueNamePlaceholder,
            error: f.error(VenueField.name, l10n),
            enabled: !f.busy,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              LengthLimitingTextInputFormatter(venueNameMaxLength),
            ],
          ),
          const SizedBox(height: Spacing.s12),
          FormTextField(
            label: l10n.adminAddressUpper,
            semanticLabel: l10n.adminAddress,
            controller: f.address,
            focusNode: f.addressFocus,
            placeholder: editing == null
                ? l10n.adminAddressPlaceholderNew
                : l10n.adminAddressPlaceholderEdit,
            error: f.error(VenueField.address, l10n),
            enabled: !f.busy,
            keyboardType: TextInputType.streetAddress,
            autofillHints: const [AutofillHints.streetAddressLine1],
            textInputAction: TextInputAction.done,
            inputFormatters: [
              LengthLimitingTextInputFormatter(venueAddressMaxLength),
            ],
          ),
          const SizedBox(height: Spacing.s12),
          ..._schedule(l10n),
        ],
      ),
    );
  }

  List<Widget> _schedule(AppLocalizations l10n) {
    final f = form;
    final opensAt = f.opensAt;
    final closesAt = f.closesAt;
    return [
      SelectorField(
        label: l10n.adminOpeningUpper,
        semanticLabel: l10n.adminOpening,
        value: opensAt == null ? null : wholeHour(opensAt),
        placeholder: '08:00',
        icon: Icons.schedule_rounded,
        error: f.error(VenueField.opensAt, l10n),
        onTap: f.submitting ? null : () => onPickHour(VenueField.opensAt),
      ),
      const SizedBox(height: Spacing.s12),
      SelectorField(
        label: l10n.adminClosingUpper,
        semanticLabel: l10n.adminClosing,
        value: closesAt == null ? null : wholeHour(closesAt),
        placeholder: '23:00',
        icon: Icons.schedule_rounded,
        error: f.error(VenueField.closesAt, l10n),
        onTap: f.busy ? null : () => onPickHour(VenueField.closesAt),
      ),
      const SizedBox(height: Spacing.s12),
      SelectorField(
        label: l10n.adminOpenDaysUpper,
        semanticLabel: l10n.adminOpenDays,
        value: weekdaysText(l10n, weekdaysLabel(f.openDays)),
        placeholder: openDaysText(l10n, OpenDays.mondayToSunday),
        icon: Icons.expand_more_rounded,
        error: f.error(VenueField.openDays, l10n),
        onTap: f.busy ? null : onPickDays,
      ),
    ];
  }
}
