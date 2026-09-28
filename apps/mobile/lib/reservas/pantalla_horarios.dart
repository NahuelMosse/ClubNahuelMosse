import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/dialogo_error.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// «Horarios disponibles» de un tipo de cancha en una sede, con la cancha elegida desde la
/// sede. Muestra las canchas de ese tipo para cambiar de una a otra.
class PantallaHorarios extends StatefulWidget {
  const PantallaHorarios({
    super.key,
    required this.sedeId,
    required this.espacioId,
    required this.sedes,
    required this.espacios,
    required this.sesion,
  });

  final int sedeId;
  final int espacioId;
  final Sedes sedes;
  final Espacios espacios;
  final Sesion sesion;

  @override
  State<PantallaHorarios> createState() => _PantallaHorariosState();
}

class _PantallaHorariosState extends State<PantallaHorarios> {
  (Sede, List<Espacio>, Catalogo)? _datos;
  late int _elegida = widget.espacioId;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    Object? fallo;
    var vencida = false;
    try {
      final catalogo = await widget.espacios.catalogo();
      final sedes = await widget.sedes.activas();
      final sede = sedes.where((s) => s.id == widget.sedeId).firstOrNull;
      final canchas = await widget.espacios.activos(sedeId: widget.sedeId);
      final elegida = canchas
          .where((c) => c.id == widget.espacioId)
          .firstOrNull;
      if (!mounted) return;
      if (sede == null || elegida == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta cancha ya no está disponible')),
        );
        if (sede == null) {
          widget.sedes.avisarCambio();
        } else {
          widget.espacios.avisarCambio();
        }
        context.go(sede == null ? '/sedes' : '/sedes/${sede.id}');
        return;
      }
      setState(() {
        _datos = (
          sede,
          [
            for (final c in canchas)
              if (c.deporte == elegida.deporte && c.tipo == elegida.tipo) c,
          ],
          catalogo,
        );
      });
      return;
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    }
    if (!mounted) return;
    if (vencida) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    } else if (fallo != null) {
      final reintentar = await mostrarErrorDeRed(context, fallo);
      if (!mounted) return;
      if (reintentar) {
        await _cargar();
      } else {
        context.go('/sedes/${widget.sedeId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final datos = _datos;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BarraInferior(
        actual: Seccion.sedes,
        enRaiz: false,
      ),
      body: SafeArea(
        child: datos == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.s12,
                  Medidas.s8,
                  Medidas.s24,
                  Medidas.s40,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.go('/sedes/${widget.sedeId}'),
                      style: TextButton.styleFrom(
                        foregroundColor: p.textPrimary,
                        minimumSize: const Size(0, Medidas.tactil),
                        textStyle: Textos.leyenda,
                      ),
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      label: const Text('Sedes'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: Medidas.s12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: Medidas.s8),
                        Semantics(
                          header: true,
                          child: Text(
                            datos.$3.tipoCorto(
                              datos.$2.first.deporte,
                              datos.$2.first.tipo,
                            ),
                            style: Textos.h1.copyWith(color: p.textPrimary),
                          ),
                        ),
                        const SizedBox(height: Medidas.s4),
                        Text(
                          datos.$1.nombre.toUpperCase(),
                          style: Textos.sobretitulo.copyWith(
                            color: p.accentInk,
                          ),
                        ),
                        const SizedBox(height: Medidas.s24),
                        Text(
                          'SELECCIONÁ CANCHA',
                          style: Textos.sobretitulo.copyWith(
                            color: p.textMuted,
                          ),
                        ),
                        const SizedBox(height: Medidas.s12),
                        Wrap(
                          spacing: Medidas.s8,
                          runSpacing: Medidas.s8,
                          children: [
                            for (final c in datos.$2)
                              _ChipCancha(
                                cancha: c,
                                elegida: c.id == _elegida,
                                alTocar: () => setState(() => _elegida = c.id),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ChipCancha extends StatelessWidget {
  const _ChipCancha({
    required this.cancha,
    required this.elegida,
    required this.alTocar,
  });

  final Espacio cancha;
  final bool elegida;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final tinta = elegida ? p.accentOn : p.textPrimary;
    return Semantics(
      container: true,
      button: true,
      selected: elegida,
      excludeSemantics: true,
      label:
          '${cancha.nombre}, Cancha ${cancha.numero}, ${cancha.condicion}'
          '${elegida ? ', elegida' : ''}',
      onTap: alTocar,
      child: Material(
        color: elegida ? p.accentBase : p.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Medidas.radioMd),
          side: BorderSide(color: elegida ? p.accentEdge : p.borderControl),
        ),
        child: InkWell(
          onTap: alTocar,
          borderRadius: BorderRadius.circular(Medidas.radioMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Medidas.s16,
              vertical: Medidas.s8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancha ${cancha.numero}',
                  style: Textos.cuerpoFuerte.copyWith(color: tinta),
                ),
                Text(
                  cancha.condicion,
                  style: Textos.leyenda.copyWith(color: tinta),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
