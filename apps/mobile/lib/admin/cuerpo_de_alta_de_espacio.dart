import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../comun/selector.dart';
import '../comun/snackbar.dart';
import '../tema/tokens.dart';
import 'campo_de_alta_de_espacio.dart';
import 'campo_de_precio_por_hora.dart';
import 'formulario_de_alta_de_espacio.dart';
import 'formulario_espacio.dart';
import 'nombre_generado.dart';
import 'par_de_campos.dart';

/// El formulario del alta de un espacio: el aviso, los selectores, el precio, el nombre
/// compuesto y los botones.
class CuerpoDeAltaDeEspacio extends StatelessWidget {
  const CuerpoDeAltaDeEspacio({
    super.key,
    required this.formulario,
    required this.alElegirSede,
    required this.alElegirDeporte,
    required this.alElegirTipo,
    required this.alElegirSiNo,
    required this.alReintentarElNombre,
    required this.alGuardar,
  });

  final FormularioDeAltaDeEspacio formulario;
  final VoidCallback alElegirSede;
  final VoidCallback alElegirDeporte;
  final VoidCallback alElegirTipo;
  final void Function(CampoDeAltaDeEspacio) alElegirSiNo;
  final VoidCallback alReintentarElNombre;
  final VoidCallback alGuardar;

  @override
  Widget build(BuildContext context) {
    final f = formulario;
    final aviso = f.aviso;
    return SingleChildScrollView(
      padding: Medidas.paginaDeFormulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (aviso != null) ...[
            SnackbarError(
              key: f.claveDelAviso,
              texto: aviso,
              alCerrar: f.cerrarAviso,
            ),
            const SizedBox(height: Medidas.s16),
          ],
          ...encabezadoDeEspacio(context, 'Nuevo espacio deportivo'),
          ..._selectores(),
          CampoDePrecioPorHora(
            controlador: f.precio,
            error: f.error(CampoDeAltaDeEspacio.precio),
            habilitado: !f.enviando && !f.cargando,
          ),
          const SizedBox(height: Medidas.s16),
          NombreGenerado(
            nombre: f.sugerido?.$1,
            calculando: f.calculando,
            falta: f.faltaParaElNombre,
            alReintentar: f.falloDelNombre == null || f.enviando
                ? null
                : alReintentarElNombre,
          ),
          const SizedBox(height: Medidas.s16),
          BotonPrimario(
            texto: 'GUARDAR ESPACIO',
            cargando: f.enviando,
            atenuado: !f.completo,
            alTocar: alGuardar,
          ),
          const SizedBox(height: Medidas.s12),
          BotonContorno(
            texto: 'CANCELAR',
            alTocar: f.enviando ? null : () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  List<Widget> _selectores() {
    final f = formulario;
    final sedes = f.opcionesDeSede;
    final habilitado = !f.enviando && !f.cargando;
    return [
      CampoSelector(
        etiqueta: 'SEDE',
        etiquetaAccesible: 'Sede',
        valor: f.sede?.nombre,
        placeholder: sedes == null || sedes.isNotEmpty
            ? 'Seleccioná una sede'
            : 'Todavía no hay sedes',
        icono: Icons.expand_more_rounded,
        error: f.error(CampoDeAltaDeEspacio.sede),
        alTocar: habilitado && (sedes?.isNotEmpty ?? false)
            ? alElegirSede
            : null,
      ),
      const SizedBox(height: Medidas.s12),
      CampoSelector(
        etiqueta: 'DEPORTE',
        etiquetaAccesible: 'Deporte',
        valor: f.deporte?.nombre,
        placeholder: 'Seleccioná un deporte',
        icono: Icons.expand_more_rounded,
        error: f.error(CampoDeAltaDeEspacio.deporte),
        alTocar: habilitado ? alElegirDeporte : null,
      ),
      const SizedBox(height: Medidas.s12),
      CampoSelector(
        etiqueta: 'TIPO',
        etiquetaAccesible: 'Tipo',
        valor: f.tipo?.nombre,
        placeholder: 'Seleccioná el tipo',
        icono: Icons.expand_more_rounded,
        error: f.error(CampoDeAltaDeEspacio.tipo),
        alTocar: habilitado && f.deporte != null ? alElegirTipo : null,
      ),
      const SizedBox(height: Medidas.s12),
      ParDeCampos(
        izquierda: CampoSelector(
          etiqueta: 'CONDICIÓN',
          etiquetaAccesible: 'Condición',
          valor: switch (f.techada) {
            true => 'Techada',
            false => 'Al aire libre',
            null => null,
          },
          placeholder: 'Seleccioná',
          icono: Icons.expand_more_rounded,
          error: f.error(CampoDeAltaDeEspacio.condicion),
          alTocar: habilitado
              ? () => alElegirSiNo(CampoDeAltaDeEspacio.condicion)
              : null,
        ),
        derecha: CampoSelector(
          etiqueta: 'ILUMINACIÓN',
          etiquetaAccesible: 'Iluminación',
          valor: switch (f.iluminada) {
            true => 'Iluminada',
            false => 'Sin iluminación',
            null => null,
          },
          placeholder: 'Seleccioná',
          icono: Icons.expand_more_rounded,
          error: f.error(CampoDeAltaDeEspacio.iluminacion),
          alTocar: habilitado
              ? () => alElegirSiNo(CampoDeAltaDeEspacio.iluminacion)
              : null,
        ),
      ),
      const SizedBox(height: Medidas.s12),
    ];
  }
}
