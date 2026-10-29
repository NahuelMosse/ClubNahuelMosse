// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'button.dart';
import 'result.dart';
import 'text_field.dart';
import 'top_bar.dart';

/// A password field with its eye: [visible] says whether it shows, [onToggle] flips it.
/// With [onSubmit] the keyboard closes the entry (it is the last field).
FormTextField passwordField({
  required String label,
  required String accessibleLabel,
  required String placeholder,
  required TextEditingController controller,
  required bool visible,
  required bool enabled,
  required VoidCallback onToggle,
  required String autofill,
  String? error,
  FocusNode? focusNode,
  ValueChanged<String>? onSubmit,
}) => FormTextField(
  label: label,
  semanticLabel: accessibleLabel,
  controller: controller,
  focusNode: focusNode,
  placeholder: placeholder,
  error: error,
  obscure: !visible,
  enabled: enabled,
  autofillHints: [autofill],
  textInputAction: onSubmit != null
      ? TextInputAction.done
      : TextInputAction.next,
  onSubmitted: onSubmit,
  trailing: PasswordToggle(visible: visible, onChanged: onToggle),
);

/// The «Contraseña actualizada» screen with its primary action.
class PasswordUpdated extends StatelessWidget {
  const PasswordUpdated({
    super.key,
    required this.primary,
    required this.onPrimaryTap,
  });

  final String primary;
  final VoidCallback onPrimaryTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ResultScreen(
      icon: Icons.check_circle_outline_rounded,
      tone: ResultTone.success,
      title: l10n.commonPasswordUpdatedTitle,
      text: l10n.commonPasswordUpdatedText,
      primary: primary,
      onPrimaryTap: onPrimaryTap,
    );
  }
}

/// A password form: bar, title, explanation, [fields] and the save button, which is
/// enabled with [onSave].
class PasswordFormTemplate extends StatelessWidget {
  const PasswordFormTemplate({
    super.key,
    required this.bar,
    required this.title,
    required this.explanation,
    required this.fields,
    required this.submitting,
    required this.onSave,
  });

  final TopBar bar;
  final String title;
  final String explanation;
  final List<Widget> fields;
  final bool submitting;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bgBase,
      appBar: bar,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.s24,
            Spacing.s12,
            Spacing.s24,
            Spacing.s40,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: Texts.h1.copyWith(color: p.textPrimary),
              ),
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              explanation,
              style: Texts.body.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Spacing.s16),
            ...fields,
          ],
        ),
      ),
      bottomNavigationBar: ActionBar(
        child: PrimaryButton(
          label: AppLocalizations.of(context).commonSavePassword,
          loading: submitting,
          onTap: onSave,
        ),
      ),
    );
  }
}
