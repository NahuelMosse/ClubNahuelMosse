// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'bib.dart';
import 'marker.dart';
import 'profile_header.dart';
import 'profile_identity.dart';
import 'profile_photo.dart';

/// Member card: initials, name, email and a stats [AppMarker], with a big jersey number in the background.
class MemberProfile extends StatelessWidget {
  const MemberProfile({
    super.key,
    required this.initials,
    required this.name,
    required this.email,
    required this.stats,
    this.image,
    this.number,
  });

  final String initials;
  final String name;
  final String email;
  final List<MarkerCell> stats;
  final ImageProvider? image;
  final String? number;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final photo = image;
    final radius = BorderRadius.circular(24);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: radius,
        border: Border.all(color: p.accentBase, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            if (photo != null)
              Positioned.fill(child: ProfilePhoto(image: photo)),
            Positioned(
              top: -10,
              right: -6,
              child: GiantBib(
                text: '10',
                size: 170,
                color: p.accentBase.withValues(alpha: 0.28),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileHeader(number: number),
                  const SizedBox(height: 18),
                  ProfileIdentity(initials: initials, name: name, email: email),
                  if (stats.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    AppMarker(cells: stats),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
