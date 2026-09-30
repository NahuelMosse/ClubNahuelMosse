import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'centro.dart';
import 'notificacion.dart';
import 'tarjeta_aviso.dart';

/// `Notificaciones in-app (overlay)`: con la app abierta, un panel arriba con las
/// notificaciones sin leer y «MARCAR TODAS». Es una ruta modal del navegador: el lector de
/// pantalla no llega a lo que queda abajo, el atrás del sistema lo cierra y tocar afuera lo
/// cierra sin marcar nada.
///
/// El widget no dibuja nada: abre y cierra la ruta según [centro].
class PanelDeAvisos extends StatefulWidget {
  const PanelDeAvisos({
    super.key,
    required this.centro,
    required this.alAbrir,
    this.navegador,
    this.ahora = _ahoraEnElClub,
  });

  final CentroDeNotificaciones centro;

  /// Lo que pasa al tocar un aviso: llevarlo a lo que avisa.
  final void Function(Notificacion) alAbrir;

  /// El navegador donde se abre. Si el widget está arriba del `Navigator` (en el `builder` de la
  /// app), hace falta su llave; debajo de él, se usa el más cercano.
  final GlobalKey<NavigatorState>? navegador;
  final DateTime Function() ahora;

  static DateTime _ahoraEnElClub() => enDelClub(DateTime.now());

  @override
  State<PanelDeAvisos> createState() => _PanelDeAvisosState();
}

class _PanelDeAvisosState extends State<PanelDeAvisos> {
  NavigatorState? _navegador;
  Route<void>? _ruta;

  @override
  void initState() {
    super.initState();
    widget.centro.addListener(_revisar);
    // El centro pudo haber abierto el panel antes de que este widget existiera.
    WidgetsBinding.instance.addPostFrameCallback((_) => _revisar());
  }

  @override
  void didUpdateWidget(PanelDeAvisos anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.centro != widget.centro) {
      anterior.centro.removeListener(_revisar);
      widget.centro.addListener(_revisar);
    }
  }

  @override
  void dispose() {
    widget.centro.removeListener(_revisar);
    _cerrarLaRuta();
    super.dispose();
  }

  void _revisar() {
    if (!mounted) return;
    final abierto = _ruta?.isActive ?? false;
    if (widget.centro.panelAbierto && !abierto) {
      _abrirLaRuta();
    } else if (!widget.centro.panelAbierto && abierto) {
      _cerrarLaRuta();
    }
  }

  void _abrirLaRuta() {
    final navegador =
        widget.navegador?.currentState ?? Navigator.maybeOf(context);
    if (navegador == null) return;
    final paleta = context.paleta;
    final ruta = RawDialogRoute<void>(
      barrierDismissible: true,
      barrierLabel: 'Cerrar las notificaciones',
      barrierColor: paleta.bgScrim,
      transitionDuration: Duration.zero,
      pageBuilder: (context, _, _) => _ContenidoDelPanel(
        centro: widget.centro,
        alAbrir: widget.alAbrir,
        ahora: widget.ahora,
      ),
    );
    _navegador = navegador;
    _ruta = ruta;
    // Se cierre como se cierre —tocando afuera, el atrás del sistema, un aviso—, el centro
    // deja de tener el panel abierto.
    ruta.popped.then((_) {
      if (identical(_ruta, ruta)) _ruta = null;
      widget.centro.cerrarPanel();
    });
    navegador.push(ruta);
  }

  void _cerrarLaRuta() {
    final ruta = _ruta;
    if (ruta != null && ruta.isActive) _navegador?.removeRoute(ruta);
    _ruta = null;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ContenidoDelPanel extends StatelessWidget {
  const _ContenidoDelPanel({
    required this.centro,
    required this.alAbrir,
    required this.ahora,
  });

  final CentroDeNotificaciones centro;
  final void Function(Notificacion) alAbrir;
  final DateTime Function() ahora;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: centro,
    builder: (context, _) {
      final p = context.paleta;
      final medidas = MediaQuery.of(context);
      final lista = centro.sinLeer;
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Medidas.s16,
              Medidas.s12,
              Medidas.s16,
              0,
            ),
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
                            // Un lector de pantalla anuncia el panel cuando aparece.
                            child: Semantics(
                              header: true,
                              liveRegion: true,
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
        ),
      );
    },
  );
}
