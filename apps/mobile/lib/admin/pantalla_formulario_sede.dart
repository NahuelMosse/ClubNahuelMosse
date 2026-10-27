import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/barra_superior.dart';
import '../comun/boton.dart';
import '../comun/dialogo_error.dart';
import '../comun/faltantes.dart';
import '../comun/fechas.dart';
import '../comun/selector.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tokens.dart';
import 'baja_sede.dart';
import 'botones_de_formulario_de_sede.dart';
import 'campo_de_sede.dart';
import 'cuerpo_de_formulario_de_sede.dart';
import 'formulario_de_sede.dart';
import 'texto_de_reservas_afuera.dart';

/// El formulario de una sede: nombre, dirección, apertura, cierre y días que abre. Sin
/// [editando] da de alta una sede nueva; con [editando], corrige esa.
class PantallaFormularioSede extends StatefulWidget {
  const PantallaFormularioSede({
    super.key,
    required this.sedes,
    required this.sesion,
    this.editando,
  });

  final Sedes sedes;
  final Sesion sesion;
  final Sede? editando;

  @override
  State<PantallaFormularioSede> createState() => _PantallaFormularioSedeState();
}

class _PantallaFormularioSedeState extends State<PantallaFormularioSede> {
  late final _f = FormularioDeSede(
    sedes: widget.sedes,
    editando: widget.editando,
  );

  @override
  void initState() {
    super.initState();
    _f.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _f.dispose();
    super.dispose();
  }

  Future<void> _elegirHora(CampoDeSede campo) async {
    final esCierre = campo == CampoDeSede.cierre;
    // El cierre a la medianoche va al final: es el último horario del día.
    final horas = esCierre
        ? [for (var h = 1; h < 24; h++) h, 0]
        : [for (var h = 0; h < 24; h++) h];
    final elegida = await elegirOpcion<int>(
      context,
      titulo: esCierre ? 'Horario de cierre' : 'Horario de apertura',
      opciones: [for (final h in horas) (h, horaCerrada(h))],
      columnas: 4,
      elegida: esCierre ? _f.cierre : _f.apertura,
    );
    if (!mounted) return;
    _f.elegirHora(campo, elegida);
  }

  Future<void> _elegirDias() async {
    final elegidos = await elegirOpcion<DiasQueAbre>(
      context,
      titulo: 'Días que abre',
      opciones: [for (final d in DiasQueAbre.values) (d, d.texto)],
      elegida: DiasQueAbre.values
          .where((d) => diasDeLaSemana(d.dias) == diasDeLaSemana(_f.dias))
          .firstOrNull,
    );
    if (elegidos == null || !mounted) return;
    _f.elegirDias(elegidos);
  }

  void _listo(Sede sede) {
    if (!mounted) return;
    if (!_f.esEdicion) {
      context.go('/admin/sedes/creada', extra: sede);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Los cambios se guardaron correctamente')),
    );
    context.go('/admin/sedes');
  }

  Future<void> _guardar({bool confirmar = false}) async {
    final apertura = _f.apertura;
    final cierre = _f.cierre;
    if (_f.ocupado) return;
    if (!_f.completo || apertura == null || cierre == null) {
      _f.marcarIntentoDeGuardar();
      enfocarElPrimerFaltante(_f.faltantes);
      return;
    }
    FocusScope.of(context).unfocus();
    final pendiente = await _f.enviar(
      apertura,
      cierre,
      confirmar: confirmar,
      alGuardar: _listo,
    );
    if (pendiente == null || !mounted) return;
    if (pendiente.afuera case final n?) {
      final guardarIgual = await confirmarHorarioNuevo(
        context,
        textoDeReservasAfuera(
          n,
          antes: widget.editando,
          apertura: apertura,
          cierre: cierre,
          dias: _f.dias,
        ),
      );
      if (guardarIgual && mounted) await _guardar(confirmar: true);
    } else if (pendiente.yaNoEsta) {
      await mostrarCambioMientrasTanto(context);
      widget.sedes.avisarCambio();
      if (mounted) context.go('/admin/sedes');
    } else {
      await avisarFalloDeEnvio(
        context,
        sesion: widget.sesion,
        vencida: pendiente.vencida,
        error: pendiente.fallo,
        reintentar: () => _guardar(confirmar: confirmar),
      );
    }
  }

  Future<void> _darDeBaja() async {
    final sede = widget.editando;
    if (sede == null) return;
    await darDeBajaSede(
      context,
      sede: sede,
      sedes: widget.sedes,
      sesion: widget.sesion,
      volverAlListado: true,
      enviando: (enCamino) {
        if (mounted) _f.dandoDeBaja = enCamino;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mientras se guarda no se sale: la sede se guardaría sin que se viera el éxito.
    return PopScope(
      canPop: !_f.ocupado,
      child: Scaffold(
        backgroundColor: context.paleta.bgBase,
        appBar: BarraSuperior(
          titulo: widget.editando == null ? 'Agregar sede' : 'Editar sede',
        ),
        body: SafeArea(
          top: false,
          child: CuerpoDeFormularioDeSede(
            formulario: _f,
            alElegirHora: _elegirHora,
            alElegirDias: _elegirDias,
          ),
        ),
        bottomNavigationBar: BarraDeAccion(
          child: BotonesDeFormularioDeSede(
            formulario: _f,
            alGuardar: _guardar,
            alDarDeBaja: _darDeBaja,
          ),
        ),
      ),
    );
  }
}
