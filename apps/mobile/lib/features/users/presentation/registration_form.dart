import 'package:flutter/material.dart';

import '../../../common/date_format.dart';
import '../../../common/text_field.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          RegistrationField.firstName,
          label: 'NOMBRE',
          accessible: 'Nombre',
          placeholder: 'Tu nombre',
          keyboard: TextInputType.name,
          autofill: const [AutofillHints.givenName],
        ),
        const SizedBox(height: Spacing.s16),
        _field(
          RegistrationField.lastName,
          label: 'APELLIDO',
          accessible: 'Apellido',
          placeholder: 'Tu apellido',
          keyboard: TextInputType.name,
          autofill: const [AutofillHints.familyName],
        ),
        const SizedBox(height: Spacing.s16),
        _field(
          RegistrationField.dni,
          label: 'DNI',
          accessible: 'DNI',
          placeholder: '00.000.000',
          keyboard: TextInputType.number,
        ),
        const SizedBox(height: Spacing.s16),
        _field(
          RegistrationField.birthDate,
          label: 'FECHA DE NACIMIENTO',
          accessible: 'Fecha de nacimiento',
          placeholder: 'DD / MM / AAAA',
          keyboard: TextInputType.number,
          trailingAction: IconButton(
            tooltip: 'Elegir fecha',
            onPressed: submitting ? null : onPickDate,
            icon: Icon(Icons.calendar_today_outlined, color: p.textSecondary),
          ),
        ),
        const SizedBox(height: Spacing.s16),
        _field(
          RegistrationField.email,
          label: 'CORREO ELECTRÓNICO',
          accessible: 'Correo electrónico',
          placeholder: 'tu@correo.com',
          keyboard: TextInputType.emailAddress,
          autofill: const [AutofillHints.email],
        ),
        const SizedBox(height: Spacing.s16),
        _field(
          RegistrationField.password,
          label: 'CONTRASEÑA',
          accessible: 'Contraseña',
          placeholder: '8+ caracteres, mayúscula y número',
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
