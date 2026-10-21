import 'package:flutter/material.dart';

/// Las portadas del prototipo. El administrador no carga fotos: cada sede toma una por su
/// número y cada cancha la de su deporte.
const _portadas = [
  AssetImage('assets/imagenes/sedes/portada_1.jpg'),
  AssetImage('assets/imagenes/sedes/portada_2.jpg'),
  AssetImage('assets/imagenes/sedes/portada_3.jpg'),
  AssetImage('assets/imagenes/sedes/portada_4.jpg'),
];

ImageProvider portadaDeSede(int id) => _portadas[id % _portadas.length];

ImageProvider fotoDeDeporte(String deporte) => switch (deporte) {
  'Basquet' => _portadas[0],
  'Tenis' || 'Padel' || 'Voley' => _portadas[1],
  'Golf' => _portadas[2],
  _ => _portadas[3],
};

/// Una foto que llena su lugar con un velo oscuro, para que se lea lo que va encima.
class FotoConVelo extends StatelessWidget {
  const FotoConVelo({super.key, required this.imagen, required this.child});

  final ImageProvider imagen;
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
              child: Image(image: imagen, fit: BoxFit.cover),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
