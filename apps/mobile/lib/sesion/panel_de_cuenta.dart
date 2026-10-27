import 'package:flutter/material.dart';

import '../comun/movimiento.dart';
import '../tema/tokens.dart';
import 'cabecera_de_cuenta.dart';
import 'opcion_de_cuenta.dart';
import 'sesion.dart';

/// El panel flotante de la cuenta: la cabecera y sus accesos.
class PanelDeCuenta extends StatelessWidget {
  const PanelDeCuenta({
    super.key,
    required this.perfil,
    required this.alIr,
    required this.alCerrarSesion,
  });

  final Perfil perfil;
  final ValueChanged<String> alIr;
  final VoidCallback alCerrarSesion;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final esUsuario = perfil.rol == Rol.usuario;
    return Aparecer(
      desdeY: -16,
      duracion: const Duration(milliseconds: 350),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Medidas.radioLg),
          boxShadow: const [
            BoxShadow(
              color: Color(0x8C000000),
              offset: Offset(0, 14),
              blurRadius: 34,
            ),
          ],
        ),
        child: Material(
          color: p.bgSurfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Medidas.radioLg),
            side: BorderSide(color: p.borderDefault),
          ),
          clipBehavior: Clip.antiAlias,
          // Con el teléfono apaisado o el texto grande no entra en el alto.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CabeceraDeCuenta(perfil: perfil),
                Divider(height: 1, color: p.borderDefault),
                const SizedBox(height: Medidas.s8),
                if (esUsuario) ...[
                  OpcionDeCuenta(
                    icono: Icons.person_outline_rounded,
                    texto: 'Perfil completo',
                    alTocar: () => alIr('/perfil'),
                  ),
                  OpcionDeCuenta(
                    icono: Icons.calendar_today_outlined,
                    texto: 'Mis reservas',
                    alTocar: () => alIr('/reservas'),
                  ),
                ],
                OpcionDeCuenta(
                  icono: Icons.logout_rounded,
                  texto: 'Cerrar sesión',
                  peligro: true,
                  alTocar: alCerrarSesion,
                ),
                const SizedBox(height: Medidas.s8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
