import 'package:flutter/material.dart';

import '../../../common/motion.dart';
import '../../../common/snackbar.dart';
import '../../../theme/tokens.dart';

/// El aviso de error al pie de la pantalla; tiembla cada vez que [notices] sube.
class LoginNotice extends StatelessWidget {
  const LoginNotice({
    super.key,
    required this.notice,
    required this.notices,
    required this.onClose,
  });

  final String? notice;
  final int notices;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = notice;
    return Positioned(
      left: Spacing.s24,
      right: Spacing.s24,
      bottom: Spacing.s24 + MediaQuery.viewInsetsOf(context).bottom,
      child: SafeArea(
        top: false,
        child: Shake(
          trigger: notices,
          child: text == null
              ? const SizedBox.shrink()
              : ErrorSnackbar(message: text, onClose: onClose),
        ),
      ),
    );
  }
}
