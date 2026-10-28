import 'package:flutter/material.dart';

import '../../../common/selector.dart';

/// A value shown looking like a selector that cannot be changed.
class ReadOnlyField extends StatelessWidget {
  const ReadOnlyField({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.value,
  });

  final String label;
  final String semanticLabel;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SelectorField(
      label: label,
      semanticLabel: semanticLabel,
      value: value,
      placeholder: '',
      icon: Icons.expand_more_rounded,
      onTap: null,
      readOnly: true,
    );
  }
}
