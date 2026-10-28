import 'package:flutter/material.dart';

import '../../../common/pending_booking.dart';
import '../../../theme/theme.dart';
import 'login_form.dart';
import 'session.dart';

export 'login_form.dart' show invalidCredentialsMessage;

/// Inicio de sesión sobre la foto del club. Va siempre en oscuro: el texto se apoya en la
/// foto oscurecida, no en el fondo del tema.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.session, required this.pending});

  final Session session;

  /// La reserva que se estaba confirmando cuando venció la sesión.
  final PendingBooking pending;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: darkTheme,
      child: LoginForm(session: session, pending: pending),
    );
  }
}
