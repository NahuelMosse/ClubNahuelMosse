import 'package:flutter/material.dart';

/// The profile background photo, with a dark veil that deepens toward the bottom.
class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({super.key, required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image(image: image, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x66000000), Color(0xD9000000)],
            ),
          ),
        ),
      ],
    );
  }
}
