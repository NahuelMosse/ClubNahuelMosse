import 'package:flutter/material.dart';

import '../../../common/price_format.dart';
import '../../../common/selector.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

const requiredMessage = 'Este campo es obligatorio';
const _maxPrice = 9999999;

/// The error of the price-per-hour [text]: required and between $ 1 and $ 9.999.999.
String? priceError(String text) {
  final price = readPrice(text);
  if (price == null) return requiredMessage;
  return price < 1 || price > _maxPrice
      ? 'Ingresá un precio entre \$ 1 y \$ 9.999.999'
      : null;
}

/// The title of a space form, with the explanation of how the name is built.
List<Widget> spaceFormHeading(BuildContext context, String title) {
  final p = context.palette;
  return [
    Semantics(
      header: true,
      child: Text(title, style: Texts.h1.copyWith(color: p.textPrimary)),
    ),
    const SizedBox(height: Spacing.s4),
    Text(
      'El nombre se arma solo con la sede, la dirección, el deporte, '
      'el tipo y el número.',
      style: Texts.body.copyWith(color: p.textSecondary),
    ),
    const SizedBox(height: Spacing.s16),
  ];
}

/// Asks to choose the roofing (covered or open air) or the lighting of the space; `null`
/// if closed without choosing.
Future<bool?> pickYesNo(
  BuildContext context, {
  required bool roofing,
  required bool? selected,
}) => pickOption<bool>(
  context,
  title: roofing ? 'Condición' : 'Iluminación',
  options: roofing
      ? const [(false, 'Al aire libre'), (true, 'Techada')]
      : const [(true, 'Iluminada'), (false, 'Sin iluminación')],
  selected: selected,
);
