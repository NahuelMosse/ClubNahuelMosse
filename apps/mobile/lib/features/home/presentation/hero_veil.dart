import 'package:flutter/material.dart';

/// The dark gradient at the top of the photo, so the greeting can be read.
class HeroVeil extends StatelessWidget {
  const HeroVeil({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.5],
            colors: [Color(0x99000000), Color(0x00000000)],
          ),
        ),
      ),
    );
  }
}
