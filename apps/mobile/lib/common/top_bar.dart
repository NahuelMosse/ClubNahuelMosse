// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';

/// The prototype `AppBar`: back on the left and the title.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final goBack = onBack ?? () => Navigator.of(context).maybePop();
    return AppBar(
      backgroundColor: p.bgBase,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: kToolbarHeight,
      titleSpacing: 0,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: Spacing.s12),
        // The Flutter tooltip is not the button label: without this, the screen reader
        // announces it as «Volver» but it cannot be found by name.
        child: Semantics(
          button: true,
          label: 'Volver',
          onTap: goBack,
          excludeSemantics: true,
          child: IconButton(
            tooltip: 'Volver',
            onPressed: goBack,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: p.textPrimary,
              size: 28,
            ),
          ),
        ),
      ),
      title: Text(title, style: Texts.title.copyWith(color: p.textPrimary)),
    );
  }
}
