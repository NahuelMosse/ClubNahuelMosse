import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'field_input.dart';
import 'motion.dart';

/// The prototype `Input` component: label on top if any, pill field and error below.
class FormTextField extends StatelessWidget {
  const FormTextField({
    super.key,
    this.label,
    required this.semanticLabel,
    required this.controller,
    this.focusNode,
    this.placeholder,
    this.error,
    this.keyboardType,
    this.inputFormatters,
    this.obscure = false,
    this.trailing,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints,
    this.enabled = true,
  });

  final String? label;
  final String semanticLabel;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final String? error;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscure;
  final Widget? trailing;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final message = error;
    final hint = placeholder;
    final title = label;
    final hasError = message != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          ExcludeSemantics(
            child: Text(
              title,
              style: Texts.overline.copyWith(color: p.textSecondary),
            ),
          ),
          const SizedBox(height: Spacing.s8),
        ],
        Semantics(
          container: true,
          label: semanticLabel,
          hint: accessibleHint(format: hint, error: message),
          // The error is announced as soon as it appears.
          liveRegion: hasError,
          child: Shake(
            trigger: message,
            child: SizedBox(
              height: Spacing.controlHeight,
              child: Material(
                type: MaterialType.transparency,
                child: FieldInput(
                  controller: controller,
                  enabled: enabled,
                  focusNode: focusNode,
                  obscure: obscure,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  textInputAction: textInputAction,
                  onSubmitted: onSubmitted,
                  autofillHints: autofillHints,
                  hint: hint,
                  trailing: trailing,
                  hasError: hasError,
                ),
              ),
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: Spacing.s8),
          FieldError(message),
        ],
      ],
    );
  }
}

/// A loose error, outside a field: the screen reader announces it as soon as it appears.
class FieldMessage extends StatelessWidget {
  const FieldMessage(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) =>
      Semantics(liveRegion: true, child: _ErrorRow(message));
}

/// The error shown below a field. The screen reader does not walk it separately: the field
/// announces it, carrying it in its own node.
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: _ErrorRow(message));
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: p.stateDangerInk,
          ),
        ),
        const SizedBox(width: Spacing.s8),
        Expanded(
          child: Text(
            message,
            style: Texts.caption.copyWith(color: p.stateDangerInk),
          ),
        ),
      ],
    );
  }
}

/// What the reader says about a field besides its label: the expected format and the
/// error, in that order. `null` if there is nothing to add.
String? accessibleHint({String? format, String? error}) {
  final parts = [?format, ?error];
  return parts.isEmpty ? null : parts.join('. ');
}

/// The eye that shows or hides the password, at the end of the field.
class PasswordToggle extends StatelessWidget {
  const PasswordToggle({
    super.key,
    required this.visible,
    required this.onChanged,
  });

  final bool visible;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: visible ? 'Ocultar contraseña' : 'Mostrar contraseña',
      onPressed: onChanged,
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: context.palette.textSecondary,
      ),
    );
  }
}
