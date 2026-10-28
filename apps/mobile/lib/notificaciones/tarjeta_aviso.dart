import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'notificacion.dart';

/// `Push-Notification` del prototipo: el ícono del tipo, «CLUBNAHUELMOSSE · cuándo», el título
/// y el cuerpo. Sin leer lleva un punto de acento.
class TarjetaAviso extends StatelessWidget {
  const TarjetaAviso({
    super.key,
    required this.notificacion,
    required this.ahora,
    required this.alTocar,
  });

  final Notificacion notificacion;

  /// La hora del club con la que se cuenta el «hace cuánto».
  final DateTime ahora;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final n = notificacion;
    final cuando = cuandoLlego(n.creada, ahora);
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Medidas.radioLg),
      side: BorderSide(color: p.borderDefault),
    );
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: '${n.titulo}. ${n.cuerpo}. $cuando${n.leida ? '' : ', sin leer'}',
      onTap: alTocar,
      child: Material(
        color: p.bgSurfaceRaised,
        shape: forma,
        child: InkWell(
          onTap: alTocar,
          customBorder: forma,
          child: Padding(
            padding: const EdgeInsets.all(Medidas.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Icono(tipo: n.tipo),
                const SizedBox(width: Medidas.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLUBNAHUELMOSSE · $cuando',
                        style: Textos.sobretitulo.copyWith(color: p.textMuted),
                      ),
                      const SizedBox(height: Medidas.s4),
                      Text(
                        n.titulo,
                        style: Textos.cuerpoFuerte.copyWith(
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: Medidas.s4),
                      Text(
                        n.cuerpo,
                        style: Textos.leyenda.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!n.leida) ...[
                  const SizedBox(width: Medidas.s8),
                  Padding(
                    padding: const EdgeInsets.only(top: Medidas.s4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.accentInk,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El ícono del tipo: lima el recordatorio, verde la confirmación, rojo la alerta.
class _Icono extends StatelessWidget {
  const _Icono({required this.tipo});

  final TipoDeNotificacion tipo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final (fondo, color, icono) = switch (tipo) {
      TipoDeNotificacion.recordatorio || TipoDeNotificacion.recordatorioCinco =>
        (p.accentBase, p.accentOn, Icons.schedule_rounded),
      TipoDeNotificacion.cancelacionUsuario => (
        p.stateSuccessMuted,
        p.stateSuccessInk,
        Icons.check_circle_outline_rounded,
      ),
      TipoDeNotificacion.cancelacionForzosa => (
        p.stateDangerMuted,
        p.stateDangerInk,
        Icons.warning_amber_rounded,
      ),
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Medidas.radioMd),
      ),
      child: Icon(icono, size: 22, color: color),
    );
  }
}
