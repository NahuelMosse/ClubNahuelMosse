import 'package:flutter/material.dart';

import '../../../common/price_format.dart';
import '../../../common/selector.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/name_missing.dart';
import '../domain/space_price.dart';

/// The error of the price-per-hour [text]: required and between $ 1 and $ 9.999.999.
String? priceError(AppLocalizations l10n, String text) {
  final price = readPrice(text);
  if (price == null) return l10n.adminRequiredField;
  return validPricePerHour(price) ? null : l10n.adminPriceRange;
}

/// What is missing to compute the name of a space, in words.
String nameMissingText(AppLocalizations l10n, NameMissing missing) =>
    switch (missing) {
      NameMissing.venueSportAndType => l10n.adminMissingAll,
      NameMissing.venue => l10n.adminMissingVenue,
      NameMissing.sport => l10n.adminMissingSport,
      NameMissing.type => l10n.adminMissingType,
    };

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
      AppLocalizations.of(context).adminSpaceFormHint,
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
}) {
  final l10n = AppLocalizations.of(context);
  return pickOption<bool>(
    context,
    title: roofing ? l10n.adminCondition : l10n.adminLighting,
    options: roofing
        ? [(false, l10n.adminOpenAir), (true, l10n.adminCovered)]
        : [(true, l10n.adminLit), (false, l10n.adminUnlit)],
    selected: selected,
  );
}
