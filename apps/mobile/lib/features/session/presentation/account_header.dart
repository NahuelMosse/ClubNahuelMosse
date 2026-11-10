import 'package:flutter/material.dart';

import '../../../common/avatar.dart';
import '../../../common/badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/profile.dart';
import '../domain/role.dart';

/// The avatar of whoever has the session open, with their name, their email and, if a
/// user, the member badge.
class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isUser = profile.role == Role.user;
    return Padding(
      padding: const EdgeInsets.all(Spacing.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarInitials(
            firstName: profile.firstName,
            lastName: profile.lastName,
          ),
          const SizedBox(width: Spacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.firstName} ${profile.lastName}',
                  style: Texts.title.copyWith(color: p.textPrimary),
                ),
                const SizedBox(height: Spacing.s4),
                Text(
                  profile.email,
                  style: Texts.caption.copyWith(color: p.textMuted),
                ),
                if (isUser) ...[
                  const SizedBox(height: Spacing.s4),
                  AccentBadge(
                    label: AppLocalizations.of(context).accountActiveMember,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
