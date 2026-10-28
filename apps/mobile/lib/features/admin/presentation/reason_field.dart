import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// The multiline field for the reason of a voiding; with [missingReason] it is marked as an error.
class ReasonField extends StatelessWidget {
  const ReasonField({
    super.key,
    required this.controller,
    required this.maxLength,
    required this.missingReason,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int maxLength;
  final bool missingReason;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Spacing.radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
    return Semantics(
      container: true,
      label: 'Motivo de la anulación',
      child: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 5,
        maxLength: maxLength,
        buildCounter:
            (
              context, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) => null,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        onChanged: onChanged,
        style: Texts.body.copyWith(color: p.textPrimary),
        decoration: InputDecoration(
          filled: true,
          fillColor: p.bgSurface,
          contentPadding: const EdgeInsets.all(Spacing.s16),
          enabledBorder: missingReason
              ? border(p.borderError, 1.5)
              : border(p.borderControl, 1),
          focusedBorder: missingReason
              ? border(p.borderError, 1.5)
              : border(p.borderFocus, 1.5),
          border: border(p.borderControl, 1),
        ),
      ),
    );
  }
}
