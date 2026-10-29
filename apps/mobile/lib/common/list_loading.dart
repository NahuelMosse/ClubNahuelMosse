// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import 'button.dart';
import 'motion.dart';

/// What shows in place of a list when its read failed: REINTENTAR.
class ListRetry extends StatelessWidget {
  const ListRetry({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Spacing.s24),
    child: Center(
      child: TextActionButton(
        label: AppLocalizations.of(context).commonRetry,
        onTap: onTap,
      ),
    ),
  );
}

/// The switch between the lists of two filters or tabs, without animating if the person
/// asked for less motion.
class ListSwitcher extends StatelessWidget {
  const ListSwitcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.listChange,
    layoutBuilder: (current, previous) => Stack(
      alignment: Alignment.topCenter,
      children: [...previous, ?current],
    ),
    child: child,
  );
}
