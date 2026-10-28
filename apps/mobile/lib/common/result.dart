import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'motion.dart';
import 'result_actions.dart';
import 'result_detail.dart';

enum ResultTone { success, warning, danger }

/// Full-screen result: icon in a circle, title, text and up to two actions. It is the one
/// for «Contraseña actualizada», «Revisá tu correo» and «El enlace no es válido».
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.text,
    required this.primary,
    required this.onPrimaryTap,
    this.secondary,
    this.onSecondaryTap,
    this.secondaryLoading = false,
    this.detail,
    this.diameter = 96,
    this.iconSize = 40,
    this.iconGap = Spacing.s24,
    this.titleGap = Spacing.s12,
    this.actionsGap = Spacing.s32,
  });

  /// The value that was just saved, in a lime box below the text.
  final String? detail;

  /// The size of the circle and of its icon, and what separates the circle from the title,
  /// the title from the text and the text from the actions.
  final double diameter;
  final double iconSize;
  final double iconGap;
  final double titleGap;
  final double actionsGap;

  final IconData icon;
  final ResultTone tone;
  final String title;
  final String text;
  final String primary;
  final VoidCallback onPrimaryTap;
  final String? secondary;
  final VoidCallback? onSecondaryTap;
  final bool secondaryLoading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (background, ink) = switch (tone) {
      ResultTone.success => (p.stateSuccessMuted, p.stateSuccessInk),
      ResultTone.warning => (p.bgSurfaceRaised, p.textSecondary),
      ResultTone.danger => (p.stateDangerMuted, p.stateDangerInk),
    };
    return Scaffold(
      backgroundColor: p.bgBase,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SuccessPulse(
                    icon: icon,
                    background: background,
                    ink: ink,
                    diameter: diameter,
                    iconSize: iconSize,
                  ),
                ),
                SizedBox(height: iconGap),
                FadeIn(
                  delay: const Duration(milliseconds: 370),
                  fromY: 14,
                  child: Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Texts.h1.copyWith(color: p.textPrimary),
                    ),
                  ),
                ),
                SizedBox(height: titleGap),
                FadeIn(
                  delay: const Duration(milliseconds: 460),
                  fromY: 14,
                  child: ResultDetail(text: text, detail: detail),
                ),
                SizedBox(height: actionsGap),
                FadeIn(
                  delay: const Duration(milliseconds: 550),
                  fromY: 14,
                  child: ResultActions(
                    primary: primary,
                    onPrimaryTap: onPrimaryTap,
                    secondary: secondary,
                    onSecondaryTap: onSecondaryTap,
                    secondaryLoading: secondaryLoading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
