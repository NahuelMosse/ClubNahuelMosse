import 'package:flutter/material.dart';
import '../comun/avatar.dart';
import '../comun/ficha_socio.dart';
import '../comun/movimiento.dart';
import '../sedes/fotos.dart';
import '../sesion/sesion.dart';
import '../tema/tokens.dart';

class CabeceraDePerfil extends StatelessWidget {
  const CabeceraDePerfil({super.key, required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.bgHeroFrom, p.bgHeroTo],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s24,
            Medidas.s24,
            Medidas.s24,
          ),
          child: Aparecer(
            duracion: const Duration(milliseconds: 550),
            desdeY: -24,
            giro: -3 / 360,
            curva: Movimiento.suave,
            child: FichaSocio(
              iniciales: AvatarIniciales.iniciales(
                perfil.nombre,
                perfil.apellido,
              ),
              nombre: '${perfil.nombre} ${perfil.apellido}',
              correo: perfil.correo,
              numero: 'MIEMBRO ACTIVO',
              estadisticas: const [],
              imagen: fotoDeDeporte('Futbol'),
            ),
          ),
        ),
      ),
    );
  }
}
