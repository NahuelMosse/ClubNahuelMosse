import 'package:flutter/material.dart';

/// A button of the card, which says which booking it belongs to.
class BookingAction extends StatelessWidget {
  const BookingAction({
    super.key,
    required this.expand,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final bool expand;
  final String label;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      label: label,
      excludeSemantics: true,
      button: true,
      enabled: onTap != null,
      onTap: onTap,
      child: child,
    );
    return expand ? Expanded(child: button) : button;
  }
}
