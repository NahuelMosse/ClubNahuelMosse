import 'package:flutter/material.dart';

import '../../../common/avatar.dart';
import '../../../common/member_profile.dart';
import '../../../common/motion.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/profile.dart';
import '../../venues/presentation/photos.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.bgHeroFrom, p.bgHeroTo],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.s24,
            Spacing.s24,
            Spacing.s24,
            Spacing.s24,
          ),
          child: FadeIn(
            duration: const Duration(milliseconds: 550),
            fromY: -24,
            turn: -3 / 360,
            curve: AppMotion.smooth,
            child: MemberProfile(
              initials: AvatarInitials.initials(
                profile.firstName,
                profile.lastName,
              ),
              name: '${profile.firstName} ${profile.lastName}',
              email: profile.email,
              number: 'MIEMBRO ACTIVO',
              stats: const [],
              image: sportPhoto('Futbol'),
            ),
          ),
        ),
      ),
    );
  }
}
