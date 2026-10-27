// kit-shape: el widget, su State y el recorte de revelado son una sola pieza de Flutter
import 'package:flutter/material.dart';

import 'tiempos.dart';

/// El círculo de un resultado: crece de 0,4 a 1 con rebote y, desde los 170 ms, revela
/// el ícono con un recorte que se abre.
class PulsoDeExito extends StatefulWidget {
  const PulsoDeExito({
    super.key,
    required this.icono,
    required this.fondo,
    required this.tinta,
    this.diametro = 96,
    this.tamanoIcono = 40,
  });

  final IconData icono;
  final Color fondo;
  final Color tinta;
  final double diametro;
  final double tamanoIcono;

  @override
  State<PulsoDeExito> createState() => _PulsoDeExitoState();
}

class _PulsoDeExitoState extends State<PulsoDeExito>
    with SingleTickerProviderStateMixin {
  static const _escala = Duration(milliseconds: 550);
  static const _inicioDelIcono = Duration(milliseconds: 170);
  static const _duracionDelIcono = Duration(milliseconds: 450);
  static const _total = Duration(milliseconds: 620);

  late final _controlador = AnimationController(vsync: this, duration: _total);
  late final Animation<double> _tamano = _controlador.drive(
    Tween<double>(begin: 0.4, end: 1).chain(
      CurveTween(
        curve: Interval(
          0,
          _escala.inMicroseconds / _total.inMicroseconds,
          curve: Movimiento.rebote,
        ),
      ),
    ),
  );
  late final Animation<double> _revelado = _controlador.drive(
    CurveTween(
      curve: Interval(
        _inicioDelIcono.inMicroseconds / _total.inMicroseconds,
        (_inicioDelIcono + _duracionDelIcono).inMicroseconds /
            _total.inMicroseconds,
        curve: Movimiento.salida,
      ),
    ),
  );
  bool _arrancado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arrancado) return;
    _arrancado = true;
    arrancarUnaVez(_controlador, context);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _tamano,
    child: Container(
      width: widget.diametro,
      height: widget.diametro,
      decoration: BoxDecoration(color: widget.fondo, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _revelado,
        builder: (context, _) => ClipPath(
          clipper: _Revelado(_revelado.value),
          child: Icon(
            widget.icono,
            size: widget.tamanoIcono,
            color: widget.tinta,
          ),
        ),
      ),
    ),
  );
}

/// Un círculo desde el centro que crece hasta cubrir todo el ícono.
class _Revelado extends CustomClipper<Path> {
  _Revelado(this.progreso);

  final double progreso;

  @override
  Path getClip(Size size) => Path()
    ..addOval(
      Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: progreso * size.longestSide * 0.75,
      ),
    );

  @override
  bool shouldReclip(_Revelado anterior) => anterior.progreso != progreso;
}
