import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../comun/campo_texto.dart';
import '../comun/fechas.dart';
import '../comun/selector.dart';
import '../sedes/sede.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'campo_de_sede.dart';
import 'formulario_de_sede.dart';
import 'reglas_de_sede.dart';

/// Los campos del formulario de una sede: nombre, dirección, apertura, cierre y días.
class CuerpoDeFormularioDeSede extends StatelessWidget {
  const CuerpoDeFormularioDeSede({
    super.key,
    required this.formulario,
    required this.alElegirHora,
    required this.alElegirDias,
  });

  final FormularioDeSede formulario;
  final void Function(CampoDeSede) alElegirHora;
  final VoidCallback alElegirDias;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final f = formulario;
    final editando = f.editando;
    return SingleChildScrollView(
      padding: Medidas.paginaDeFormulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              editando?.nombre ?? 'Nueva sede',
              style: Textos.h1.copyWith(color: p.textPrimary),
            ),
          ),
          const SizedBox(height: Medidas.s4),
          Text(
            'Nombre, dirección y horarios son obligatorios.',
            style: Textos.cuerpo.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: Medidas.s16),
          CampoTexto(
            etiqueta: 'NOMBRE DE LA SEDE',
            etiquetaAccesible: 'Nombre de la sede',
            controlador: f.nombre,
            foco: f.focoNombre,
            placeholder: 'Ej. Sede Haedo',
            error: f.error(CampoDeSede.nombre),
            habilitado: !f.ocupado,
            accion: TextInputAction.next,
            formateadores: [
              LengthLimitingTextInputFormatter(largoDelNombreDeSede),
            ],
          ),
          const SizedBox(height: Medidas.s12),
          CampoTexto(
            etiqueta: 'DIRECCIÓN',
            etiquetaAccesible: 'Dirección',
            controlador: f.direccion,
            foco: f.focoDireccion,
            placeholder: editando == null
                ? 'Calle y altura'
                : 'Escribí la dirección',
            error: f.error(CampoDeSede.direccion),
            habilitado: !f.ocupado,
            teclado: TextInputType.streetAddress,
            autocompletar: const [AutofillHints.streetAddressLine1],
            accion: TextInputAction.done,
            formateadores: [
              LengthLimitingTextInputFormatter(largoDeLaDireccionDeSede),
            ],
          ),
          const SizedBox(height: Medidas.s12),
          ..._horarios(),
        ],
      ),
    );
  }

  List<Widget> _horarios() {
    final f = formulario;
    final apertura = f.apertura;
    final cierre = f.cierre;
    return [
      CampoSelector(
        etiqueta: 'HORARIO DE APERTURA',
        etiquetaAccesible: 'Horario de apertura',
        valor: apertura == null ? null : horaCerrada(apertura),
        placeholder: '08:00',
        icono: Icons.schedule_rounded,
        error: f.error(CampoDeSede.apertura),
        alTocar: f.enviando ? null : () => alElegirHora(CampoDeSede.apertura),
      ),
      const SizedBox(height: Medidas.s12),
      CampoSelector(
        etiqueta: 'HORARIO DE CIERRE',
        etiquetaAccesible: 'Horario de cierre',
        valor: cierre == null ? null : horaCerrada(cierre),
        placeholder: '23:00',
        icono: Icons.schedule_rounded,
        error: f.error(CampoDeSede.cierre),
        alTocar: f.ocupado ? null : () => alElegirHora(CampoDeSede.cierre),
      ),
      const SizedBox(height: Medidas.s12),
      CampoSelector(
        etiqueta: 'DÍAS QUE ABRE',
        etiquetaAccesible: 'Días que abre',
        valor: diasDeLaSemana(f.dias),
        placeholder: DiasQueAbre.lunesADomingo.texto,
        icono: Icons.expand_more_rounded,
        error: f.error(CampoDeSede.dias),
        alTocar: f.ocupado ? null : alElegirDias,
      ),
    ];
  }
}
