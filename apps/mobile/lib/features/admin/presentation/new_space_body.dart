import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/selector.dart';
import '../../../common/snackbar.dart';
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
          ...spaceFormHeading(context, 'Nuevo espacio deportivo'),
          ..._selectors(),
          PricePerHourField(
            controller: f.price,
            error: f.error(NewSpaceField.price),
            enabled: !f.submitting && !f.loading,
          ),
          const SizedBox(height: Spacing.s16),
          GeneratedName(
            name: f.suggested?.$1,
            computing: f.computing,
            missing: f.missingForName,
            onRetry: f.nameFailure == null || f.submitting ? null : onRetryName,
          ),
          const SizedBox(height: Spacing.s16),
          PrimaryButton(
            label: 'GUARDAR ESPACIO',
            loading: f.submitting,
            dimmed: !f.isComplete,
            onTap: onSave,
          ),
          const SizedBox(height: Spacing.s12),
          OutlineButton(
            label: 'CANCELAR',
            onTap: f.submitting ? null : () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  List<Widget> _selectors() {
    final f = form;
    final venues = f.venueOptions;
    final enabled = !f.submitting && !f.loading;
    return [
      SelectorField(
        label: 'SEDE',
        semanticLabel: 'Sede',
        value: f.venue?.name,
        placeholder: venues == null || venues.isNotEmpty
            ? 'Seleccioná una sede'
            : 'Todavía no hay sedes',
        icon: Icons.expand_more_rounded,
        error: f.error(NewSpaceField.venue),
        onTap: enabled && (venues?.isNotEmpty ?? false) ? onPickVenue : null,
      ),
      const SizedBox(height: Spacing.s12),
      SelectorField(
        label: 'DEPORTE',
        semanticLabel: 'Deporte',
        value: f.sport?.name,
        placeholder: 'Seleccioná un deporte',
        icon: Icons.expand_more_rounded,
        error: f.error(NewSpaceField.sport),
        onTap: enabled ? onPickSport : null,
      ),
      const SizedBox(height: Spacing.s12),
      SelectorField(
        label: 'TIPO',
        semanticLabel: 'Tipo',
        value: f.type?.name,
        placeholder: 'Seleccioná el tipo',
        icon: Icons.expand_more_rounded,
        error: f.error(NewSpaceField.type),
        onTap: enabled && f.sport != null ? onPickType : null,
      ),
      const SizedBox(height: Spacing.s12),
      FieldPair(
        left: SelectorField(
          label: 'CONDICIÓN',
          semanticLabel: 'Condición',
          value: switch (f.roofed) {
            true => 'Techada',
            false => 'Al aire libre',
            null => null,
          },
          placeholder: 'Seleccioná',
          icon: Icons.expand_more_rounded,
          error: f.error(NewSpaceField.roofing),
          onTap: enabled ? () => onPickYesNo(NewSpaceField.roofing) : null,
        ),
        right: SelectorField(
          label: 'ILUMINACIÓN',
          semanticLabel: 'Iluminación',
          value: switch (f.lit) {
            true => 'Iluminada',
            false => 'Sin iluminación',
            null => null,
          },
          placeholder: 'Seleccioná',
          icon: Icons.expand_more_rounded,
          error: f.error(NewSpaceField.lighting),
          onTap: enabled ? () => onPickYesNo(NewSpaceField.lighting) : null,
        ),
      ),
      const SizedBox(height: Spacing.s12),
    ];
  }
}
