// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Club Nahuel Mosse';

  @override
  String get accountTitle => 'Your account';

  @override
  String get accountCloseCard => 'Close your account card';

  @override
  String get accountActiveMember => 'ACTIVE MEMBER';

  @override
  String get accountFullProfile => 'Full profile';

  @override
  String get accountMyBookings => 'My bookings';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountSignOutUpper => 'SIGN OUT';

  @override
  String get accountDeleteUpper => 'DELETE ACCOUNT';

  @override
  String get accountDeleting => 'DELETING YOUR ACCOUNT…';

  @override
  String get accountCancel => 'CANCEL';

  @override
  String get accountBackToSignIn => 'BACK TO SIGN IN';

  @override
  String get accessDeniedTitle => 'Access denied';

  @override
  String get accessDeniedBody =>
      'Your account does not have administrator permissions. We are taking you to My bookings.';

  @override
  String get accessDeniedGoToBookings => 'GO TO MY BOOKINGS';

  @override
  String get recoveryTitle => 'Recover password';

  @override
  String get recoveryIntro =>
      'Enter the email you registered with and we will send you a link to create a new one.';

  @override
  String get recoverySend => 'SEND LINK';

  @override
  String get recoveryCheckEmail => 'Check your email';

  @override
  String get recoveryLinkSent =>
      'If the email is registered, we sent you a link to create a new password. The link expires in 30 minutes.';

  @override
  String get recoveryResend => 'Resend the email';

  @override
  String get newPasswordChecking => 'Checking the link';

  @override
  String get newPasswordInvalidTitle => 'The link is not valid';

  @override
  String get newPasswordInvalidAfterCutoff =>
      'This link was already used or has expired. If you just saved your new password, sign in with it.';

  @override
  String get newPasswordInvalid =>
      'This link was already used or has expired. Request a new one from the sign-in screen.';

  @override
  String get newPasswordRequestNew => 'REQUEST A NEW LINK';

  @override
  String get newPasswordBackToSignIn => 'Back to sign in';

  @override
  String get newPasswordBarTitle => 'New password';

  @override
  String get newPasswordHeading => 'Create a new password';

  @override
  String get newPasswordExplanation =>
      'It must have at least 8 characters, an uppercase letter and a number.';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordHeading => 'Change your password';

  @override
  String get changePasswordExplanation =>
      'We need your current password to confirm it is you.';

  @override
  String get changePasswordBack => 'BACK TO PROFILE';

  @override
  String get passwordCurrentUpper => 'CURRENT PASSWORD';

  @override
  String get passwordCurrent => 'Current password';

  @override
  String get passwordCurrentPlaceholder => 'Your current password';

  @override
  String get passwordNewUpper => 'NEW PASSWORD';

  @override
  String get passwordNew => 'New password';

  @override
  String get passwordNewPlaceholder => 'At least 8 characters';

  @override
  String get passwordRepeatUpper => 'REPEAT PASSWORD';

  @override
  String get passwordRepeat => 'Repeat password';

  @override
  String get passwordRepeatPlaceholder => 'Type it again';

  @override
  String passwordRuleMet(Object rule) {
    return '$rule: met';
  }

  @override
  String passwordRuleMissing(Object rule) {
    return '$rule: missing';
  }

  @override
  String get registerTitle => 'Sign up';

  @override
  String get registerHeading => 'Create your account';

  @override
  String get registerAllRequired => 'All fields are required.';

  @override
  String get registerAlreadyExists =>
      'Your account already exists: the registration was completed before the outage. Sign in with your email and password.';

  @override
  String get registerFirstNamePlaceholder => 'Your first name';

  @override
  String get registerLastNamePlaceholder => 'Your last name';

  @override
  String get registerBirthPlaceholder => 'DD / MM / YYYY';

  @override
  String get registerPickDate => 'Pick a date';

  @override
  String get registerPasswordPlaceholder =>
      '8+ characters, uppercase and number';

  @override
  String get registerCreate => 'CREATE ACCOUNT';

  @override
  String get registerDoneTitle => 'Account created!';

  @override
  String get registerDoneText =>
      'Your account was created successfully. You can now sign in with your email and password.';

  @override
  String get profileFirstNameUpper => 'FIRST NAME';

  @override
  String get profileFirstName => 'First name';

  @override
  String get profileLastNameUpper => 'LAST NAME';

  @override
  String get profileLastName => 'Last name';

  @override
  String get profileDni => 'DNI';

  @override
  String get profileBirthUpper => 'DATE OF BIRTH';

  @override
  String get profileBirth => 'Date of birth';

  @override
  String get profileBirthShort => 'Birth';

  @override
  String get profileEmailUpper => 'EMAIL';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileEmailShort => 'Email';

  @override
  String get profileEmailPlaceholder => 'you@email.com';

  @override
  String get profilePasswordUpper => 'PASSWORD';

  @override
  String get profilePassword => 'Password';

  @override
  String profileFixedField(Object label, Object value) {
    return '$label: $value. Cannot be changed';
  }

  @override
  String get profilePersonalUpper => 'PERSONAL DETAILS';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileSecurityUpper => 'SECURITY';

  @override
  String get profileAppearanceUpper => 'APPEARANCE';

  @override
  String get profileDarkMode => 'Dark mode';

  @override
  String get profileInvalidData => 'The data format is not valid';

  @override
  String get profilePickDate => 'Choose the date in the calendar';

  @override
  String get profileSave => 'SAVE';

  @override
  String get profileDeleteTitle => 'Delete your account?';

  @override
  String get profileDeleteBody =>
      'This action is permanent. Your data and your active bookings will be deleted.';

  @override
  String get ruleFirstNameRequired => 'First name is required';

  @override
  String get ruleLastNameRequired => 'Last name is required';

  @override
  String ruleNameTooLong(int max) {
    return 'Maximum $max characters';
  }

  @override
  String get ruleDniRequired => 'The DNI is required';

  @override
  String get ruleDniFormat => 'The DNI has 7 or 8 digits';

  @override
  String get ruleBirthRequired => 'Date of birth is required';

  @override
  String get ruleBirthInvalid => 'The date is not valid';

  @override
  String get ruleBirthNotPast => 'The date must be before today';

  @override
  String get ruleEmailRequired => 'Email is required';

  @override
  String get ruleEmailFormat => 'Check the email format';

  @override
  String get rulePasswordRequired => 'The password is required';

  @override
  String get rulePasswordLength => 'At least 8 characters';

  @override
  String get rulePasswordUppercase => 'One uppercase letter';

  @override
  String get rulePasswordNumber => 'At least one number';

  @override
  String get rulePasswordMismatch => 'Passwords do not match';

  @override
  String get homeGreetingMorning => 'GOOD MORNING,';

  @override
  String get homeGreetingAfternoon => 'GOOD AFTERNOON,';

  @override
  String get homeGreetingNight => 'GOOD EVENING,';

  @override
  String get homeHeroTitle => 'BOOK YOUR COURT';

  @override
  String get homeMarkerVenues => 'VENUES';

  @override
  String get homeMarkerCourts => 'COURTS';

  @override
  String get homeMarkerUpcoming => 'UPCOMING';

  @override
  String get homeQuickAccess => 'QUICK ACCESS';

  @override
  String get homeSports => 'SPORTS';

  @override
  String get homeFindCourt => 'Find a court';

  @override
  String get homeFindCourtHint => 'By venue, date and time';

  @override
  String get homeViewVenues => 'View venues';

  @override
  String get homeViewVenuesHint => 'Hours and courts of each one';

  @override
  String get homeNextBooking => 'YOUR NEXT BOOKING';

  @override
  String get homeViewAll => 'VIEW ALL →';

  @override
  String get homeBackLabel => 'Home';

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
