import '../../../common/price_format.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/space.dart';

/// «Covered» or «Open air», in the language of [l].
String conditionText(AppLocalizations l, Space space) =>
    space.covered ? l.spaceCovered : l.spaceOpenAir;

/// «Lit» or «Unlit», in the language of [l].
String lightingText(AppLocalizations l, Space space) =>
    space.lit ? l.spaceLit : l.spaceUnlit;

/// «Fútbol 5 · Open air · $ 38.000 per hour».
String spaceDescription(AppLocalizations l, Space space, Catalog catalog) =>
    l.spaceDescription(
      conditionText(l, space),
      catalog.readableKind(space.sport, space.kind),
      formatPesos(space.pricePerHour),
    );
