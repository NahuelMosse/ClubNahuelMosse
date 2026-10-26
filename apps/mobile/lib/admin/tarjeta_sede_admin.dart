import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../sedes/sede.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'listado_admin.dart';

/// `Card-Sede-Admin`: nombre, dirección, cantidad de canchas y días con horario, con
/// «Editar sede» y «Dar de baja».
class TarjetaSedeAdmin extends StatelessWidget {
  const TarjetaSedeAdmin({
    super.key,
    required this.sede,
    this.alDarDeBaja,
    this.dandoDeBaja = false,
    this.habilitada = true,
  });

  final Sede sede;
  final VoidCallback? alDarDeBaja;

  /// La baja de esta sede está en camino.
  final bool dandoDeBaja;

  /// `false` deshabilita sus botones (hay otra baja en camino).
  final bool habilitada;

  void _editar(BuildContext context) =>
      context.go('/admin/sedes/${sede.id}/editar', extra: sede);

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final canchas = sede.canchas == 1 ? '1 cancha' : '${sede.canchas} canchas';
    // Los datos se leen como uno; los botones quedan afuera, cada uno con su nombre.
    final datos = Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '${sede.nombre}, ${sede.direccion}, $canchas, '
          '${sede.diasLegibles} de ${sede.apertura} a ${sede.cierre}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: Medidas.tactil,
                height: Medidas.tactil,
                decoration: BoxDecoration(
                  color: p.accentMuted,
                  borderRadius: BorderRadius.circular(Medidas.radioMd),
                ),
                child: Icon(Icons.place_outlined, size: 20, color: p.accentInk),
              ),
              const SizedBox(width: Medidas.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sede.nombre,
                      style: Textos.titulo.copyWith(color: p.textPrimary),
                    ),
                    const SizedBox(height: Medidas.s4),
                    Text(
                      sede.direccion,
                      style: Textos.leyenda.copyWith(color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Medidas.s12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${sede.canchas}',
                    style: Textos.h2.copyWith(color: p.accentInk),
                  ),
                  Text(
                    sede.canchas == 1 ? 'CANCHA' : 'CANCHAS',
                    style: Textos.sobretitulo.copyWith(color: p.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Medidas.s12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: p.textMuted),
              const SizedBox(width: Medidas.s8),
              Expanded(
                child: Text(
                  '${sede.diasLegibles} · ${sede.apertura} a ${sede.cierre}',
                  style: Textos.leyenda.copyWith(color: p.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return TarjetaAdmin(
      datos: datos,
      nombre: sede.nombre,
      textoEditar: 'Editar sede',
      etiquetaEditar: 'Editar sede ${sede.nombre}',
      alEditar: habilitada ? () => _editar(context) : null,
      textoBaja: 'Dar de baja',
      etiquetaBaja: 'Dar de baja ${sede.nombre}',
      alDarDeBaja: habilitada ? alDarDeBaja : null,
      dandoDeBaja: dandoDeBaja,
    );
  }
}
