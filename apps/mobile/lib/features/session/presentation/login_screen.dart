import 'package:flutter/material.dart';

import '../../../common/pending_booking.dart';
import '../../../theme/theme.dart';
import 'login_form.dart';
import 'session.dart';

/// Sign-in over the photo of the club. It is always dark: the text rests on the darkened
/// photo, not on the theme's background.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.session, required this.pending});

  final Session session;

  /// The booking that was being confirmed when the session expired.
  final PendingBooking pending;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: darkTheme,
      child: LoginForm(session: session, pending: pending),
    );
  }
}
