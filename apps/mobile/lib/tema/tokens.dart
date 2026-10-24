import 'package:flutter/material.dart';

/// Los colores de la colección `Color` del prototipo, en sus dos modos.
@immutable
class Paleta extends ThemeExtension<Paleta> {
  const Paleta({
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

  static const oscura = Paleta(
    bgBase: Color(0xFF0B0A12),
    bgSurface: Color(0xFF17152A),
    bgSurfaceRaised: Color(0xFF211E3A),
    bgScrim: Color(0xA8000000),
    bgHeroFrom: Color(0xFF2A1A55),
    bgHeroTo: Color(0xFF0B0A12),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA9A3C2),
    textMuted: Color(0xFF8C86A4),
    textInverse: Color(0xFF0B0A12),
    textOnMedia: Color(0xFFFFFFFF),
    textOnMediaMuted: Color(0xFFDCD8EE),
    borderDefault: Color(0xFF2C2847),
    borderFocus: Color(0xFFA88BFF),
    borderError: Color(0xFFFF4D6A),
    borderControl: Color(0xFF3E3961),
    accentBase: Color(0xFF7C4DFF),
    accentOn: Color(0xFFFFFFFF),
    accentMuted: Color(0x267C4DFF),
    accentInk: Color(0xFFD4FF3D),
    accentEdge: Color(0x007C4DFF),
    accentOnMedia: Color(0xFFD4FF3D),
    stateDanger: Color(0xFFFF4D6A),
    stateDangerInk: Color(0xFFFF7B8E),
    stateDangerMuted: Color(0x2EFF4D6A),
    stateDangerStrong: Color(0xFFE02D4A),
    stateSuccess: Color(0xFF3DD68C),
    stateSuccessInk: Color(0xFF3DD68C),
    stateSuccessMuted: Color(0x2E3DD68C),
    stateWarning: Color(0xFFFFB020),
    stateWarningInk: Color(0xFFFFB020),
    stateDisabled: Color(0xFF3E3961),
  );

  static const clara = Paleta(
    bgBase: Color(0xFFFFFFFF),
    bgSurface: Color(0xFFF4F4F6),
    bgSurfaceRaised: Color(0xFFFFFFFF),
    bgScrim: Color(0x73000000),
    bgHeroFrom: Color(0xFFEEE8FF),
    bgHeroTo: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0A0A0B),
    textSecondary: Color(0xFF52525B),
    textMuted: Color(0xFF6B6B75),
    textInverse: Color(0xFFFFFFFF),
    textOnMedia: Color(0xFFFFFFFF),
    textOnMediaMuted: Color(0xFFD4D4D8),
    borderDefault: Color(0xFFE4E4E7),
    borderFocus: Color(0xFF6D3CF0),
    borderError: Color(0xFFD92D4A),
    borderControl: Color(0xFF8A8A93),
    accentBase: Color(0xFF6D3CF0),
    accentOn: Color(0xFFFFFFFF),
    accentMuted: Color(0x476D3CF0),
    accentInk: Color(0xFF5B2BD6),
    accentEdge: Color(0xFF6D3CF0),
    accentOnMedia: Color(0xFFD4FF3D),
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

  /// Arriba del degradé de las cabeceras con foto o color, como la del perfil.
  final Color bgHeroFrom;

  /// Abajo del degradé de las cabeceras con foto o color.
  final Color bgHeroTo;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textInverse;

  /// Texto principal sobre una foto; es igual en los dos modos.
  final Color textOnMedia;

  /// Texto secundario sobre una foto.
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

  /// Acento sobre una foto; es lima en los dos modos.
  final Color accentOnMedia;
  final Color stateDanger;
  final Color stateDangerInk;
  final Color stateDangerMuted;

  /// Fondo de los botones de peligro rellenos, con texto blanco.
  final Color stateDangerStrong;
  final Color stateSuccess;
  final Color stateSuccessInk;
  final Color stateSuccessMuted;
  final Color stateWarning;
  final Color stateWarningInk;
  final Color stateDisabled;

  @override
  Paleta copyWith() => this;

  @override
  Paleta lerp(Paleta? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

/// Escala de espacio y radios de la colección `Scale`.
abstract final class Medidas {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double radioMd = 12;
  static const double radioLg = 20;
  static const double radioPill = 999;
  static const double tactil = 44;
  static const double altoControl = 52;
}

extension PaletaDelContexto on BuildContext {
  Paleta get paleta {
    final paleta = Theme.of(this).extension<Paleta>();
    if (paleta == null) throw StateError('El tema no tiene Paleta');
    return paleta;
  }
}
