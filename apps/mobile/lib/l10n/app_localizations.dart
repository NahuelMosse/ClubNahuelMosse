import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Club Nahuel Mosse'**
  String get appName;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'WELCOME TO'**
  String get loginWelcome;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Sports facility management'**
  String get loginTagline;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get loginForgotPassword;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @loginStart.
  ///
  /// In en, this message translates to:
  /// **'GET STARTED'**
  String get loginStart;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get loginSignIn;

  /// No description provided for @loginEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get loginEmailRequired;

  /// No description provided for @commonDuration.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}}'**
  String commonDuration(num hours);

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCloseNotice.
  ///
  /// In en, this message translates to:
  /// **'Close notice'**
  String get commonCloseNotice;

  /// No description provided for @commonShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get commonShowPassword;

  /// No description provided for @commonHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get commonHidePassword;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonLoading;

  /// No description provided for @commonMemberCard.
  ///
  /// In en, this message translates to:
  /// **'MEMBER CARD'**
  String get commonMemberCard;

  /// No description provided for @commonSelected.
  ///
  /// In en, this message translates to:
  /// **'SELECTED'**
  String get commonSelected;

  /// No description provided for @commonSavePassword.
  ///
  /// In en, this message translates to:
  /// **'SAVE PASSWORD'**
  String get commonSavePassword;

  /// No description provided for @commonPasswordUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get commonPasswordUpdatedTitle;

  /// No description provided for @commonPasswordUpdatedText.
  ///
  /// In en, this message translates to:
  /// **'Your password was changed. Use it the next time you sign in.'**
  String get commonPasswordUpdatedText;

  /// No description provided for @commonYourDay.
  ///
  /// In en, this message translates to:
  /// **'YOUR DAY ON THE COURT'**
  String get commonYourDay;

  /// No description provided for @commonSlotFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get commonSlotFree;

  /// No description provided for @commonSlotTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get commonSlotTaken;

  /// No description provided for @commonSlotChosen.
  ///
  /// In en, this message translates to:
  /// **'Chosen'**
  String get commonSlotChosen;

  /// No description provided for @commonSlotFreeSemantics.
  ///
  /// In en, this message translates to:
  /// **'{hour} h free'**
  String commonSlotFreeSemantics(Object hour);

  /// No description provided for @commonSlotTakenSemantics.
  ///
  /// In en, this message translates to:
  /// **'{hour} h taken'**
  String commonSlotTakenSemantics(Object hour);

  /// No description provided for @commonSlotChosenSemantics.
  ///
  /// In en, this message translates to:
  /// **'{hour} h chosen'**
  String commonSlotChosenSemantics(Object hour);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get navHome;

  /// No description provided for @navVenues.
  ///
  /// In en, this message translates to:
  /// **'VENUES'**
  String get navVenues;

  /// No description provided for @navBookings.
  ///
  /// In en, this message translates to:
  /// **'BOOKINGS'**
  String get navBookings;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get navProfile;

  /// No description provided for @navSpaces.
  ///
  /// In en, this message translates to:
  /// **'SPACES'**
  String get navSpaces;

  /// No description provided for @errorConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get errorConnectionTitle;

  /// No description provided for @errorConnectionText.
  ///
  /// In en, this message translates to:
  /// **'We could not connect. Check your internet connection and try again.'**
  String get errorConnectionText;

  /// No description provided for @errorServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get errorServerTitle;

  /// No description provided for @errorNoResponseText.
  ///
  /// In en, this message translates to:
  /// **'The server is not responding. Try again in a few minutes.'**
  String get errorNoResponseText;

  /// No description provided for @errorGenericText.
  ///
  /// In en, this message translates to:
  /// **'We could not process the operation right now. Try again later.'**
  String get errorGenericText;

  /// No description provided for @errorTimeSlotTakenTitle.
  ///
  /// In en, this message translates to:
  /// **'That time slot was taken'**
  String get errorTimeSlotTakenTitle;

  /// No description provided for @errorTimeSlotRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm the time slot'**
  String get errorTimeSlotRejectedTitle;

  /// No description provided for @errorChooseAnotherTime.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE ANOTHER TIME'**
  String get errorChooseAnotherTime;

  /// No description provided for @errorSaveNewScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Save the new schedule?'**
  String get errorSaveNewScheduleTitle;

  /// No description provided for @errorSaveAnyway.
  ///
  /// In en, this message translates to:
  /// **'SAVE ANYWAY'**
  String get errorSaveAnyway;

  /// No description provided for @errorReviewSchedule.
  ///
  /// In en, this message translates to:
  /// **'REVIEW THE SCHEDULE'**
  String get errorReviewSchedule;

  /// No description provided for @errorBookingCanceledTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking canceled'**
  String get errorBookingCanceledTitle;

  /// No description provided for @errorBookingCanceledText.
  ///
  /// In en, this message translates to:
  /// **'The time slot was freed and the booking moved to your history.'**
  String get errorBookingCanceledText;

  /// No description provided for @errorBookingVoidedTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking voided'**
  String get errorBookingVoidedTitle;

  /// No description provided for @errorBookingVoidedText.
  ///
  /// In en, this message translates to:
  /// **'The time slot was freed and the booking moved to the voided ones.'**
  String get errorBookingVoidedText;

  /// No description provided for @errorChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'This changed in the meantime'**
  String get errorChangedTitle;

  /// No description provided for @errorChangedText.
  ///
  /// In en, this message translates to:
  /// **'Someone else changed this data while you were viewing it. We updated it so you see the current state.'**
  String get errorChangedText;

  /// No description provided for @errorChangedAction.
  ///
  /// In en, this message translates to:
  /// **'SEE THE UPDATE'**
  String get errorChangedAction;

  /// No description provided for @errorSessionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Your session expired'**
  String get errorSessionExpiredTitle;

  /// No description provided for @errorSessionExpiredText.
  ///
  /// In en, this message translates to:
  /// **'For security we signed you out. Sign in again to continue.'**
  String get errorSessionExpiredText;

  /// No description provided for @errorSessionExpiredAction.
  ///
  /// In en, this message translates to:
  /// **'GO TO SIGN IN'**
  String get errorSessionExpiredAction;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsBellUnread.
  ///
  /// In en, this message translates to:
  /// **'Notifications, {unread} unread'**
  String notificationsBellUnread(Object unread);

  /// No description provided for @notificationUnread.
  ///
  /// In en, this message translates to:
  /// **'unread'**
  String get notificationUnread;

  /// No description provided for @notificationFrom.
  ///
  /// In en, this message translates to:
  /// **'CLUBNAHUELMOSSE · {when}'**
  String notificationFrom(Object when);

  /// No description provided for @notificationsCloseLabel.
  ///
  /// In en, this message translates to:
  /// **'Close notifications'**
  String get notificationsCloseLabel;

  /// No description provided for @notificationsPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notificationsPanelTitle;

  /// No description provided for @notificationsMarkAll.
  ///
  /// In en, this message translates to:
  /// **'MARK ALL READ'**
  String get notificationsMarkAll;

  /// No description provided for @notificationsDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get notificationsDisabledTitle;

  /// No description provided for @notificationsDisabledText.
  ///
  /// In en, this message translates to:
  /// **'Turn on notices so we can remind you about your bookings an hour before.'**
  String get notificationsDisabledText;

  /// No description provided for @notificationsEnable.
  ///
  /// In en, this message translates to:
  /// **'TURN ON NOTIFICATIONS'**
  String get notificationsEnable;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyText.
  ///
  /// In en, this message translates to:
  /// **'Here you will see the reminders for your bookings.'**
  String get notificationsEmptyText;

  /// No description provided for @arrivalToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get arrivalToday;

  /// No description provided for @arrivalYesterday.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get arrivalYesterday;

  /// No description provided for @arrivalNow.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get arrivalNow;

  /// No description provided for @arrivalMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} MIN AGO'**
  String arrivalMinutesAgo(Object minutes);

  /// No description provided for @arrivalHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} H AGO'**
  String arrivalHoursAgo(Object hours);

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordRequired;

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Check your details and try again.'**
  String get loginInvalidCredentials;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
