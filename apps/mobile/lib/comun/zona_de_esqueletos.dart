import 'package:flutter/material.dart';

// kit-shape: el widget con estado y su State son un solo componente; _Deslizar es su degradé privado.

/// Reúne los bloques de una pantalla bajo un mismo brillo que los recorre. Se detiene con
/// «reducir movimiento» y el lector de pantalla dice «Cargando» una vez, sin leer los bloques.
class ZonaDeEsqueletos extends StatefulWidget {
  const ZonaDeEsqueletos({super.key, required this.child});

  final Widget child;

  @override
  State<ZonaDeEsqueletos> createState() => _ZonaDeEsqueletosState();
}

class _ZonaDeEsqueletosState extends State<ZonaDeEsqueletos>
    with SingleTickerProviderStateMixin {
  static const _vuelta = Duration(milliseconds: 1400);
  static const _brillo = Color(0x1FFFFFFF);

  late final AnimationController _reloj = AnimationController(
    vsync: this,
    duration: _vuelta,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _reloj.stop();
    } else if (!_reloj.isAnimating) {
      _reloj.repeat();
    }
  }

  @override
  void dispose() {
    _reloj.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando',
    container: true,
    child: ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _reloj,
        child: widget.child,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (area) => LinearGradient(
            colors: const [Color(0x00FFFFFF), _brillo, Color(0x00FFFFFF)],
            transform: _Deslizar(_reloj.value),
          ).createShader(area),
          child: child,
        ),
      ),
    ),
  );
}

/// Corre el degradé de un borde al otro del área.
class _Deslizar extends GradientTransform {
  const _Deslizar(this.avance);

  final double avance;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (avance * 2 - 1), 0, 0);
}
