import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';

enum AvatarSize {
  small(40, 15),
  medium(48, 17),
  large(76, 24);

  const AvatarSize(this.side, this.fontSize);
  final double side;
  final double fontSize;
}

/// `Avatar-Iniciales` from the prototype: a lime circle with the first-name and last-name initials.
class AvatarInitials extends StatelessWidget {
  const AvatarInitials({
    super.key,
    required this.firstName,
    required this.lastName,
    this.size = AvatarSize.medium,
  });

  final String firstName;
  final String lastName;
  final AvatarSize size;

  static String initials(String firstName, String lastName) =>
      [firstName, lastName]
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .map((part) => String.fromCharCode(part.runes.first).toUpperCase())
          .join();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final large = size == AvatarSize.large;
    return ExcludeSemantics(
      child: Container(
        width: size.side,
        height: size.side,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: p.accentBase, shape: BoxShape.circle),
        child: Text(
          initials(firstName, lastName),
          textScaler: TextScaler.noScaling,
          style: (large ? Texts.h1 : Texts.title).copyWith(
            color: p.accentOn,
            fontSize: size.fontSize,
          ),
        ),
      ),
    );
  }
}
