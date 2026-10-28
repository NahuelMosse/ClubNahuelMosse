import 'package:flutter/material.dart';

/// The colors of the prototype's `Color` collection, in both modes.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.bgBase,
    required this.bgSurface,
    required this.bgSurfaceRaised,
    required this.bgScrim,
    required this.bgHeroFrom,
    required this.bgHeroTo,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textInverse,
    required this.textOnMedia,
    required this.textOnMediaMuted,
    required this.borderDefault,
    required this.borderFocus,
    required this.borderError,
    required this.borderControl,
    required this.accentBase,
    required this.accentOn,
    required this.accentMuted,
    required this.accentInk,
    required this.accentEdge,
    required this.accentOnMedia,
    required this.accentFree,
    required this.stateDanger,
    required this.stateDangerInk,
    required this.stateDangerMuted,
    required this.stateDangerStrong,
    required this.stateSuccess,
    required this.stateSuccessInk,
    required this.stateSuccessMuted,
    required this.stateWarning,
    required this.stateWarningInk,
    required this.stateDisabled,
  });

  static const dark = Palette(
    bgBase: Color(0xFF0A0A0B),
    bgSurface: Color(0xFF141416),
    bgSurfaceRaised: Color(0xFF1E1E21),
    bgScrim: Color(0xA8000000),
    bgHeroFrom: Color(0xFF16301F),
    bgHeroTo: Color(0xFF0A0A0B),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA1A1AA),
    textMuted: Color(0xFF85858C),
    textInverse: Color(0xFF0A0A0B),
    textOnMedia: Color(0xFFFFFFFF),
    textOnMediaMuted: Color(0xFFD4D4D8),
    borderDefault: Color(0xFF2A2A2E),
    borderFocus: Color(0xFFD4FF3D),
    borderError: Color(0xFFFF4D6A),
    borderControl: Color(0xFF64646E),
    accentBase: Color(0xFFD4FF3D),
    accentOn: Color(0xFF0A0A0B),
    accentMuted: Color(0x24D4FF3D),
    accentInk: Color(0xFFD4FF3D),
    accentEdge: Color(0x00D4FF3D),
    accentOnMedia: Color(0xFFD4FF3D),
    accentFree: Color(0xFF6B8A1C),
    stateDanger: Color(0xFFFF4D6A),
    stateDangerInk: Color(0xFFFF7B8E),
    stateDangerMuted: Color(0x2EFF4D6A),
    stateDangerStrong: Color(0xFFE02D4A),
    stateSuccess: Color(0xFF3DD68C),
    stateSuccessInk: Color(0xFF3DD68C),
    stateSuccessMuted: Color(0x2E3DD68C),
    stateWarning: Color(0xFFFFB020),
    stateWarningInk: Color(0xFFFFB020),
    stateDisabled: Color(0xFF3A3A40),
  );

  static const light = Palette(
    bgBase: Color(0xFFFFFFFF),
    bgSurface: Color(0xFFF4F4F6),
    bgSurfaceRaised: Color(0xFFFFFFFF),
    bgScrim: Color(0x73000000),
    bgHeroFrom: Color(0xFFEEF9D6),
    bgHeroTo: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0A0A0B),
    textSecondary: Color(0xFF52525B),
    textMuted: Color(0xFF6B6B75),
    textInverse: Color(0xFFFFFFFF),
    textOnMedia: Color(0xFFFFFFFF),
    textOnMediaMuted: Color(0xFFD4D4D8),
    borderDefault: Color(0xFFE4E4E7),
    borderFocus: Color(0xFF5C7A00),
    borderError: Color(0xFFD92D4A),
    borderControl: Color(0xFF8A8A93),
    accentBase: Color(0xFFD4FF3D),
    accentOn: Color(0xFF0A0A0B),
    accentMuted: Color(0x1F5C7A00),
    accentInk: Color(0xFF4D6600),
    accentEdge: Color(0xFF5C7A00),
    accentOnMedia: Color(0xFFD4FF3D),
    accentFree: Color(0xFF8DB31F),
    stateDanger: Color(0xFFD92D4A),
    stateDangerInk: Color(0xFFB4233D),
    stateDangerMuted: Color(0x1FDC2626),
    stateDangerStrong: Color(0xFFB91C1C),
    stateSuccess: Color(0xFF16A34A),
    stateSuccessInk: Color(0xFF15803D),
    stateSuccessMuted: Color(0x1F16A34A),
    stateWarning: Color(0xFFD97706),
    stateWarningInk: Color(0xFFA85B00),
    stateDisabled: Color(0xFFD4D4D8),
  );

  final Color bgBase;
  final Color bgSurface;
  final Color bgSurfaceRaised;
  final Color bgScrim;

  /// Top of the gradient of the headers with a photo or a color, like the profile's.
  final Color bgHeroFrom;

  /// Bottom of the gradient of the headers with a photo or a color.
  final Color bgHeroTo;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textInverse;

  /// Main text over a photo; the same in both modes.
  final Color textOnMedia;

  /// Secondary text over a photo.
  final Color textOnMediaMuted;
  final Color borderDefault;
  final Color borderFocus;
  final Color borderError;
  final Color borderControl;
  final Color accentBase;
  final Color accentOn;
  final Color accentMuted;
  final Color accentInk;
  final Color accentEdge;

  /// Accent over a photo; lime in both modes.
  final Color accentOnMedia;

  /// Free hour of the day timeline.
  final Color accentFree;
  final Color stateDanger;
  final Color stateDangerInk;
  final Color stateDangerMuted;

  /// Background of the filled danger buttons, with white text.
  final Color stateDangerStrong;
  final Color stateSuccess;
  final Color stateSuccessInk;
  final Color stateSuccessMuted;
  final Color stateWarning;
  final Color stateWarningInk;
  final Color stateDisabled;

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

/// Space and radius scale of the `Scale` collection.
abstract final class Spacing {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double radiusMd = 12;
  static const double radiusLg = 20;
  static const double radiusPill = 999;
  static const double touchTarget = 44;
  static const double controlHeight = 52;

  /// The content margin of a scrolling list.
  static const listPagePadding = EdgeInsets.fromLTRB(s24, s24, s24, s40);

  /// The content margin of a scrolling form.
  static const formPagePadding = EdgeInsets.fromLTRB(s24, s12, s24, s40);
}

extension ContextPalette on BuildContext {
  Palette get palette {
    final palette = Theme.of(this).extension<Palette>();
    if (palette == null) throw StateError('El tema no tiene Paleta');
    return palette;
  }
}
