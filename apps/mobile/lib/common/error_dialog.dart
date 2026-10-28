import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/api_client.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'motion.dart';

/// How the notice of [handleNetworkError] ended.
enum ErrorOutcome {
  /// The person chose to retry: the caller retries once the previous attempt has finished.
  retry,

  /// The person closed the notice.
  closed,

  /// It was a 403: the person was already taken to «Acceso denegado» and the caller does not
  /// navigate on top of it.
  accessDenied,
}

/// The shared overlays for connection errors and server errors.
///
/// A 403 from the API is not a failure: it is «Acceso denegado», and leads to its screen.
Future<ErrorOutcome> handleNetworkError(
  BuildContext context,
  Object error,
) async {
  if (error is ErrorDelServidor && error.codigo == 403) {
    context.go('/admin/acceso-denegado');
    return ErrorOutcome.accessDenied;
  }
  final noConnection = error is SinConexion;
  final message = error is ErrorDelServidor && error.codigo == 429
      ? error.mensaje
      : null;
  final retry = await showDialog<bool>(
    context: context,
    barrierColor: context.palette.bgScrim,
    builder: (context) => NoticeModal(
      icon: noConnection ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
      title: noConnection ? 'Error de conexión' : 'Error del servidor',
      text: switch (error) {
        SinConexion() =>
          'No pudimos conectarnos. Revisá tu conexión a internet y volvé a intentar.',
        ServidorSinRespuesta() =>
          'El servidor no responde. Probá de nuevo en unos minutos.',
        _ when message != null => message,
        _ =>
          'No pudimos procesar la operación en este momento. Intentá más tarde.',
      },
      primary: noConnection ? 'REINTENTAR' : null,
      secondary: noConnection ? 'Volver' : 'ACEPTAR',
    ),
  );
  return retry == true ? ErrorOutcome.retry : ErrorOutcome.closed;
}

/// [handleNetworkError] for callers that only need to know whether to retry.
Future<bool> showNetworkError(BuildContext context, Object error) async =>
    await handleNetworkError(context, error) == ErrorOutcome.retry;

/// The notice that someone else took the time slot while it was being confirmed ([text] says
/// which). The only way out is to choose another.
Future<void> showTimeSlotTaken(BuildContext context, String text) =>
    _showTimeSlotNotice(context, 'Ese horario se ocupó', text);

/// The notice that the club rejected the chosen time slot ([text] is the reason it gave). It
/// does not close by itself: the person reads it and chooses another.
Future<void> showTimeSlotRejected(BuildContext context, String text) =>
    _showTimeSlotNotice(context, 'No se pudo confirmar el horario', text);

Future<void> _showTimeSlotNotice(
  BuildContext context,
  String title,
  String text,
) => showDialog<void>(
  context: context,
  barrierColor: context.palette.bgScrim,
  builder: (context) => NoticeModal(
    icon: Icons.schedule_rounded,
    title: title,
    text: text,
    primary: 'ELEGIR OTRO HORARIO',
  ),
);

/// A venue's new schedule leaves future bookings out: «GUARDAR IGUAL» returns `true`.
Future<bool> confirmNewSchedule(BuildContext context, String text) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: context.palette.bgScrim,
      builder: (context) => NoticeModal(
        icon: Icons.warning_amber_rounded,
        title: '¿Guardar el horario nuevo?',
        text: text,
        primary: 'GUARDAR IGUAL',
        secondary: 'REVISAR EL HORARIO',
        secondaryOutlined: true,
      ),
    ) ??
    false;

/// The booking was canceled.
Future<void> showBookingCanceled(BuildContext context) => showDialog<void>(
  context: context,
  barrierColor: context.palette.bgScrim,
  builder: (context) => const NoticeModal(
    icon: Icons.check_circle_outline_rounded,
    success: true,
    title: 'Reserva cancelada con éxito',
    text: 'El horario quedó liberado y la reserva pasó a tu historial.',
    primary: 'ACEPTAR',
  ),
);

/// The administrator voided the booking.
Future<void> showBookingVoided(BuildContext context) => showDialog<void>(
  context: context,
  barrierColor: context.palette.bgScrim,
  builder: (context) => const NoticeModal(
    icon: Icons.check_circle_outline_rounded,
    success: true,
    title: 'Reserva anulada correctamente',
    text: 'El horario quedó liberado y la reserva pasó a las anuladas.',
    primary: 'ACEPTAR',
  ),
);

/// The shared «Esto cambió mientras tanto» overlay: what was on screen is no longer that
/// way, and the caller reads it again.
Future<void> showChangedMeanwhile(BuildContext context) => showDialog<void>(
  context: context,
  barrierColor: context.palette.bgScrim,
  builder: (context) => const NoticeModal(
    icon: Icons.sync_problem_rounded,
    title: 'Esto cambió mientras tanto',
    text:
        'Otra persona modificó estos datos mientras los estabas viendo. Los '
        'actualizamos para que veas el estado real.',
    primary: 'VER LO ACTUALIZADO',
  ),
);

/// The shared expired-session overlay. It cannot be dismissed: the only way out is to sign
/// in again, which the caller does when this finishes.
Future<void> showSessionExpired(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  barrierColor: context.palette.bgScrim,
  builder: (context) => const PopScope(
    canPop: false,
    child: NoticeModal(
      icon: Icons.cloud_off_rounded,
      title: 'Tu sesión expiró',
      text:
          'Por seguridad cerramos tu sesión. Volvé a iniciar sesión para continuar.',
      primary: 'IR AL INICIO DE SESIÓN',
    ),
  ),
);

/// The text that gives the most contrast over [background]: white or the app background.
Color textOn(Color background, Palette p) {
  double contrast(Color a, Color b) {
    final (x, y) = (a.computeLuminance(), b.computeLuminance());
    return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
  }

  const white = Color(0xFFFFFFFF);
  return contrast(white, background) >= contrast(p.bgBase, background)
      ? white
      : p.bgBase;
}

/// `Modal` from the prototype: icon in a circle, title, text and up to two actions. The
/// primary one closes with `true` and the secondary one with `false`.
class NoticeModal extends StatelessWidget {
  const NoticeModal({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    this.primary,
    this.secondary,
    this.success = false,
    this.primaryDanger = false,
    this.secondaryOutlined = false,
  });

  final IconData icon;
  final String title;
  final String text;
  final String? primary;
  final String? secondary;

  /// The icon in green: the notice says something went well.
  final bool success;

  /// The primary action in red: it cannot be undone.
  final bool primaryDanger;
  final bool secondaryOutlined;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryAction = primary;
    final secondaryAction = secondary;
    // On what cannot be undone, focus starts on the way out that does not destroy.
    final focusSecondary = primaryDanger;
    return DialogFrame(
      maxWidth: 320,
      children: [
        IconCircle(
          icon: icon,
          background: success ? p.stateSuccessMuted : p.stateDangerMuted,
          ink: success ? p.stateSuccessInk : p.stateDangerInk,
        ),
        const SizedBox(height: Spacing.s12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Texts.h2.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: Spacing.s12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: Texts.body.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: Spacing.s12),
        if (primaryAction != null)
          Pressable(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: primaryDanger ? p.stateDanger : p.accentBase,
                foregroundColor: primaryDanger
                    ? textOn(p.stateDanger, p)
                    : p.accentOn,
                minimumSize: const Size.fromHeight(Spacing.controlHeight),
                shape: const StadiumBorder(),
                textStyle: Texts.button,
              ),
              child: Text(primaryAction, textAlign: TextAlign.center),
            ),
          ),
        if (primaryAction != null && secondaryAction != null)
          const SizedBox(height: Spacing.s8),
        if (secondaryAction != null && secondaryOutlined)
          Pressable(
            child: OutlinedButton(
              autofocus: focusSecondary,
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: p.textPrimary,
                side: BorderSide(color: p.borderControl),
                minimumSize: const Size.fromHeight(Spacing.controlHeight),
                shape: const StadiumBorder(),
                textStyle: Texts.button,
              ),
              child: Text(secondaryAction),
            ),
          )
        else if (secondaryAction != null)
          Pressable(
            child: TextButton(
              autofocus: focusSecondary,
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: p.accentInk,
                minimumSize: const Size.fromHeight(Spacing.controlHeight),
                textStyle: Texts.button,
              ),
              child: Text(secondaryAction),
            ),
          ),
      ],
    );
  }
}

/// A dialog's frame: the card with [children] stacked. With [maxWidth] the content is
/// bounded and scrolls if it does not fit; without it, it takes the dialog's width.
class DialogFrame extends StatelessWidget {
  const DialogFrame({super.key, required this.children, this.maxWidth});

  final List<Widget> children;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const padding = EdgeInsets.all(Spacing.s24);
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    final width = maxWidth;
    return FadeIn(
      scaleFrom: 0.88,
      fromY: 0,
      curve: AppMotion.fast,
      child: Dialog(
        backgroundColor: p.bgSurfaceRaised,
        insetPadding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacing.radiusLg),
          side: BorderSide(color: p.borderDefault),
        ),
        child: width == null
            ? Padding(padding: padding, child: column)
            : ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: SingleChildScrollView(padding: padding, child: column),
              ),
      ),
    );
  }
}

/// The 64-diameter circle with a notice's icon.
class IconCircle extends StatelessWidget {
  const IconCircle({
    super.key,
    required this.icon,
    required this.background,
    required this.ink,
  });

  final IconData icon;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 28, color: ink),
    ),
  );
}
