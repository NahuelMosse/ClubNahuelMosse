import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/boton.dart';
import '../comun/campo_texto.dart';
import '../tema/tokens.dart';

/// Correo y contraseña, con el enlace para recuperarla.
class CamposDeInicioSesion extends StatelessWidget {
  const CamposDeInicioSesion({
    super.key,
    required this.correo,
    required this.contrasena,
    required this.errorCorreo,
    required this.errorContrasena,
    required this.contrasenaVisible,
    required this.enviando,
    required this.alEnviar,
    required this.alCambiarVisibilidad,
  });

  final TextEditingController correo;
  final TextEditingController contrasena;
  final String? errorCorreo;
  final String? errorContrasena;
  final bool contrasenaVisible;
  final bool enviando;
  final VoidCallback alEnviar;
  final VoidCallback alCambiarVisibilidad;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTexto(
          etiquetaAccesible: 'Correo',
          placeholder: 'Correo',
          controlador: correo,
          error: errorCorreo,
          teclado: TextInputType.emailAddress,
          autocompletar: const [AutofillHints.email],
          accion: TextInputAction.next,
          habilitado: !enviando,
        ),
        const SizedBox(height: Medidas.s12),
        CampoTexto(
          etiquetaAccesible: 'Contraseña',
          placeholder: 'Contraseña',
          controlador: contrasena,
          error: errorContrasena,
          oculto: !contrasenaVisible,
          autocompletar: const [AutofillHints.password],
          accion: TextInputAction.done,
          alEnviar: (_) => alEnviar(),
          habilitado: !enviando,
          accionFinal: VerContrasena(
            visible: contrasenaVisible,
            alCambiar: alCambiarVisibilidad,
          ),
        ),
        const SizedBox(height: Medidas.s12),
        Align(
          alignment: Alignment.centerRight,
          child: BotonTexto(
            texto: '¿Olvidaste tu contraseña?',
            sobreFoto: true,
            alTocar: enviando
                ? null
                : () => context.go('/recuperar-contrasena'),
          ),
        ),
      ],
    );
  }
}
