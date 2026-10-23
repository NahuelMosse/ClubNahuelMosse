import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Cómo terminó el aviso de [atenderErrorDeRed].
enum ResultadoDeError {
  /// La persona eligió reintentar: quien llama reintenta cuando el intento anterior ya terminó.
  reintentar,

  /// La persona cerró el aviso.
  cerrado,

  /// Era un 403: ya se la llevó a «Acceso denegado» y quien llama no navega encima.
  accesoDenegado,
}

/// Los overlays compartidos de error de conexión y de error del servidor.
///
/// Un 403 de la API no es una falla: es «Acceso denegado», y lleva a su pantalla.
Future<ResultadoDeError> atenderErrorDeRed(
  BuildContext context,
  Object error,
) async {
  if (error is ErrorDelServidor && error.codigo == 403) {
    context.go('/admin/acceso-denegado');
    return ResultadoDeError.accesoDenegado;
  }
  final sinConexion = error is SinConexion;
  final mensaje = error is ErrorDelServidor && error.codigo == 429
      ? error.mensaje
      : null;
  final reintentar = await showDialog<bool>(
    context: context,
    barrierColor: context.paleta.bgScrim,
    builder: (context) => _Modal(
      icono: sinConexion ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
      titulo: sinConexion ? 'Error de conexión' : 'Error del servidor',
      texto: sinConexion
          ? 'No pudimos conectarnos. Revisá tu conexión a internet y volvé a intentar.'
          : mensaje ??
                'No pudimos procesar la operación en este momento. Intentá más tarde.',
      principal: sinConexion ? 'REINTENTAR' : null,
      secundaria: sinConexion ? 'Volver' : 'ACEPTAR',
    ),
  );
  return reintentar == true
      ? ResultadoDeError.reintentar
      : ResultadoDeError.cerrado;
}

/// [atenderErrorDeRed] para quien sólo necesita saber si hay que reintentar.
Future<bool> mostrarErrorDeRed(BuildContext context, Object error) async =>
    await atenderErrorDeRed(context, error) == ResultadoDeError.reintentar;

/// El aviso de que otra persona tomó el horario mientras se confirmaba ([texto] dice cuál).
/// La única salida es elegir otro.
Future<void> mostrarHorarioOcupado(BuildContext context, String texto) =>
    showDialog<void>(
      context: context,
      barrierColor: context.paleta.bgScrim,
      builder: (context) => _Modal(
        icono: Icons.schedule_rounded,
        titulo: 'Ese horario se ocupó',
        texto: texto,
        principal: 'ELEGIR OTRO HORARIO',
      ),
    );

/// La confirmación de cancelar una reserva ([texto] dice cuál). Devuelve `true` si la
/// persona confirmó.
Future<bool> confirmarCancelacion(BuildContext context, String texto) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: context.paleta.bgScrim,
      builder: (context) => _Modal(
        icono: Icons.warning_amber_rounded,
        titulo: '¿Cancelar la reserva?',
        texto: texto,
        principal: 'CANCELAR RESERVA',
        principalPeligro: true,
        secundaria: 'NO CANCELAR',
        secundariaContorno: true,
      ),
    ) ??
    false;

/// El horario nuevo de una sede deja afuera reservas futuras: GUARDAR IGUAL devuelve
/// `true`.
Future<bool> confirmarHorarioNuevo(BuildContext context, String texto) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: context.paleta.bgScrim,
      builder: (context) => _Modal(
        icono: Icons.warning_amber_rounded,
        titulo: '¿Guardar el horario nuevo?',
        texto: texto,
        principal: 'GUARDAR IGUAL',
        secundaria: 'REVISAR EL HORARIO',
        secundariaContorno: true,
      ),
    ) ??
    false;

/// Confirmar la baja de una sede: DAR DE BAJA devuelve `true`.
Future<bool> confirmarBajaDeSede(BuildContext context, String texto) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: context.paleta.bgScrim,
      builder: (context) => _Modal(
        icono: Icons.warning_amber_rounded,
        titulo: '¿Dar de baja la sede?',
        texto: texto,
        principal: 'DAR DE BAJA',
        principalPeligro: true,
        secundaria: 'CANCELAR',
        secundariaContorno: true,
      ),
    ) ??
    false;

/// La sede tiene reservas pendientes y no se puede dar de baja.
Future<void> mostrarSedeConReservas(BuildContext context) => showDialog<void>(
  context: context,
  barrierColor: context.paleta.bgScrim,
  builder: (context) => const _Modal(
    icono: Icons.event_busy_rounded,
    titulo: 'No se puede dar de baja la sede',
    texto:
        'La sede posee reservas futuras asociadas a sus espacios deportivos. '
        'Gestionalas primero.',
    principal: 'ACEPTAR',
  ),
);

/// Confirmar la baja del espacio [nombre]: CONFIRMAR BAJA devuelve `true`.
Future<bool> confirmarBajaDeEspacio(
  BuildContext context,
  String nombre,
) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: context.paleta.bgScrim,
      builder: (context) => _Modal(
        icono: Icons.warning_amber_rounded,
        titulo: '¿Dar de baja el espacio?',
        texto: '$nombre. La acción es permanente.',
        principal: 'CONFIRMAR BAJA',
        principalPeligro: true,
        secundaria: 'CANCELAR',
        secundariaContorno: true,
      ),
    ) ??
    false;

/// El espacio tiene reservas pendientes y no se puede dar de baja.
Future<void> mostrarEspacioConReservas(BuildContext context) =>
    showDialog<void>(
      context: context,
      barrierColor: context.paleta.bgScrim,
      builder: (context) => const _Modal(
        icono: Icons.event_busy_rounded,
        titulo: 'No se puede dar de baja el espacio',
        texto: 'El espacio posee reservas futuras. Gestionalas primero.',
        principal: 'ACEPTAR',
      ),
    );

/// La reserva quedó cancelada.
Future<void> mostrarCancelada(BuildContext context) => showDialog<void>(
  context: context,
  barrierColor: context.paleta.bgScrim,
  builder: (context) => const _Modal(
    icono: Icons.check_circle_outline_rounded,
    exito: true,
    titulo: 'Reserva cancelada con éxito',
    texto: 'El horario quedó liberado y la reserva pasó a tu historial.',
    principal: 'ACEPTAR',
  ),
);

/// El administrador anuló la reserva.
Future<void> mostrarReservaAnulada(BuildContext context) => showDialog<void>(
  context: context,
  barrierColor: context.paleta.bgScrim,
  builder: (context) => const _Modal(
    icono: Icons.check_circle_outline_rounded,
    exito: true,
    titulo: 'Reserva anulada correctamente',
    texto: 'El horario quedó liberado y la reserva pasó a las anuladas.',
    principal: 'ACEPTAR',
  ),
);

/// El overlay compartido «Esto cambió mientras tanto»: lo que se veía ya no está así, y
/// quien llama lo vuelve a leer.
Future<void> mostrarCambioMientrasTanto(
  BuildContext context,
) => showDialog<void>(
  context: context,
  barrierColor: context.paleta.bgScrim,
  builder: (context) => const _Modal(
    icono: Icons.sync_problem_rounded,
    titulo: 'Esto cambió mientras tanto',
    texto:
        'Otra persona modificó estos datos mientras los estabas viendo. Los '
        'actualizamos para que veas el estado real.',
    principal: 'VER LO ACTUALIZADO',
  ),
);

/// El overlay compartido de sesión expirada. No se puede descartar: la única salida es
/// volver a iniciar sesión, que hace quien llama cuando esto termina.
Future<void> mostrarSesionVencida(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  barrierColor: context.paleta.bgScrim,
  builder: (context) => const PopScope(
    canPop: false,
    child: _Modal(
      icono: Icons.cloud_off_rounded,
      titulo: 'Tu sesión expiró',
      texto:
          'Por seguridad cerramos tu sesión. Volvé a iniciar sesión para continuar.',
      principal: 'IR AL INICIO DE SESIÓN',
    ),
  ),
);

/// El texto que más contraste da sobre [fondo]: el blanco o el fondo de la app.
Color textoSobre(Color fondo, Paleta p) {
  double contraste(Color a, Color b) {
    final (x, y) = (a.computeLuminance(), b.computeLuminance());
    return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
  }

  const blanco = Color(0xFFFFFFFF);
  return contraste(blanco, fondo) >= contraste(p.bgBase, fondo)
      ? blanco
      : p.bgBase;
}

/// `Modal` del prototipo: ícono en círculo, título, texto y hasta dos acciones. La
/// principal cierra con `true` y la secundaria con `false`.
class _Modal extends StatelessWidget {
  const _Modal({
    required this.icono,
    required this.titulo,
    required this.texto,
    this.principal,
    this.secundaria,
    this.exito = false,
    this.principalPeligro = false,
    this.secundariaContorno = false,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final String? principal;
  final String? secundaria;

  /// El ícono en verde: el aviso cuenta que algo salió bien.
  final bool exito;

  /// La acción principal en rojo: no se deshace.
  final bool principalPeligro;
  final bool secundariaContorno;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final accionPrincipal = principal;
    final accionSecundaria = secundaria;
    return MarcoDeDialogo(
      anchoMaximo: 320,
      hijos: [
        CirculoDeIcono(
          icono: icono,
          fondo: exito ? p.stateSuccessMuted : p.stateDangerMuted,
          tinta: exito ? p.stateSuccessInk : p.stateDangerInk,
        ),
        const SizedBox(height: Medidas.s12),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: Textos.h2.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: Medidas.s12),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: Textos.cuerpo.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: Medidas.s12),
        if (accionPrincipal != null)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: principalPeligro ? p.stateDanger : p.accentBase,
              foregroundColor: principalPeligro
                  ? textoSobre(p.stateDanger, p)
                  : p.accentOn,
              minimumSize: const Size.fromHeight(Medidas.altoControl),
              shape: const StadiumBorder(),
              textStyle: Textos.boton,
            ),
            child: Text(accionPrincipal, textAlign: TextAlign.center),
          ),
        if (accionPrincipal != null && accionSecundaria != null)
          const SizedBox(height: Medidas.s8),
        if (accionSecundaria != null && secundariaContorno)
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: p.textPrimary,
              side: BorderSide(color: p.borderControl),
              minimumSize: const Size.fromHeight(Medidas.altoControl),
              shape: const StadiumBorder(),
              textStyle: Textos.boton,
            ),
            child: Text(accionSecundaria),
          )
        else if (accionSecundaria != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: p.accentInk,
              minimumSize: const Size.fromHeight(Medidas.altoControl),
              textStyle: Textos.boton,
            ),
            child: Text(accionSecundaria),
          ),
      ],
    );
  }
}

/// El marco de un diálogo: la tarjeta con [hijos] apilados. Con [anchoMaximo] el contenido
/// se acota y se desliza si no entra; sin él ocupa el ancho del diálogo.
class MarcoDeDialogo extends StatelessWidget {
  const MarcoDeDialogo({super.key, required this.hijos, this.anchoMaximo});

  final List<Widget> hijos;
  final double? anchoMaximo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    const relleno = EdgeInsets.all(Medidas.s24);
    final columna = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: hijos,
    );
    final ancho = anchoMaximo;
    return Dialog(
      backgroundColor: p.bgSurfaceRaised,
      insetPadding: const EdgeInsets.symmetric(horizontal: Medidas.s24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        side: BorderSide(color: p.borderDefault),
      ),
      child: ancho == null
          ? Padding(padding: relleno, child: columna)
          : ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ancho),
              child: SingleChildScrollView(padding: relleno, child: columna),
            ),
    );
  }
}

/// El círculo de 64 con el ícono de un aviso.
class CirculoDeIcono extends StatelessWidget {
  const CirculoDeIcono({
    super.key,
    required this.icono,
    required this.fondo,
    required this.tinta,
  });

  final IconData icono;
  final Color fondo;
  final Color tinta;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
      child: Icon(icono, size: 28, color: tinta),
    ),
  );
}
