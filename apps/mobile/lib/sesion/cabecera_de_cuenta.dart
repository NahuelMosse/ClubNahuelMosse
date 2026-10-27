import 'package:flutter/material.dart';

import '../comun/avatar.dart';
import '../comun/insignia.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'sesion.dart';

/// El avatar de quien tiene la sesión abierta, con su nombre, su correo y, si es usuario,
/// la insignia de miembro.
class CabeceraDeCuenta extends StatelessWidget {
  const CabeceraDeCuenta({super.key, required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final esUsuario = perfil.rol == Rol.usuario;
    return Padding(
      padding: const EdgeInsets.all(Medidas.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarIniciales(nombre: perfil.nombre, apellido: perfil.apellido),
          const SizedBox(width: Medidas.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${perfil.nombre} ${perfil.apellido}',
                  style: Textos.titulo.copyWith(color: p.textPrimary),
                ),
                const SizedBox(height: Medidas.s4),
                Text(
                  perfil.correo,
                  style: Textos.leyenda.copyWith(color: p.textMuted),
                ),
                if (esUsuario) ...[
                  const SizedBox(height: Medidas.s4),
                  const Insignia(texto: 'MIEMBRO ACTIVO'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
