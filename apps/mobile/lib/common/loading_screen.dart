// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'logo_mark.dart';

/// Startup wait: the dark logo mark on the electric green, like the native screen, with a
/// progress indicator below because the API may take time to wake up.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  /// Dark in both themes: the accent would not show on the green.
  static final _ink = Palette.dark.textInverse;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.palette.accentBase,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LogoMark(size: 120, decorative: true, color: _ink),
          const SizedBox(height: 32),
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(color: _ink, strokeWidth: 3),
          ),
        ],
      ),
    ),
  );
}
