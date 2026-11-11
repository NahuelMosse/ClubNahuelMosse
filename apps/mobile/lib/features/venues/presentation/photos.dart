import 'package:flutter/material.dart';

/// The covers of the prototype. The administrator does not upload photos: each venue
/// takes one by its number and each court the one of its sport.
const _covers = [
  AssetImage('assets/imagenes/sedes/portada_1.jpg'),
  AssetImage('assets/imagenes/sedes/portada_2.jpg'),
  AssetImage('assets/imagenes/sedes/portada_3.jpg'),
  AssetImage('assets/imagenes/sedes/portada_4.jpg'),
];

/// The same id always gives the same cover: the sum of its characters, modulo the covers.
ImageProvider venueCover(String id) =>
    _covers[id.codeUnits.fold(0, (a, c) => a + c) % _covers.length];

ImageProvider sportPhoto(String sport) => switch (sport) {
  'Basquet' => _covers[0],
  'Tenis' || 'Padel' || 'Voley' => _covers[1],
  'Golf' => _covers[2],
  _ => _covers[3],
};

/// A photo that fills its place with a dark veil, so what goes on top can be read.
class PhotoWithScrim extends StatelessWidget {
  const PhotoWithScrim({super.key, required this.image, required this.child});

  final ImageProvider image;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.45, 1],
                  colors: [
                    Color(0x33000000),
                    Color(0x8C000000),
                    Color(0xE6000000),
                  ],
                ),
              ),
              child: Image(image: image, fit: BoxFit.cover),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
