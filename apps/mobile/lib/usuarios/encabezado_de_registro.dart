import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/boton.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'aviso_de_registro.dart';

/// Lo que va arriba del formulario: el aviso que corresponda, el título y su bajada.
class EncabezadoDeRegistro extends StatelessWidget {
  const EncabezadoDeRegistro({
    super.key,
    required this.yaExiste,
    required this.aviso,
  });

  final bool yaExiste;
  final String? aviso;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final aviso = this.aviso;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (yaExiste) ...[
          const AvisoDeRegistro(
            texto:
                'Tu cuenta ya existe: el registro se completó antes del corte. '
                'Iniciá sesión con tu correo y tu contraseña.',
          ),
          BotonTexto(texto: 'INICIAR SESIÓN', alTocar: () => context.go('/')),
          const SizedBox(height: Medidas.s16),
        ] else if (aviso != null) ...[
          AvisoDeRegistro(texto: aviso),
          const SizedBox(height: Medidas.s16),
        ],
        Text('Creá tu cuenta', style: Textos.h1.copyWith(color: p.textPrimary)),
        const SizedBox(height: Medidas.s4),
        Text(
          'Todos los campos son obligatorios.',
          style: Textos.leyenda.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: Medidas.s16),
      ],
    );
  }
}
