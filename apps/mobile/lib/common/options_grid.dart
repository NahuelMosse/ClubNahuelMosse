// kit-shape: the grid and its private option are read together and not used separately
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';

/// The options of [pickOption] in [columns] columns, with the [selected] one marked.
///
/// All are built at once: there are few, so any of them can be reached without the list
/// discarding them.
class OptionsGrid<T> extends StatelessWidget {
  const OptionsGrid({
    super.key,
    required this.options,
    required this.columns,
    required this.onSelected,
    this.selected,
  });

  final List<(T, String)> options;
  final int columns;
  final ValueChanged<T> onSelected;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.s12,
        0,
        Spacing.s12,
        Spacing.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < options.length; i += columns)
            Row(
              children: [
                for (var j = i; j < i + columns; j++)
                  Expanded(
                    child: j < options.length
                        ? _Option(
                            text: options[j].$2,
                            selected: options[j].$1 == selected,
                            centered: columns > 1,
                            onTap: () => onSelected(options[j].$1),
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.text,
    required this.selected,
    required this.centered,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool centered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? p.accentMuted : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: Spacing.touchTarget + 4,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.s12),
              child: Row(
                mainAxisAlignment: centered
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      style: (selected ? Texts.bodyStrong : Texts.body)
                          .copyWith(color: p.textPrimary),
                    ),
                  ),
                  if (selected && !centered) ...[
                    const Spacer(),
                    Icon(Icons.check_rounded, size: 20, color: p.accentInk),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
