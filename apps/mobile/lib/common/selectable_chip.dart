import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';

/// A chip or tab that is chosen by tapping it: the chosen one in lime. Each
/// `SelectableChip(...)` sets what distinguishes it: minimum [minHeight], [padding],
/// [unselectedBackground], [bordered], [style], [icon] and the unselected label inks.
///
/// It is announced as a button, selected and enabled according to [onTap]. Without [onTap] it
/// is disabled; with [disabledInk] it also dims the label.
class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
    this.label,
    this.icon,
    this.style = Texts.bodyStrong,
    this.minHeight = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: Spacing.s16),
    this.unselectedBackground,
    this.bordered = false,
    this.unselectedInk,
    this.disabledInk,
  });

  final String text;
  final bool selected;
  final VoidCallback? onTap;

  /// What the screen reader reads; without it, [text].
  final String? label;
  final IconData? icon;
  final TextStyle style;

  /// The minimum height; with a height the content is centered.
  final double minHeight;
  final EdgeInsetsGeometry padding;

  /// Without them: `bgSurfaceRaised` and `textPrimary`.
  final Color? unselectedBackground;
  final Color? unselectedInk;

  /// The label color when [onTap] is null and the chip is not selected.
  final Color? disabledInk;

  /// The shape border, dark lime when selected.
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ink = selected
        ? p.accentOn
        : onTap == null && disabledInk != null
        ? disabledInk!
        : unselectedInk ?? p.textPrimary;
    final symbol = icon;
    final labelText = Text(text, style: style.copyWith(color: ink));
    final content = symbol == null
        ? labelText
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(symbol, size: 18, color: ink),
              const SizedBox(width: Spacing.s8),
              labelText,
            ],
          );
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label ?? text,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected
            ? p.accentBase
            : unselectedBackground ?? p.bgSurfaceRaised,
        shape: bordered
            ? StadiumBorder(
                side: BorderSide(
                  color: selected ? p.accentEdge : p.borderControl,
                ),
              )
            : const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: padding,
              child: minHeight > 0
                  ? Center(widthFactor: 1, child: content)
                  : content,
            ),
          ),
        ),
      ),
    );
  }
}
