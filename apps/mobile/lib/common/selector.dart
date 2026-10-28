// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'motion.dart';
import 'options_grid.dart';
import 'selector_value.dart';
import 'text_field.dart';

/// A field that is chosen rather than typed: it looks like the prototype `Input` or `Dropdown`
/// and opens the options when tapped.
class SelectorField extends StatelessWidget {
  const SelectorField({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
    this.error,
    this.readOnly = false,
  });

  final String label;
  final String semanticLabel;
  final String? value;
  final String placeholder;
  final IconData icon;
  final VoidCallback? onTap;
  final String? error;

  /// A value that is shown but not changed: all dimmed, like the disabled `Dropdown`
  /// of the prototype.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final message = error;
    final selected = value;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Spacing.radiusPill),
      side: message != null
          ? BorderSide(color: p.borderError, width: 1.5)
          : BorderSide(color: readOnly ? p.borderDefault : p.borderControl),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: Texts.overline.copyWith(
              color: readOnly ? p.stateDisabled : p.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: Spacing.s8),
        Semantics(
          container: true,
          button: true,
          enabled: onTap != null,
          label: semanticLabel,
          value: selected ?? '',
          hint: message,
          liveRegion: message != null,
          excludeSemantics: true,
          onTap: onTap,
          child: Shake(
            trigger: message,
            child: Material(
              color: readOnly ? Colors.transparent : p.bgSurface,
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  height: Spacing.controlHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.s20,
                    ),
                    child: SelectorValue(
                      value: selected,
                      placeholder: placeholder,
                      icon: icon,
                      readOnly: readOnly,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: Spacing.s8),
          FieldError(message),
        ],
      ],
    );
  }
}

/// Opens the list of [options] and returns the selected one, or `null` if it is closed without choosing.
Future<T?> pickOption<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  T? selected,
  int columns = 1,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) {
      final p = context.palette;
      return FadeIn(
        scaleFrom: 0.88,
        fromY: 0,
        curve: AppMotion.fast,
        child: Dialog(
          backgroundColor: p.bgSurfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Spacing.radiusLg),
            side: BorderSide(color: p.borderDefault),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.s24,
            vertical: Spacing.s48,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.s24,
                  Spacing.s20,
                  Spacing.s24,
                  Spacing.s8,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Texts.title.copyWith(color: p.textPrimary),
                  ),
                ),
              ),
              Flexible(
                child: OptionsGrid<T>(
                  options: options,
                  columns: columns,
                  selected: selected,
                  onSelected: (value) => Navigator.of(context).pop(value),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
