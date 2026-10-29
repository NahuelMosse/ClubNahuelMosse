import 'package:flutter/material.dart';

import '../../../common/price_format.dart';
import '../../../common/text_field.dart';
import '../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    return FormTextField(
      label: l10n.adminPricePerHourUpper,
      semanticLabel: l10n.adminPricePerHour,
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
