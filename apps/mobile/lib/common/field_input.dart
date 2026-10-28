// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';

/// The pill `TextField` of a [FormTextField]: fill, placeholder and border according to the error.
class FieldInput extends StatelessWidget {
  const FieldInput({
    super.key,
    required this.controller,
    required this.enabled,
    required this.obscure,
    required this.hasError,
    this.focusNode,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.trailing,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool obscure;
  final bool hasError;
  final FocusNode? focusNode;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? trailing;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hintText = hint;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Spacing.radiusPill),
      borderSide: BorderSide(color: color, width: width),
    );

    return TextField(
      controller: controller,
      enabled: enabled,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      style: Texts.body.copyWith(color: p.textPrimary),
      decoration: InputDecoration(
        // The placeholder is announced as the field hint, not as its label.
        hint: hintText == null
            ? null
            : ExcludeSemantics(
                child: Text(
                  hintText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Texts.body.copyWith(color: p.textMuted),
                ),
              ),
        filled: true,
        fillColor: p.bgSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.s20),
        suffixIcon: trailing == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: Spacing.s8),
                child: trailing,
              ),
        enabledBorder: hasError
            ? border(p.borderError, 1.5)
            : border(p.borderControl, 1),
        focusedBorder: hasError
            ? border(p.borderError, 1.5)
            : border(p.borderFocus, 1.5),
        disabledBorder: border(p.borderControl, 1),
        border: border(p.borderControl, 1),
      ),
    );
  }
}
