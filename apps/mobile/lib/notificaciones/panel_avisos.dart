import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'centro.dart';
import 'notificacion.dart';
import 'tarjeta_aviso.dart';

/// `Notificaciones in-app (overlay)`: con la app abierta, un panel arriba con las
/// notificaciones sin leer y «MARCAR TODAS». Tocar afuera lo cierra sin marcar nada.
class PanelDeAvisos extends StatelessWidget {
  const PanelDeAvisos({
    super.key,
    required this.centro,
    required this.alAbrir,
    this.ahora = _ahoraEnElClub,
  });

  final CentroDeNotificaciones centro;

  /// Lo que pasa al tocar un aviso: llevarlo a lo que avisa.
  final void Function(Notificacion) alAbrir;
  final DateTime Function() ahora;

  static DateTime _ahoraEnElClub() => enDelClub(DateTime.now());

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: centro,
    builder: (context, _) {
      if (!centro.panelAbierto) return const SizedBox.shrink();
      final p = context.paleta;
      final medidas = MediaQuery.of(context);
      final lista = centro.sinLeer;
      return Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              button: true,
              excludeSemantics: true,
              label: 'Cerrar las notificaciones',
              onTap: centro.cerrarPanel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: centro.cerrarPanel,
                child: ColoredBox(color: p.bgScrim),
              ),
            ),
          ),
          Positioned(
            top: medidas.padding.top + Medidas.s12,
            left: Medidas.s16,
            right: Medidas.s16,
            child: Material(
              color: p.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Medidas.radioLg),
                side: BorderSide(color: p.borderDefault),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: medidas.size.height * 0.7,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Medidas.s12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: Medidas.s4,
                                ),
                                child: Text(
                                  'NOTIFICACIONES',
                                  style: Textos.sobretitulo.copyWith(
                                    color: p.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'MARCAR TODAS',
                            excludeSemantics: true,
                            onTap: centro.marcarTodas,
                            child: InkWell(
                              onTap: centro.marcarTodas,
                              borderRadius: BorderRadius.circular(
                                Medidas.radioMd,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: kMinInteractiveDimension,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Medidas.s8,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'MARCAR TODAS',
                                      style: Textos.sobretitulo.copyWith(
                                        color: p.accentInk,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Medidas.s4),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: lista.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: Medidas.s8),
                          itemBuilder: (context, i) => TarjetaAviso(
                            notificacion: lista[i],
                            ahora: ahora(),
                            alTocar: () => alAbrir(lista[i]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
