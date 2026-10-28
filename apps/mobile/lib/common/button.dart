// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'fixed_bar.dart';
import 'motion.dart';

/// `Btn/Type=Primary`: lime pill, 52 tall. Disabled turns gray.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.dimmed = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;

  /// Looks disabled but still accepts the tap: the form uses it to flag what is
  /// missing instead of doing nothing.
  final bool dimmed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onTap != null && !loading;
    final symbol = icon;
    return Pressable(
      // Minimum height, not fixed: with enlarged text the button grows instead of clipping it.
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: Spacing.controlHeight,
          minWidth: double.infinity,
        ),
        child: FilledButton(
          onPressed: enabled ? onTap : null,
          style: FilledButton.styleFrom(
            // Dimmed lowers only the background and keeps the text in `textPrimary`: it can be
            // tapped and must reach 4.5:1. Disabled is gray with `textSecondary`;
            // loading keeps the lime.
            backgroundColor: dimmed
                ? p.accentBase.withValues(alpha: 0.4)
                : p.accentBase,
            foregroundColor: dimmed ? p.textPrimary : p.accentOn,
            disabledBackgroundColor: loading ? p.accentBase : p.stateDisabled,
            disabledForegroundColor: loading ? p.accentOn : p.textSecondary,
            shape: const StadiumBorder(),
            side: BorderSide(color: p.accentEdge),
            textStyle: Texts.button,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
          ),
          child: loading
              ? SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: p.accentOn,
                  ),
                )
              : symbol == null
              ? Text(label)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(symbol, size: 20),
                    const SizedBox(width: Spacing.s8),
                    Flexible(child: Text(label, textAlign: TextAlign.center)),
                  ],
                ),
        ),
      ),
    );
  }
}

/// `Btn/Type=Text`: no background, in `accent/ink`. With [overPhoto] it uses the fixed lime.
class TextActionButton extends StatelessWidget {
  const TextActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.overPhoto = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool overPhoto;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = overPhoto ? p.accentOnMedia : p.accentInk;
    return Pressable(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Spacing.controlHeight),
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: color,
            textStyle: Texts.button,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(label, textAlign: TextAlign.center)),
              if (icon != null) ...[
                const SizedBox(width: Spacing.s8),
                Icon(icon, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `Btn/Type=Secondary`: 52 pill with a border, for actions that are not the main one.
class OutlineButton extends StatelessWidget {
  const OutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.compact = false,
    this.icon,
    this.semanticLabel,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onTap;

  /// `Btn/Type=Danger-Outline`: red border and text, for actions that cannot be undone.
  final bool danger;

  /// Less side padding, for two buttons side by side on a small phone.
  final bool compact;
  final IconData? icon;

  /// What the screen reader reads when [label] alone does not say what the button is for.
  final String? semanticLabel;

  /// `false` shrinks it to its content instead of stretching it to the full available
  /// width: for a short button next to another control, like «Filtros» next to the search.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final symbol = icon;
    return Pressable(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: Spacing.controlHeight,
          minWidth: expand ? double.infinity : 0,
        ),
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: symbol == null ? null : Icon(symbol, size: 18),
          style: OutlinedButton.styleFrom(
            foregroundColor: danger ? p.stateDangerInk : p.textPrimary,
            side: BorderSide(
              color: danger ? p.stateDanger : p.borderControl,
              width: 1.5,
            ),
            shape: const StadiumBorder(),
            textStyle: Texts.button,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? Spacing.s8 : Spacing.s24,
            ),
          ),
          label: switch (semanticLabel) {
            final semanticText? => Semantics(
              label: semanticText,
              excludeSemantics: true,
              child: Text(label, textAlign: TextAlign.center),
            ),
            null => Text(label, textAlign: TextAlign.center),
          },
        ),
      ),
    );
  }
}

/// The fixed bottom bar with the main action of a long form.
class ActionBar extends StatelessWidget {
  const ActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FixedBar(
      color: p.bgSurfaceRaised,
      padding: const EdgeInsets.fromLTRB(
        Spacing.s24,
        Spacing.s16,
        Spacing.s24,
        Spacing.s24,
      ),
      child: child,
    );
  }
}

/// `Btn/Type=Danger`: red pill to confirm something that cannot be undone.
///
/// Uses `state/danger-strong`: with `state/danger` the white text misses the minimum contrast.
class DangerButton extends StatelessWidget {
  const DangerButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: Spacing.controlHeight,
          minWidth: double.infinity,
        ),
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: p.stateDangerStrong,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            textStyle: Texts.button,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
          ),
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
