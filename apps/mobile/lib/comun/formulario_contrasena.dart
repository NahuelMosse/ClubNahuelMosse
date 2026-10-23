import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'barra_superior.dart';
import 'boton.dart';
import 'campo_texto.dart';
import 'resultado.dart';

/// El campo de una contraseña con su ojo: [visible] dice si se ve, [alAlternar] lo cambia.
/// Con [alEnviar] el teclado cierra la carga (es el último campo).
CampoTexto campoDeContrasena({
  required String etiqueta,
  required String accesible,
  required String placeholder,
  required TextEditingController controlador,
  required bool visible,
  required bool habilitado,
  required VoidCallback alAlternar,
  required String autocompletar,
  String? error,
  FocusNode? foco,
  ValueChanged<String>? alEnviar,
}) => CampoTexto(
  etiqueta: etiqueta,
  etiquetaAccesible: accesible,
  controlador: controlador,
  foco: foco,
  placeholder: placeholder,
  error: error,
  oculto: !visible,
  habilitado: habilitado,
  autocompletar: [autocompletar],
  accion: alEnviar != null ? TextInputAction.done : TextInputAction.next,
  alEnviar: alEnviar,
  accionFinal: VerContrasena(visible: visible, alCambiar: alAlternar),
);

/// La pantalla de «Contraseña actualizada» con su acción principal.
class ContrasenaActualizada extends StatelessWidget {
  const ContrasenaActualizada({
    super.key,
    required this.principal,
    required this.alTocarPrincipal,
  });

  final String principal;
  final VoidCallback alTocarPrincipal;

  @override
  Widget build(BuildContext context) => PantallaResultado(
    icono: Icons.check_circle_outline_rounded,
    tono: TonoResultado.exito,
    titulo: 'Contraseña actualizada',
    texto:
        'Tu contraseña se cambió correctamente. Usala la próxima vez que '
        'inicies sesión.',
    principal: principal,
    alTocarPrincipal: alTocarPrincipal,
  );
}

/// El formulario de una contraseña: barra, título, explicación, [campos] y el botón de
/// guardar, que se habilita con [alGuardar].
class PlantillaDeContrasena extends StatelessWidget {
  const PlantillaDeContrasena({
    super.key,
    required this.barra,
    required this.titulo,
    required this.explicacion,
    required this.campos,
    required this.enviando,
    required this.alGuardar,
  });

  final BarraSuperior barra;
  final String titulo;
  final String explicacion;
  final List<Widget> campos;
  final bool enviando;
  final VoidCallback? alGuardar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Scaffold(
      backgroundColor: p.bgBase,
      appBar: barra,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s12,
            Medidas.s24,
            Medidas.s40,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                titulo,
                style: Textos.h1.copyWith(color: p.textPrimary),
              ),
            ),
            const SizedBox(height: Medidas.s4),
            Text(
              explicacion,
              style: Textos.cuerpo.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Medidas.s16),
            ...campos,
          ],
        ),
      ),
      bottomNavigationBar: BarraDeAccion(
        child: BotonPrimario(
          texto: 'GUARDAR CONTRASEÑA',
          cargando: enviando,
          alTocar: alGuardar,
        ),
      ),
    );
  }
}
