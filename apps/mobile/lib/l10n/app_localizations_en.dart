// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginWelcome => 'WELCOME TO';

  @override
  String get loginTagline => 'Sports facility management';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginForgotPassword => 'Forgot your password?';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginStart => 'GET STARTED';

  @override
  String get loginSignIn => 'SIGN IN';

  @override
  String get loginEmailRequired => 'Enter your email address';

  @override
  String get loginPasswordRequired => 'Enter your password';

  @override
  String get loginInvalidCredentials =>
      'Could not sign in. Check your details and try again.';
}
