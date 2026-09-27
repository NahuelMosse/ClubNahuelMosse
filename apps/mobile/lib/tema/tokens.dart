import 'package:flutter/material.dart';

/// Los colores de la colección `Color` del prototipo, en sus dos modos.
@immutable
class Paleta extends ThemeExtension<Paleta> {
  const Paleta({
    required this.bgBase,
    required this.bgSurface,
    required this.bgSurfaceRaised,
    required this.bgScrim,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textInverse,
    required this.borderDefault,
    required this.borderFocus,
    required this.borderError,
    required this.borderControl,
    required this.accentBase,
    required this.accentOn,
    required this.accentMuted,
    required this.accentInk,
    required this.accentEdge,
    required this.stateDanger,
    required this.stateDangerInk,
    required this.stateDangerMuted,
    required this.stateSuccess,
    required this.stateSuccessInk,
    required this.stateSuccessMuted,
    required this.stateWarning,
    required this.stateWarningInk,
    required this.stateDisabled,
  });

  static const oscura = Paleta(
    bgBase: Color(0xFF0A0A0B),
    bgSurface: Color(0xFF141416),
    bgSurfaceRaised: Color(0xFF1E1E21),
    bgScrim: Color(0xA8000000),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA1A1AA),
    textMuted: Color(0xFF85858C),
    textInverse: Color(0xFF0A0A0B),
    borderDefault: Color(0xFF2A2A2E),
    borderFocus: Color(0xFFD4FF3D),
    borderError: Color(0xFFFF4D4D),
    borderControl: Color(0xFF3A3A40),
    accentBase: Color(0xFFD4FF3D),
    accentOn: Color(0xFF0A0A0B),
    accentMuted: Color(0x26D4FF3D),
    accentInk: Color(0xFFD4FF3D),
    accentEdge: Color(0x00D4FF3D),
    stateDanger: Color(0xFFFF4D4D),
    stateDangerInk: Color(0xFFFF7B7B),
    stateDangerMuted: Color(0x2EFF4D4D),
    stateSuccess: Color(0xFF3DD68C),
    stateSuccessInk: Color(0xFF3DD68C),
    stateSuccessMuted: Color(0x2E3DD68C),
    stateWarning: Color(0xFFFFB020),
    stateWarningInk: Color(0xFFFFB020),
    stateDisabled: Color(0xFF3A3A40),
  );

  static const clara = Paleta(
    bgBase: Color(0xFFFFFFFF),
    bgSurface: Color(0xFFF4F4F6),
    bgSurfaceRaised: Color(0xFFFFFFFF),
    bgScrim: Color(0x73000000),
    textPrimary: Color(0xFF0A0A0B),
    textSecondary: Color(0xFF52525B),
    textMuted: Color(0xFF6B6B75),
    textInverse: Color(0xFFFFFFFF),
    borderDefault: Color(0xFFE4E4E7),
    borderFocus: Color(0xFF5C7A00),
    borderError: Color(0xFFDC2626),
    borderControl: Color(0xFF8A8A93),
    accentBase: Color(0xFFD4FF3D),
    accentOn: Color(0xFF0A0A0B),
    accentMuted: Color(0x47D4FF3D),
    accentInk: Color(0xFF5C7A00),
    accentEdge: Color(0xFF5C7A00),
    stateDanger: Color(0xFFDC2626),
    stateDangerInk: Color(0xFFB91C1C),
    stateDangerMuted: Color(0x1FDC2626),
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
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textInverse;
  final Color borderDefault;
  final Color borderFocus;
  final Color borderError;
  final Color borderControl;
  final Color accentBase;
  final Color accentOn;
  final Color accentMuted;
  final Color accentInk;
  final Color accentEdge;
  final Color stateDanger;
  final Color stateDangerInk;
  final Color stateDangerMuted;
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
