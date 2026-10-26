import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/resultado.dart';
import '../tema/tokens.dart';

class PantallaRegistroExitoso extends StatelessWidget {
  const PantallaRegistroExitoso({super.key});

  @override
  Widget build(BuildContext context) => PantallaResultado(
    icono: Icons.check_circle_outline_rounded,
    tono: TonoResultado.exito,
    titulo: '¡Cuenta creada!',
    texto:
        'Tu cuenta se registró con éxito. Ya podés iniciar sesión con tu correo y contraseña.',
    principal: 'VOLVER AL INICIO DE SESIÓN',
    alTocarPrincipal: () => context.go('/'),
    diametro: 100,
    tamanoIcono: 44,
    separacionIcono: Medidas.s20,
    separacionTitulo: Medidas.s20,
    separacionAcciones: 36,
  );
}
