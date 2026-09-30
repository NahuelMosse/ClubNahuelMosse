import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'centro.dart';

/// La campana de la cabecera: abre el centro de notificaciones y cuenta las que no se leyeron.
class BotonNotificaciones extends StatelessWidget {
  const BotonNotificaciones({super.key, required this.centro});

  final CentroDeNotificaciones centro;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: centro,
    builder: (context, _) {
      final p = context.paleta;
      final sinLeer = centro.noLeidas;
      void abrir() => context.push('/notificaciones');
      return Semantics(
        container: true,
        button: true,
        label: sinLeer == 0
            ? 'Notificaciones'
            : 'Notificaciones, $sinLeer sin leer',
        onTap: abrir,
        excludeSemantics: true,
        child: InkResponse(
          onTap: abrir,
          radius: Medidas.altoControl / 2,
          child: SizedBox.square(
            dimension: Medidas.altoControl,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 26,
                  color: p.textPrimary,
                ),
                if (sinLeer > 0)
                  Positioned(
                    top: Medidas.s8,
                    right: Medidas.s4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.accentBase,
                        borderRadius: BorderRadius.circular(Medidas.radioPill),
                      ),
                      child: Text(
                        sinLeer > 99 ? '99+' : '$sinLeer',
                        style: Textos.sobretitulo.copyWith(color: p.accentOn),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
