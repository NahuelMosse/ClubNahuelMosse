import 'package:flutter/material.dart';

/// La foto del club con el degradé del prototipo, que asegura el contraste del texto.
class FondoDeInicioSesion extends StatelessWidget {
  const FondoDeInicioSesion({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.42, 0.72, 1],
            colors: [
              Color(0x94000000),
              Color(0xB3000000),
              Color(0xCC000000),
              Color(0xF0000000),
            ],
          ),
        ),
        child: Image(
          image: AssetImage('assets/imagenes/login.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
