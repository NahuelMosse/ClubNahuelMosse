import 'package:flutter/material.dart';

/// La foto de fondo de la ficha, con un velo oscuro que sube hacia abajo.
class FotoDeFicha extends StatelessWidget {
  const FotoDeFicha({super.key, required this.imagen});

  final ImageProvider imagen;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image(image: imagen, fit: BoxFit.cover),
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
