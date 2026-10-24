import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema/tokens.dart';

/// Duraciones y curvas del movimiento de la app. Cada animación corre una vez, con un
/// `AnimationController` propio, y con reducir movimiento muestra su estado final.
abstract final class Movimiento {
  static const Curve salida = Curves.easeOut;
  static const Curve suave = Curves.easeOutCubic;
  static const Curve rapida = Curves.easeOutQuart;
  static const Curve rebote = Curves.easeOutBack;

  static const avanzar = Duration(milliseconds: 320);
  static const volver = Duration(milliseconds: 280);
  static const fundido = Duration(milliseconds: 250);
  static const cambioDeLista = Duration(milliseconds: 150);
  static const temblor = Duration(milliseconds: 360);
  static const latido = Duration(milliseconds: 500);
  static const presion = Duration(milliseconds: 80);
  static const entrada = Duration(milliseconds: 400);
  static const paso = Duration(milliseconds: 80);
  static const subida = Duration(milliseconds: 450);
}

/// Arranca [controlador] una vez, salvo con reducir movimiento: ahí queda en su final.
void _arrancar(AnimationController controlador, BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) {
    controlador.value = 1;
  } else {
    unawaited(controlador.forward());
  }
}

/// Hace aparecer a [child] con un fundido, corrido de lugar, a escala y girado, hasta
/// quedar en su sitio. Espera [retraso] antes de empezar.
class Aparecer extends StatefulWidget {
  const Aparecer({
    super.key,
    required this.child,
    this.retraso = Duration.zero,
    this.duracion = Movimiento.entrada,
    this.desdeX = 0,
    this.desdeY = 20,
    this.escalaDesde = 1,
    this.giro = 0,
    this.curva = Movimiento.salida,
    this.yaEntro = false,
  });

  final Widget child;
  final Duration retraso;
  final Duration duracion;
  final double desdeX;
  final double desdeY;
  final double escalaDesde;

  /// Vueltas que le faltan para llegar a su posición.
  final double giro;

  /// La curva del desplazamiento, la escala y el giro; el fundido es siempre easeOut.
  final Curve curva;

  /// Nace en su estado final, sin animar: para un bloque que vuelve a armarse en una
  /// pantalla que ya hizo su entrada.
  final bool yaEntro;

  @override
  State<Aparecer> createState() => _AparecerState();
}

class _AparecerState extends State<Aparecer>
    with SingleTickerProviderStateMixin {
  late final _controlador = AnimationController(
    vsync: this,
    duration: widget.retraso + widget.duracion,
  );
  late final double _comienzo =
      widget.retraso.inMicroseconds /
      (widget.retraso + widget.duracion).inMicroseconds;
  late final Animation<double> _avance = _controlador.drive(
    CurveTween(curve: _ConRetraso(_comienzo, Movimiento.salida)),
  );
  late final Animation<double> _recorrido = _controlador.drive(
    CurveTween(curve: _ConRetraso(_comienzo, widget.curva)),
  );
  bool _arrancado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arrancado) return;
    _arrancado = true;
    if (widget.yaEntro) {
      _controlador.value = 1;
    } else {
      _arrancar(_controlador, context);
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _avance,
    alwaysIncludeSemantics: true,
    child: AnimatedBuilder(
      animation: _recorrido,
      child: widget.child,
      builder: (context, hijo) {
        final resto = 1 - _recorrido.value;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(
            widget.desdeX * resto,
            widget.desdeY * resto,
            0,
          )..multiply(Matrix4.rotationZ(widget.giro * resto * 2 * math.pi)),
          child: Transform.scale(
            scale:
                widget.escalaDesde +
                (1 - widget.escalaDesde) * _recorrido.value,
            child: hijo,
          ),
        );
      },
    ),
  );
}

/// [curva] desde [comienzo] hasta el final; antes de [comienzo] vale 0 exacto, sin el
/// ruido de la aproximación de las curvas cúbicas.
class _ConRetraso extends Curve {
  const _ConRetraso(this.comienzo, this.curva);

  final double comienzo;
  final Curve curva;

  @override
  double transformInternal(double t) {
    final x = (t - comienzo) / (1 - comienzo);
    if (x <= 1e-6) return 0;
    if (x >= 1) return 1;
    return curva.transform(x);
  }
}

/// Hace aparecer a [hijos] uno tras otro: el primero a los [inicio] y cada siguiente [paso]
/// después del anterior.
class EntradaEscalonada extends StatelessWidget {
  const EntradaEscalonada({
    super.key,
    required this.hijos,
    this.inicio = Duration.zero,
    this.paso = Movimiento.paso,
    this.duracion = Movimiento.entrada,
    this.desdeY = 20,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> hijos;
  final Duration inicio;
  final Duration paso;
  final Duration duracion;
  final double desdeY;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: crossAxisAlignment,
    children: [
      for (var i = 0; i < hijos.length; i++)
        Aparecer(
          retraso: inicio + paso * i,
          duracion: duracion,
          desdeY: desdeY,
          child: hijos[i],
        ),
    ],
  );
}

/// Sacude a [child] de lado a lado una vez cada vez que [disparador] pasa a un valor
/// no nulo distinto del anterior.
class Temblor extends StatefulWidget {
  const Temblor({super.key, required this.disparador, required this.child});

  final Object? disparador;
  final Widget child;

  @override
  State<Temblor> createState() => _TemblorState();
}

class _TemblorState extends State<Temblor> with SingleTickerProviderStateMixin {
  static const _puntos = [0.0, -9.0, 9.0, -6.0, 6.0, -3.0, 0.0];

  late final _controlador = AnimationController(
    vsync: this,
    duration: Movimiento.temblor,
  );

  @override
  void didUpdateWidget(Temblor anterior) {
    super.didUpdateWidget(anterior);
    final disparador = widget.disparador;
    if (disparador == null || disparador == anterior.disparador) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    unawaited(_controlador.forward(from: 0));
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  double _desplazamiento(double avance) {
    final tramos = _puntos.length - 1;
    final i = math.min((avance * tramos).floor(), tramos - 1);
    final fraccion = avance * tramos - i;
    return _puntos[i] + (_puntos[i + 1] - _puntos[i]) * fraccion;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controlador,
    child: widget.child,
    builder: (context, hijo) => Transform.translate(
      offset: Offset(_desplazamiento(_controlador.value), 0),
      child: hijo,
    ),
  );
}

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
    _arrancar(_controlador, context);
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

/// Hace latir a [child] (escala 1 → 1,03 → 1) cada vez que [disparador] cambia a un valor
/// no nulo distinto del anterior.
class Latido extends StatefulWidget {
  const Latido({super.key, required this.disparador, required this.child});

  final Object? disparador;
  final Widget child;

  @override
  State<Latido> createState() => _LatidoState();
}

class _LatidoState extends State<Latido> with SingleTickerProviderStateMixin {
  late final _controlador = AnimationController(
    vsync: this,
    duration: Movimiento.latido,
  );
  late final Animation<double> _escala = _controlador.drive(
    TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.03,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.03,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]),
  );

  @override
  void didUpdateWidget(Latido anterior) {
    super.didUpdateWidget(anterior);
    final disparador = widget.disparador;
    if (disparador == null || disparador == anterior.disparador) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    unawaited(_controlador.forward(from: 0));
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _escala, child: widget.child);
}

/// Achica a [child] a 0,97 mientras un dedo lo presiona. No toma el gesto: lo que haya
/// adentro sigue recibiéndolo.
class Presionable extends StatefulWidget {
  const Presionable({super.key, required this.child});

  final Widget child;

  @override
  State<Presionable> createState() => _PresionableState();
}

class _PresionableState extends State<Presionable>
    with SingleTickerProviderStateMixin {
  late final _controlador = AnimationController(
    vsync: this,
    duration: Movimiento.presion,
  );
  late final Animation<double> _escala = _controlador.drive(
    Tween<double>(
      begin: 1,
      end: 0.97,
    ).chain(CurveTween(curve: Movimiento.salida)),
  );
  int _dedos = 0;

  void _bajar() {
    _dedos++;
    if (MediaQuery.disableAnimationsOf(context)) return;
    unawaited(_controlador.forward());
  }

  void _subir() {
    if (!mounted) return;
    if (_dedos > 0) _dedos--;
    if (_dedos == 0) unawaited(_controlador.reverse());
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _bajar(),
    onPointerUp: (_) => _subir(),
    onPointerCancel: (_) => _subir(),
    child: ScaleTransition(scale: _escala, child: widget.child),
  );
}

/// El festejo de la reserva confirmada: aros que giran, chispas, el [grito] que crece y,
/// después, el [comprobante]. Corre una vez.
class Festejo extends StatefulWidget {
  const Festejo({super.key, required this.grito, required this.comprobante});

  final Widget grito;
  final Widget comprobante;

  @override
  State<Festejo> createState() => _FestejoState();
}

class _FestejoState extends State<Festejo> with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 2300);
  static const _inicioChispas = Duration(milliseconds: 370);
  static const _duracionChispas = Duration(milliseconds: 450);
  static const _inicioGrito = Duration(milliseconds: 420);
  static const _duracionGrito = Duration(milliseconds: 500);
  static const _inicioComprobante = Duration(milliseconds: 870);
  static const _duracionComprobante = Duration(milliseconds: 700);
  static const _lado = 280.0;

  late final _controlador = AnimationController(vsync: this, duration: _total);
  bool _arrancado = false;

  double _fraccion(Duration d) => d.inMicroseconds / _total.inMicroseconds;

  Interval _tramo(
    Duration inicio,
    Duration duracion, [
    Curve curva = Curves.linear,
  ]) => Interval(_fraccion(inicio), _fraccion(inicio + duracion), curve: curva);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arrancado) return;
    _arrancado = true;
    _arrancar(_controlador, context);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final giro = _controlador.drive(
      Tween<double>(
        begin: 0,
        end: -1 / 3,
      ).chain(CurveTween(curve: Movimiento.salida)),
    );
    final chispa = _controlador.drive(
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0,
            end: 1.6,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.6,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
      ]).chain(CurveTween(curve: _tramo(_inicioChispas, _duracionChispas))),
    );
    final gritoEscala = _controlador.drive(
      Tween<double>(begin: 0.55, end: 1).chain(
        CurveTween(
          curve: _tramo(_inicioGrito, _duracionGrito, Movimiento.rebote),
        ),
      ),
    );
    final gritoOpacidad = _controlador.drive(
      CurveTween(
        curve: _tramo(
          _inicioGrito,
          const Duration(milliseconds: 200),
          Movimiento.salida,
        ),
      ),
    );
    final colores = [p.accentBase, p.stateSuccess];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _lado,
          height: _lado,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RotationTransition(
                turns: giro,
                child: CustomPaint(
                  size: const Size.square(_lado),
                  painter: _Aros(p.accentBase, p.accentMuted),
                ),
              ),
              for (var i = 0; i < 8; i++)
                Transform.translate(
                  offset: Offset.fromDirection(
                    i * math.pi / 4 + math.pi / 8,
                    118,
                  ),
                  child: ScaleTransition(
                    scale: chispa,
                    child: Container(
                      width: i.isEven ? 10 : 7,
                      height: i.isEven ? 10 : 7,
                      decoration: BoxDecoration(
                        color: colores[i % colores.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              FadeTransition(
                opacity: gritoOpacidad,
                alwaysIncludeSemantics: true,
                child: ScaleTransition(scale: gritoEscala, child: widget.grito),
              ),
            ],
          ),
        ),
        Aparecer(
          retraso: _inicioComprobante,
          duracion: _duracionComprobante,
          desdeY: 24,
          child: widget.comprobante,
        ),
      ],
    );
  }
}

/// Tres aros concéntricos, cada uno con una marca para que se note que giran.
class _Aros extends CustomPainter {
  _Aros(this.trazo, this.marca);

  final Color trazo;
  final Color marca;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final linea = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final punto = Paint()..color = trazo;
    for (var i = 0; i < 3; i++) {
      final radio = 62.0 + 34 * i;
      canvas.drawCircle(
        centro,
        radio,
        linea..color = Color.lerp(trazo, marca, i / 3)!.withValues(alpha: 0.55),
      );
      canvas.drawCircle(
        centro + Offset.fromDirection(math.pi * (0.4 + 0.7 * i), radio),
        4,
        punto,
      );
    }
  }

  @override
  bool shouldRepaint(_Aros anterior) =>
      anterior.trazo != trazo || anterior.marca != marca;
}
