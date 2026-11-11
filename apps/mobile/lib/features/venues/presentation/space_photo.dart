// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/label.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import 'photos.dart';

/// The photo of the sport of the court, with its type on top and its name below.
class SpacePhoto extends StatelessWidget {
  const SpacePhoto({super.key, required this.space, required this.kind});

  final Space space;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 180,
      child: PhotoWithScrim(
        image: sportPhoto(space.sport),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppLabel(text: kind, onPhoto: true),
              Text(
                space.name,
                style: Texts.mono.copyWith(fontSize: 12, color: p.textOnMedia),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
