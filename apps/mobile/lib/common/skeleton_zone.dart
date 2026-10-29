// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

// kit-shape: the stateful widget and its State are a single component; _Slide is its private gradient.

/// Gathers the blocks of a screen under one shimmer that sweeps across them. It stops with
/// «reduce motion» and the screen reader says «Cargando» once, without reading the blocks.
class SkeletonZone extends StatefulWidget {
  const SkeletonZone({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonZone> createState() => _SkeletonZoneState();
}

class _SkeletonZoneState extends State<SkeletonZone>
    with SingleTickerProviderStateMixin {
  static const _lap = Duration(milliseconds: 1400);
  static const _shine = Color(0x1FFFFFFF);

  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: _lap,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).commonLoading,
    container: true,
    child: ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _clock,
        child: widget.child,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (area) => LinearGradient(
            colors: const [Color(0x00FFFFFF), _shine, Color(0x00FFFFFF)],
            transform: _Slide(_clock.value),
          ).createShader(area),
          child: child,
        ),
      ),
    ),
  );
}

/// Moves the gradient from one edge of the area to the other.
class _Slide extends GradientTransform {
  const _Slide(this.progress);

  final double progress;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (progress * 2 - 1), 0, 0);
}
