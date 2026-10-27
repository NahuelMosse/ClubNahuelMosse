import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/apariencia.dart';
import '../comun/movimiento.dart';
import '../sesion/sesion.dart';
import '../tema/tokens.dart';
import 'acciones_de_cuenta.dart';
import 'boton_chico.dart';
import 'cabecera_de_perfil.dart';
import 'datos_de_perfil.dart';
import 'edicion_de_perfil.dart';
import 'fila_de_perfil.dart';
import 'modo_oscuro.dart';
import 'tarjeta_de_perfil.dart';

/// Las tarjetas de Mi perfil: datos, seguridad, apariencia y las acciones de la cuenta.
class ContenidoDeMiPerfil extends StatelessWidget {
  const ContenidoDeMiPerfil({
    super.key,
    required this.perfil,
    required this.sesion,
    required this.apariencia,
    required this.editando,
    required this.dandoDeBaja,
    required this.alEditar,
    required this.alGuardar,
    required this.alConfirmarBaja,
  });

  final Perfil perfil;
  final Sesion sesion;
  final Apariencia apariencia;
  final bool editando;
  final bool dandoDeBaja;
  final VoidCallback alEditar;
  final ValueChanged<Perfil> alGuardar;
  final VoidCallback alConfirmarBaja;

  @override
  Widget build(BuildContext context) {
    // Una pantalla corta y fija: todo queda armado aunque salga de la vista.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabeceraDePerfil(perfil: perfil),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Medidas.s24,
              Medidas.s20,
              Medidas.s24,
              Medidas.s48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Aparecer(
                  retraso: const Duration(milliseconds: 100),
                  child: TarjetaDePerfil(
                    titulo: 'DATOS PERSONALES',
                    accion: editando
                        ? null
                        : BotonChico(
                            texto: 'Editar',
                            icono: Icons.edit_outlined,
                            alTocar: alEditar,
                          ),
                    child: editando
                        ? EdicionDePerfil(
                            perfil: perfil,
                            sesion: sesion,
                            alGuardar: alGuardar,
                          )
                        : DatosDePerfil(perfil: perfil),
                  ),
                ),
                const SizedBox(height: Medidas.s16),
                Aparecer(
                  retraso: const Duration(milliseconds: 180),
                  child: TarjetaDePerfil(
                    titulo: 'SEGURIDAD',
                    child: FilaDePerfil(
                      icono: Icons.lock_outline_rounded,
                      texto: 'Cambiar contraseña',
                      alTocar: () => context.push('/perfil/contrasena'),
                    ),
                  ),
                ),
                const SizedBox(height: Medidas.s16),
                Aparecer(
                  retraso: const Duration(milliseconds: 260),
                  child: TarjetaDePerfil(
                    titulo: 'APARIENCIA',
                    child: ModoOscuro(apariencia: apariencia),
                  ),
                ),
                const SizedBox(height: Medidas.s20),
                Aparecer(
                  retraso: const Duration(milliseconds: 340),
                  child: AccionesDeCuenta(
                    sesion: sesion,
                    dandoDeBaja: dandoDeBaja,
                    alConfirmarBaja: alConfirmarBaja,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
