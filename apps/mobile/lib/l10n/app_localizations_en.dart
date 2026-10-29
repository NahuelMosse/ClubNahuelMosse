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
  String commonDuration(num hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get commonRetry => 'RETRY';

  @override
  String get commonBack => 'Back';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCloseNotice => 'Close notice';

  @override
  String get commonShowPassword => 'Show password';

  @override
  String get commonHidePassword => 'Hide password';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonMemberCard => 'MEMBER CARD';

  @override
  String get commonSelected => 'SELECTED';

  @override
  String get commonSavePassword => 'SAVE PASSWORD';

  @override
  String get commonPasswordUpdatedTitle => 'Password updated';

  @override
  String get commonPasswordUpdatedText =>
      'Your password was changed. Use it the next time you sign in.';

  @override
  String get commonYourDay => 'YOUR DAY ON THE COURT';

  @override
  String get commonSlotFree => 'Free';

  @override
  String get commonSlotTaken => 'Taken';

  @override
  String get commonSlotChosen => 'Chosen';

  @override
  String commonSlotFreeSemantics(Object hour) {
    return '$hour h free';
  }

  @override
  String commonSlotTakenSemantics(Object hour) {
    return '$hour h taken';
  }

  @override
  String commonSlotChosenSemantics(Object hour) {
    return '$hour h chosen';
  }

  @override
  String get navHome => 'HOME';

  @override
  String get navVenues => 'VENUES';

  @override
  String get navBookings => 'BOOKINGS';

  @override
  String get navProfile => 'PROFILE';

  @override
  String get navSpaces => 'SPACES';

  @override
  String get errorConnectionTitle => 'Connection error';

  @override
  String get errorConnectionText =>
      'We could not connect. Check your internet connection and try again.';

  @override
  String get errorServerTitle => 'Server error';

  @override
  String get errorNoResponseText =>
      'The server is not responding. Try again in a few minutes.';

  @override
  String get errorGenericText =>
      'We could not process the operation right now. Try again later.';

  @override
  String get errorTimeSlotTakenTitle => 'That time slot was taken';

  @override
  String get errorTimeSlotRejectedTitle => 'We could not confirm the time slot';

  @override
  String get errorChooseAnotherTime => 'CHOOSE ANOTHER TIME';

  @override
  String get errorSaveNewScheduleTitle => 'Save the new schedule?';

  @override
  String get errorSaveAnyway => 'SAVE ANYWAY';

  @override
  String get errorReviewSchedule => 'REVIEW THE SCHEDULE';

  @override
  String get errorBookingCanceledTitle => 'Booking canceled';

  @override
  String get errorBookingCanceledText =>
      'The time slot was freed and the booking moved to your history.';

  @override
  String get errorBookingVoidedTitle => 'Booking voided';

  @override
  String get errorBookingVoidedText =>
      'The time slot was freed and the booking moved to the voided ones.';

  @override
  String get errorChangedTitle => 'This changed in the meantime';

  @override
  String get errorChangedText =>
      'Someone else changed this data while you were viewing it. We updated it so you see the current state.';

  @override
  String get errorChangedAction => 'SEE THE UPDATE';

  @override
  String get errorSessionExpiredTitle => 'Your session expired';

  @override
  String get errorSessionExpiredText =>
      'For security we signed you out. Sign in again to continue.';

  @override
  String get errorSessionExpiredAction => 'GO TO SIGN IN';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String notificationsBellUnread(Object unread) {
    return 'Notifications, $unread unread';
  }

  @override
  String get notificationUnread => 'unread';

  @override
  String notificationFrom(Object when) {
    return 'CLUBNAHUELMOSSE · $when';
  }

  @override
  String get notificationsCloseLabel => 'Close notifications';

  @override
  String get notificationsPanelTitle => 'NOTIFICATIONS';

  @override
  String get notificationsMarkAll => 'MARK ALL READ';

  @override
  String get notificationsDisabledTitle => 'Notifications are off';

  @override
  String get notificationsDisabledText =>
      'Turn on notices so we can remind you about your bookings an hour before.';

  @override
  String get notificationsEnable => 'TURN ON NOTIFICATIONS';

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsEmptyText =>
      'Here you will see the reminders for your bookings.';

  @override
  String get arrivalToday => 'TODAY';

  @override
  String get arrivalYesterday => 'YESTERDAY';

  @override
  String get arrivalNow => 'NOW';

  @override
  String arrivalMinutesAgo(Object minutes) {
    return '$minutes MIN AGO';
  }

  @override
  String arrivalHoursAgo(Object hours) {
    return '$hours H AGO';
  }

  @override
  String get loginPasswordRequired => 'Enter your password';

  @override
  String get loginInvalidCredentials =>
      'Could not sign in. Check your details and try again.';
}
