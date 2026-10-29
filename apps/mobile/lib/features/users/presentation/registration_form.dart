import 'package:flutter/material.dart';

import '../../../common/date_format.dart';
import '../../../common/text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../domain/registration_field.dart';

/// Los seis campos del registro, uno debajo del otro.
class RegistrationForm extends StatelessWidget {
  const RegistrationForm({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.errorOf,
    required this.submitting,
    required this.passwordVisible,
    required this.onPickDate,
    required this.onToggleVisibility,
  });

  /// Uno por campo, en el orden de [RegistrationField].
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final String? Function(RegistrationField field) errorOf;
  final bool submitting;
  final bool passwordVisible;
  final VoidCallback onPickDate;
  final VoidCallback onToggleVisibility;

  FormTextField _field(
    RegistrationField field, {
    required String label,
    required String accessible,
    required String placeholder,
    TextInputType? keyboard,
    Widget? trailingAction,
    bool hidden = false,
    Iterable<String>? autofill,
  }) {
    return FormTextField(
      label: label,
      semanticLabel: accessible,
      controller: controllers[field.index],
      focusNode: focusNodes[field.index],
      placeholder: placeholder,
      error: errorOf(field),
      keyboardType: keyboard,
      obscure: hidden,
      enabled: !submitting,
      trailing: trailingAction,
      autofillHints: autofill,
      textInputAction: field == RegistrationField.password
          ? TextInputAction.done
          : TextInputAction.next,
      inputFormatters: switch (field) {
        RegistrationField.dni => [dniInputFormatter],
        RegistrationField.birthDate => const [DateInputFormatter()],
        _ => null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          RegistrationField.firstName,
          label: l10n.profileFirstNameUpper,
          accessible: l10n.profileFirstName,
          placeholder: l10n.registerFirstNamePlaceholder,
          keyboard: TextInputType.name,
          autofill: const [AutofillHints.givenName],
        ),
        const SizedBox(height: Spacing.s16),
        _field(
          RegistrationField.lastName,
          label: l10n.profileLastNameUpper,
          accessible: l10n.profileLastName,
          placeholder: l10n.registerLastNamePlaceholder,
          keyboard: TextInputType.name,
          autofill: const [AutofillHints.familyName],
        ),
        const SizedBox(height: Spacing.s16),
        _field(
          RegistrationField.dni,
          label: l10n.profileDni,
          accessible: l10n.profileDni,
          placeholder: '00.000.000',
          keyboard: TextInputType.number,
        ),
        const SizedBox(height: Spacing.s16),
        _field(
          RegistrationField.birthDate,
          label: l10n.profileBirthUpper,
          accessible: l10n.profileBirth,
          placeholder: l10n.registerBirthPlaceholder,
          keyboard: TextInputType.number,
          trailingAction: IconButton(
            tooltip: l10n.registerPickDate,
            onPressed: submitting ? null : onPickDate,
            icon: Icon(Icons.calendar_today_outlined, color: p.textSecondary),
          ),
        ),
        const SizedBox(height: Spacing.s16),
        _field(
          RegistrationField.email,
          label: l10n.profileEmailUpper,
          accessible: l10n.profileEmail,
          placeholder: l10n.profileEmailPlaceholder,
          keyboard: TextInputType.emailAddress,
          autofill: const [AutofillHints.email],
        ),
        const SizedBox(height: Spacing.s16),
        _field(
          RegistrationField.password,
          label: l10n.profilePasswordUpper,
          accessible: l10n.profilePassword,
          placeholder: l10n.registerPasswordPlaceholder,
          hidden: !passwordVisible,
          autofill: const [AutofillHints.newPassword],
          trailingAction: PasswordToggle(
            visible: passwordVisible,
            onChanged: onToggleVisibility,
          ),
        ),
      ],
    );
  }
}
