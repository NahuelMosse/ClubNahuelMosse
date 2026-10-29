import 'package:flutter/material.dart';

import '../../../common/skeleton.dart';
import '../../../theme/tokens.dart';

/// Mi perfil mientras llega: la cabecera y las tres tarjetas, con la forma que tendrán.
class MyProfileSkeleton extends StatelessWidget {
  const MyProfileSkeleton({super.key});

  static const _avatar = 72.0;

  /// Lo que mide el contenido de `ProfileHeader` sin sus márgenes.
  static const _headerContent = 166.0;

  /// Lo que miden DATOS PERSONALES, SEGURIDAD y APARIENCIA una vez cargadas.
  static const _dataHeight = 320.0;
  static const _securityHeight = 108.0;
  static const _appearanceHeight = 100.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SkeletonZone(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              key: const ValueKey('skeleton-header'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [p.bgHeroFrom, p.bgHeroTo],
                ),
              ),
              child: const SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.all(Spacing.s24),
                  child: SizedBox(
                    height: _headerContent,
                    child: Row(
                      children: [
                        Skeleton(
                          width: _avatar,
                          height: _avatar,
                          radius: _avatar / 2,
                        ),
                        SizedBox(width: Spacing.s16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Skeleton(width: 160, height: 20),
                            SizedBox(height: Spacing.s8),
                            Skeleton(width: 200, height: 14),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.s24,
                Spacing.s20,
                Spacing.s24,
                Spacing.s48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Card(height: _dataHeight, border: p.borderDefault),
                  const SizedBox(height: Spacing.s16),
                  _Card(height: _securityHeight, border: p.borderDefault),
                  const SizedBox(height: Spacing.s16),
                  _Card(height: _appearanceHeight, border: p.borderDefault),
                  const SizedBox(height: Spacing.s20),
                  const Skeleton(height: 48, radius: Spacing.radiusLg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.height, required this.border});

  final double height;
  final Color border;

  /// Alto de una fila de dato con su separación.
  static const _row = 32.0;
  static const _titleSpace = 60.0;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('skeleton-card'),
    height: height,
    padding: const EdgeInsets.all(Spacing.s16),
    decoration: BoxDecoration(
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(Spacing.radiusLg),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Skeleton(width: 120, height: 12),
        ),
        for (var i = 0; i < ((height - _titleSpace) / _row).floor(); i++) ...[
          const SizedBox(height: Spacing.s12),
          const Skeleton(height: 20),
        ],
      ],
    ),
  );
}
