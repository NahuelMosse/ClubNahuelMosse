import 'package:flutter/material.dart';

import '../comun/campo_texto.dart';
import '../comun/formato_fecha.dart';
import '../tema/tokens.dart';
import 'campo_de_registro.dart';

/// Los seis campos del registro, uno debajo del otro.
class FormularioDeRegistro extends StatelessWidget {
  const FormularioDeRegistro({
    super.key,
    required this.controladores,
    required this.focos,
    required this.errorDe,
    required this.enviando,
    required this.contrasenaVisible,
    required this.alElegirFecha,
    required this.alCambiarVisibilidad,
  });

  /// Uno por campo, en el orden de [CampoDeRegistro].
  final List<TextEditingController> controladores;
  final List<FocusNode> focos;
  final String? Function(CampoDeRegistro campo) errorDe;
  final bool enviando;
  final bool contrasenaVisible;
  final VoidCallback alElegirFecha;
  final VoidCallback alCambiarVisibilidad;

  CampoTexto _campo(
    CampoDeRegistro campo, {
    required String etiqueta,
    required String accesible,
    required String placeholder,
    TextInputType? teclado,
    Widget? accionFinal,
    bool oculto = false,
    Iterable<String>? autocompletar,
  }) {
    return CampoTexto(
      etiqueta: etiqueta,
      etiquetaAccesible: accesible,
      controlador: controladores[campo.index],
      foco: focos[campo.index],
      placeholder: placeholder,
      error: errorDe(campo),
      teclado: teclado,
      oculto: oculto,
      habilitado: !enviando,
      accionFinal: accionFinal,
      autocompletar: autocompletar,
      accion: campo == CampoDeRegistro.contrasena
          ? TextInputAction.done
          : TextInputAction.next,
      formateadores: switch (campo) {
        CampoDeRegistro.dni => [formatoDni],
        CampoDeRegistro.fechaNacimiento => const [FormatoFecha()],
        _ => null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _campo(
          CampoDeRegistro.nombre,
          etiqueta: 'NOMBRE',
          accesible: 'Nombre',
          placeholder: 'Tu nombre',
          teclado: TextInputType.name,
          autocompletar: const [AutofillHints.givenName],
        ),
        const SizedBox(height: Medidas.s16),
        _campo(
          CampoDeRegistro.apellido,
          etiqueta: 'APELLIDO',
          accesible: 'Apellido',
          placeholder: 'Tu apellido',
          teclado: TextInputType.name,
          autocompletar: const [AutofillHints.familyName],
        ),
        const SizedBox(height: Medidas.s16),
        _campo(
          CampoDeRegistro.dni,
          etiqueta: 'DNI',
          accesible: 'DNI',
          placeholder: '00.000.000',
          teclado: TextInputType.number,
        ),
        const SizedBox(height: Medidas.s16),
        _campo(
          CampoDeRegistro.fechaNacimiento,
          etiqueta: 'FECHA DE NACIMIENTO',
          accesible: 'Fecha de nacimiento',
          placeholder: 'DD / MM / AAAA',
          teclado: TextInputType.number,
          accionFinal: IconButton(
            tooltip: 'Elegir fecha',
            onPressed: enviando ? null : alElegirFecha,
            icon: Icon(Icons.calendar_today_outlined, color: p.textSecondary),
          ),
        ),
        const SizedBox(height: Medidas.s16),
        _campo(
          CampoDeRegistro.correo,
          etiqueta: 'CORREO ELECTRÓNICO',
          accesible: 'Correo electrónico',
          placeholder: 'tu@correo.com',
          teclado: TextInputType.emailAddress,
          autocompletar: const [AutofillHints.email],
        ),
        const SizedBox(height: Medidas.s16),
        _campo(
          CampoDeRegistro.contrasena,
          etiqueta: 'CONTRASEÑA',
          accesible: 'Contraseña',
          placeholder: '8+ caracteres, mayúscula y número',
          oculto: !contrasenaVisible,
          autocompletar: const [AutofillHints.newPassword],
          accionFinal: VerContrasena(
            visible: contrasenaVisible,
            alCambiar: alCambiarVisibilidad,
          ),
        ),
      ],
    );
  }
}
