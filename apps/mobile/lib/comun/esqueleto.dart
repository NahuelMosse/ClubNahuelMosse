import 'package:flutter/material.dart';

import '../tema/tokens.dart';

/// Un bloque gris redondeado: el lugar de algo que todavía no llegó.
class Esqueleto extends StatelessWidget {
  const Esqueleto({
    super.key,
    this.width,
    required this.alto,
    this.radio = Medidas.radioMd,
  });

  final double? width;
  final double alto;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: alto,
      decoration: BoxDecoration(
        color: oscuro ? p.bgSurfaceRaised : p.bgSurface,
        borderRadius: BorderRadius.circular(radio),
      ),
    );
  }
}

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

/// La forma de lo que va a aparecer en una lista.
enum FormaDeEsqueleto { sede, cancha, reserva, aviso, grilla }

/// Los bloques de una lista que carga, con la forma de la tarjeta real.
class EsqueletoDeLista extends StatelessWidget {
  const EsqueletoDeLista({super.key, required this.forma, this.cantidad = 3});

  final FormaDeEsqueleto forma;
  final int cantidad;

  @override
  Widget build(BuildContext context) => ZonaDeEsqueletos(
    child: SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cantidad; i++) ...[
            if (i > 0) SizedBox(height: _separacion),
            _fila(),
          ],
        ],
      ),
    ),
  );

  double get _separacion =>
      forma == FormaDeEsqueleto.grilla ? Medidas.s8 : Medidas.s12;

  Widget _fila() => switch (forma) {
    FormaDeEsqueleto.sede => const Esqueleto(alto: 220, radio: Medidas.radioLg),
    FormaDeEsqueleto.cancha => const Esqueleto(alto: 96),
    FormaDeEsqueleto.reserva => const Esqueleto(alto: 112),
    FormaDeEsqueleto.aviso => const _Aviso(),
    FormaDeEsqueleto.grilla => const Row(
      children: [
        Expanded(child: Esqueleto(alto: Medidas.altoControl)),
        SizedBox(width: Medidas.s8),
        Expanded(child: Esqueleto(alto: Medidas.altoControl)),
      ],
    ),
  };
}

class _Aviso extends StatelessWidget {
  const _Aviso();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 76,
    child: Row(
      children: [
        Esqueleto(width: 40, alto: 40),
        SizedBox(width: Medidas.s12),
        Expanded(child: Esqueleto(alto: 40)),
      ],
    ),
  );
}
