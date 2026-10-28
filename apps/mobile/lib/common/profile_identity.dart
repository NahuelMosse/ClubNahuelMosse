// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';

/// The initials in their accent square, with the name and the email beside it.
class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({
    super.key,
    required this.initials,
    required this.name,
    required this.email,
  });

  final String initials;
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.accentBase,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            initials,
            style: Texts.display.copyWith(color: p.accentOn),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Texts.h2.copyWith(
                  letterSpacing: 0,
                  color: p.textOnMedia,
                ),
              ),
              Text(
                email,
                style: Texts.caption.copyWith(color: p.textOnMediaMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
