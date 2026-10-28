import 'package:flutter/material.dart';

/// Las portadas del prototipo. El administrador no carga fotos: cada sede toma una por su
/// número y cada cancha la de su deporte.
const _covers = [
  AssetImage('assets/imagenes/sedes/portada_1.jpg'),
  AssetImage('assets/imagenes/sedes/portada_2.jpg'),
  AssetImage('assets/imagenes/sedes/portada_3.jpg'),
  AssetImage('assets/imagenes/sedes/portada_4.jpg'),
];

/// El mismo id da siempre la misma portada: la suma de sus caracteres, módulo las portadas.
ImageProvider venueCover(String id) =>
    _covers[id.codeUnits.fold(0, (a, c) => a + c) % _covers.length];

ImageProvider sportPhoto(String sport) => switch (sport) {
  'Basquet' => _covers[0],
  'Tenis' || 'Padel' || 'Voley' => _covers[1],
  'Golf' => _covers[2],
  _ => _covers[3],
};

/// Una foto que llena su lugar con un velo oscuro, para que se lea lo que va encima.
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
