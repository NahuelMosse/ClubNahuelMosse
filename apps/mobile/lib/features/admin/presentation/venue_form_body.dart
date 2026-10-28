// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/dates.dart';
import '../../../common/selector.dart';
import '../../../common/text_field.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../venues/domain/venue.dart';
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
              editing?.name ?? 'Nueva sede',
              style: Texts.h1.copyWith(color: p.textPrimary),
            ),
          ),
          const SizedBox(height: Spacing.s4),
          Text(
            'Nombre, dirección y horarios son obligatorios.',
            style: Texts.body.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: Spacing.s16),
          FormTextField(
            label: 'NOMBRE DE LA SEDE',
            semanticLabel: 'Nombre de la sede',
            controller: f.name,
            focusNode: f.nameFocus,
            placeholder: 'Ej. Sede Haedo',
            error: f.error(VenueField.name),
            enabled: !f.busy,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              LengthLimitingTextInputFormatter(venueNameMaxLength),
            ],
          ),
          const SizedBox(height: Spacing.s12),
          FormTextField(
            label: 'DIRECCIÓN',
            semanticLabel: 'Dirección',
            controller: f.address,
            focusNode: f.addressFocus,
            placeholder: editing == null
                ? 'Calle y altura'
                : 'Escribí la dirección',
            error: f.error(VenueField.address),
            enabled: !f.busy,
            keyboardType: TextInputType.streetAddress,
            autofillHints: const [AutofillHints.streetAddressLine1],
            textInputAction: TextInputAction.done,
            inputFormatters: [
              LengthLimitingTextInputFormatter(venueAddressMaxLength),
            ],
          ),
          const SizedBox(height: Spacing.s12),
          ..._schedule(),
        ],
      ),
    );
  }

  List<Widget> _schedule() {
    final f = form;
    final opensAt = f.opensAt;
    final closesAt = f.closesAt;
    return [
      SelectorField(
        label: 'HORARIO DE APERTURA',
        semanticLabel: 'Horario de apertura',
        value: opensAt == null ? null : wholeHour(opensAt),
        placeholder: '08:00',
        icon: Icons.schedule_rounded,
        error: f.error(VenueField.opensAt),
        onTap: f.submitting ? null : () => onPickHour(VenueField.opensAt),
      ),
      const SizedBox(height: Spacing.s12),
      SelectorField(
        label: 'HORARIO DE CIERRE',
        semanticLabel: 'Horario de cierre',
        value: closesAt == null ? null : wholeHour(closesAt),
        placeholder: '23:00',
        icon: Icons.schedule_rounded,
        error: f.error(VenueField.closesAt),
        onTap: f.busy ? null : () => onPickHour(VenueField.closesAt),
      ),
      const SizedBox(height: Spacing.s12),
      SelectorField(
        label: 'DÍAS QUE ABRE',
        semanticLabel: 'Días que abre',
        value: weekdaysLabel(f.openDays),
        placeholder: OpenDays.mondayToSunday.text,
        icon: Icons.expand_more_rounded,
        error: f.error(VenueField.openDays),
        onTap: f.busy ? null : onPickDays,
      ),
    ];
  }
}
