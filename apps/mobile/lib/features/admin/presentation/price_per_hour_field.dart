import 'package:flutter/material.dart';

import '../../../common/price_format.dart';
import '../../../common/text_field.dart';

/// The price-per-hour field of a space.
class PricePerHourField extends StatelessWidget {
  const PricePerHourField({
    super.key,
    required this.controller,
    required this.error,
    required this.enabled,
  });

  final TextEditingController controller;
  final String? error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormTextField(
      label: 'PRECIO POR HORA',
      semanticLabel: 'Precio por hora',
      controller: controller,
      placeholder: '\$ 0',
      error: error,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: const [PriceInputFormatter()],
    );
  }
}
