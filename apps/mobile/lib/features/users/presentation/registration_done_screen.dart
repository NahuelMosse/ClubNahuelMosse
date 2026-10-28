import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/result.dart';
import '../../../theme/tokens.dart';

class RegistrationDoneScreen extends StatelessWidget {
  const RegistrationDoneScreen({super.key});

  @override
  Widget build(BuildContext context) => ResultScreen(
    icon: Icons.check_circle_outline_rounded,
    tone: ResultTone.success,
    title: '¡Cuenta creada!',
    text:
        'Tu cuenta se registró con éxito. Ya podés iniciar sesión con tu correo y contraseña.',
    primary: 'VOLVER AL INICIO DE SESIÓN',
    onPrimaryTap: () => context.go('/'),
    diameter: 100,
    iconSize: 44,
    iconGap: Spacing.s20,
    titleGap: Spacing.s20,
    actionsGap: 36,
  );
}
