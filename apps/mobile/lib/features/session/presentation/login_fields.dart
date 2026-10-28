import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../common/text_field.dart';
import '../../../theme/tokens.dart';

/// Correo y contraseña, con el enlace para recuperarla.
class LoginFields extends StatelessWidget {
  const LoginFields({
    super.key,
    required this.email,
    required this.password,
    required this.emailError,
    required this.passwordError,
    required this.passwordVisible,
    required this.submitting,
    required this.onSubmit,
    required this.onToggleVisibility,
  });

  final TextEditingController email;
  final TextEditingController password;
  final String? emailError;
  final String? passwordError;
  final bool passwordVisible;
  final bool submitting;
  final VoidCallback onSubmit;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormTextField(
          semanticLabel: 'Correo',
          placeholder: 'Correo',
          controller: email,
          error: emailError,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          enabled: !submitting,
        ),
        const SizedBox(height: Spacing.s12),
        FormTextField(
          semanticLabel: 'Contraseña',
          placeholder: 'Contraseña',
          controller: password,
          error: passwordError,
          obscure: !passwordVisible,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          enabled: !submitting,
          trailing: PasswordToggle(
            visible: passwordVisible,
            onChanged: onToggleVisibility,
          ),
        ),
        const SizedBox(height: Spacing.s12),
        Align(
          alignment: Alignment.centerRight,
          child: TextActionButton(
            label: '¿Olvidaste tu contraseña?',
            overPhoto: true,
            onTap: submitting
                ? null
                : () => context.go('/recuperar-contrasena'),
          ),
        ),
      ],
    );
  }
}
