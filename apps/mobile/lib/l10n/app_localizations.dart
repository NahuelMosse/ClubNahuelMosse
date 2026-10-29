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

  /// No description provided for @adminPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'ADMIN PANEL'**
  String get adminPanelTitle;

  /// No description provided for @adminRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get adminRetry;

  /// No description provided for @adminVenuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Venues'**
  String get adminVenuesTitle;

  /// No description provided for @adminAddVenue.
  ///
  /// In en, this message translates to:
  /// **'ADD VENUE'**
  String get adminAddVenue;

  /// No description provided for @adminActiveVenues.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ACTIVE VENUE} other{{count} ACTIVE VENUES}}'**
  String adminActiveVenues(num count);

  /// No description provided for @adminNoVenues.
  ///
  /// In en, this message translates to:
  /// **'No venues yet'**
  String get adminNoVenues;

  /// No description provided for @adminSpacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Spaces'**
  String get adminSpacesTitle;

  /// No description provided for @adminAddSpace.
  ///
  /// In en, this message translates to:
  /// **'ADD SPACE'**
  String get adminAddSpace;

  /// No description provided for @adminSpacesSummary.
  ///
  /// In en, this message translates to:
  /// **'{spaces, plural, =1{1 ACTIVE SPACE} other{{spaces} ACTIVE SPACES}} · {venues, plural, =1{1 VENUE} other{{venues} VENUES}}'**
  String adminSpacesSummary(num spaces, num venues);

  /// No description provided for @adminNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'No spaces yet'**
  String get adminNoSpaces;

  /// No description provided for @adminCourtsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{COURT} other{COURTS}}'**
  String adminCourtsLabel(num count);

  /// No description provided for @adminCourtsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 court} other{{count} courts}}'**
  String adminCourtsCount(num count);

  /// No description provided for @adminVenueSchedule.
  ///
  /// In en, this message translates to:
  /// **'{days} from {opening} to {closing}'**
  String adminVenueSchedule(Object closing, Object days, Object opening);

  /// No description provided for @adminVenueScheduleShort.
  ///
  /// In en, this message translates to:
  /// **'{days} · {opening} to {closing}'**
  String adminVenueScheduleShort(Object closing, Object days, Object opening);

  /// No description provided for @adminEditVenue.
  ///
  /// In en, this message translates to:
  /// **'Edit venue'**
  String get adminEditVenue;

  /// No description provided for @adminEditVenueNamed.
  ///
  /// In en, this message translates to:
  /// **'Edit venue {name}'**
  String adminEditVenueNamed(Object name);

  /// No description provided for @adminDeactivateVenue.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get adminDeactivateVenue;

  /// No description provided for @adminDeactivateVenueNamed.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}'**
  String adminDeactivateVenueNamed(Object name);

  /// No description provided for @adminEditSpace.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get adminEditSpace;

  /// No description provided for @adminEditSpaceNamed.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String adminEditSpaceNamed(Object name);

  /// No description provided for @adminDeactivateSpace.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get adminDeactivateSpace;

  /// No description provided for @adminDeactivateSpaceNamed.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}'**
  String adminDeactivateSpaceNamed(Object name);

  /// No description provided for @adminDeactivatingNamed.
  ///
  /// In en, this message translates to:
  /// **'Deactivating {name}'**
  String adminDeactivatingNamed(Object name);

  /// No description provided for @adminSpaceDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Sports space deactivated'**
  String get adminSpaceDeactivated;

  /// No description provided for @adminLoadingBookings.
  ///
  /// In en, this message translates to:
  /// **'Loading bookings…'**
  String get adminLoadingBookings;

  /// No description provided for @adminNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get adminNoResults;

  /// No description provided for @adminNoResultsText.
  ///
  /// In en, this message translates to:
  /// **'No booking matches the applied filters.'**
  String get adminNoResultsText;

  /// No description provided for @adminClearFilters.
  ///
  /// In en, this message translates to:
  /// **'CLEAR FILTERS'**
  String get adminClearFilters;

  /// No description provided for @adminNoBookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings'**
  String get adminNoBookings;

  /// No description provided for @adminNoBookingsText.
  ///
  /// In en, this message translates to:
  /// **'No booking has been registered in the system yet.'**
  String get adminNoBookingsText;

  /// No description provided for @adminStatusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get adminStatusActive;

  /// No description provided for @adminStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get adminStatusCompleted;

  /// No description provided for @adminStatusCanceled.
  ///
  /// In en, this message translates to:
  /// **'CANCELED'**
  String get adminStatusCanceled;

  /// No description provided for @adminStatusVoided.
  ///
  /// In en, this message translates to:
  /// **'VOIDED'**
  String get adminStatusVoided;

  /// No description provided for @adminFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminFilterAll;

  /// No description provided for @adminFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminFilterActive;

  /// No description provided for @adminFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get adminFilterCompleted;

  /// No description provided for @adminFilterCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get adminFilterCanceled;

  /// No description provided for @adminFilterVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get adminFilterVoided;

  /// No description provided for @adminVoidBooking.
  ///
  /// In en, this message translates to:
  /// **'VOID BOOKING'**
  String get adminVoidBooking;

  /// No description provided for @adminVoidBookingLabel.
  ///
  /// In en, this message translates to:
  /// **'Void the booking of {user}, {sport}, {date}, {schedule}'**
  String adminVoidBookingLabel(
    Object date,
    Object schedule,
    Object sport,
    Object user,
  );

  /// No description provided for @adminVoidBookingFor.
  ///
  /// In en, this message translates to:
  /// **'Void the booking of {user}'**
  String adminVoidBookingFor(Object user);

  /// No description provided for @adminVoidingBooking.
  ///
  /// In en, this message translates to:
  /// **'Voiding the booking'**
  String get adminVoidingBooking;

  /// No description provided for @adminBackToList.
  ///
  /// In en, this message translates to:
  /// **'BACK TO THE LIST'**
  String get adminBackToList;

  /// No description provided for @adminVenueWord.
  ///
  /// In en, this message translates to:
  /// **'venue'**
  String get adminVenueWord;

  /// No description provided for @adminUserWord.
  ///
  /// In en, this message translates to:
  /// **'user'**
  String get adminUserWord;

  /// No description provided for @adminBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get adminBack;

  /// No description provided for @adminBookingDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking detail'**
  String get adminBookingDetailTitle;

  /// No description provided for @adminVenueUpper.
  ///
  /// In en, this message translates to:
  /// **'VENUE'**
  String get adminVenueUpper;

  /// No description provided for @adminSportUpper.
  ///
  /// In en, this message translates to:
  /// **'SPORT'**
  String get adminSportUpper;

  /// No description provided for @adminStatusUpper.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get adminStatusUpper;

  /// No description provided for @adminDateRangeUpper.
  ///
  /// In en, this message translates to:
  /// **'DATE RANGE'**
  String get adminDateRangeUpper;

  /// No description provided for @adminSearchBooking.
  ///
  /// In en, this message translates to:
  /// **'Search booking'**
  String get adminSearchBooking;

  /// No description provided for @adminSearchShort.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get adminSearchShort;

  /// No description provided for @adminFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get adminFilters;

  /// No description provided for @adminUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get adminUser;

  /// No description provided for @adminVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get adminVenue;

  /// No description provided for @adminCourt.
  ///
  /// In en, this message translates to:
  /// **'Court'**
  String get adminCourt;

  /// No description provided for @adminWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get adminWhen;

  /// No description provided for @adminAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get adminAmount;

  /// No description provided for @adminBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get adminBookingsTitle;

  /// No description provided for @adminResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 RESULT} other{{count} RESULTS}}'**
  String adminResultsCount(num count);

  /// No description provided for @adminTotalBookings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 BOOKING IN TOTAL} other{{count} BOOKINGS IN TOTAL}}'**
  String adminTotalBookings(num count);

  /// No description provided for @adminDeactivateVenueTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate the venue?'**
  String get adminDeactivateVenueTitle;

  /// No description provided for @adminDeactivateConfirm.
  ///
  /// In en, this message translates to:
  /// **'DEACTIVATE'**
  String get adminDeactivateConfirm;

  /// No description provided for @adminCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get adminCancel;

  /// No description provided for @adminAccept.
  ///
  /// In en, this message translates to:
  /// **'ACCEPT'**
  String get adminAccept;

  /// No description provided for @adminVenueHasBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'The venue cannot be deactivated'**
  String get adminVenueHasBookingsTitle;

  /// No description provided for @adminVenueHasBookingsText.
  ///
  /// In en, this message translates to:
  /// **'The venue has future bookings on its sports spaces. Manage them first.'**
  String get adminVenueHasBookingsText;

  /// No description provided for @adminDeactivateSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate the space?'**
  String get adminDeactivateSpaceTitle;

  /// No description provided for @adminDeactivateSpaceText.
  ///
  /// In en, this message translates to:
  /// **'{name}. This action is permanent.'**
  String adminDeactivateSpaceText(Object name);

  /// No description provided for @adminDeactivateSpaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM DEACTIVATION'**
  String get adminDeactivateSpaceConfirm;

  /// No description provided for @adminSpaceHasBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'The space cannot be deactivated'**
  String get adminSpaceHasBookingsTitle;

  /// No description provided for @adminSpaceHasBookingsText.
  ///
  /// In en, this message translates to:
  /// **'The space has future bookings. Manage them first.'**
  String get adminSpaceHasBookingsText;

  /// No description provided for @adminDeactivateVenueText.
  ///
  /// In en, this message translates to:
  /// **'{name} · {address}. Its sports spaces stop being available.'**
  String adminDeactivateVenueText(Object address, Object name);

  /// No description provided for @adminVenueDeactivated.
  ///
  /// In en, this message translates to:
  /// **'The venue was deactivated'**
  String get adminVenueDeactivated;

  /// No description provided for @adminSpaceDeactivatedDone.
  ///
  /// In en, this message translates to:
  /// **'The space was deactivated'**
  String get adminSpaceDeactivatedDone;

  /// No description provided for @adminClear.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get adminClear;

  /// No description provided for @adminApply.
  ///
  /// In en, this message translates to:
  /// **'APPLY'**
  String get adminApply;

  /// No description provided for @adminClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get adminClose;

  /// No description provided for @adminSince.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get adminSince;

  /// No description provided for @adminUntil.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get adminUntil;

  /// No description provided for @adminDatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'DD / MM / YYYY'**
  String get adminDatePlaceholder;

  /// No description provided for @adminInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'Invalid date'**
  String get adminInvalidDate;

  /// No description provided for @adminSinceAfterUntil.
  ///
  /// In en, this message translates to:
  /// **'From cannot be later than To'**
  String get adminSinceAfterUntil;

  /// No description provided for @adminUntilBeforeSince.
  ///
  /// In en, this message translates to:
  /// **'To cannot be earlier than From'**
  String get adminUntilBeforeSince;

  /// No description provided for @adminRequiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get adminRequiredField;

  /// No description provided for @adminPriceRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a price between \$ 1 and \$ 9.999.999'**
  String get adminPriceRange;

  /// No description provided for @adminMissingAll.
  ///
  /// In en, this message translates to:
  /// **'Complete venue, sport and type'**
  String get adminMissingAll;

  /// No description provided for @adminMissingVenue.
  ///
  /// In en, this message translates to:
  /// **'The venue is missing'**
  String get adminMissingVenue;

  /// No description provided for @adminMissingSport.
  ///
  /// In en, this message translates to:
  /// **'The sport is missing'**
  String get adminMissingSport;

  /// No description provided for @adminMissingType.
  ///
  /// In en, this message translates to:
  /// **'The court type is missing'**
  String get adminMissingType;

  /// No description provided for @adminSpaceFormHint.
  ///
  /// In en, this message translates to:
  /// **'The name is built from the venue, the address, the sport, the type and the number.'**
  String get adminSpaceFormHint;

  /// No description provided for @adminCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get adminCondition;

  /// No description provided for @adminConditionUpper.
  ///
  /// In en, this message translates to:
  /// **'CONDITION'**
  String get adminConditionUpper;

  /// No description provided for @adminLighting.
  ///
  /// In en, this message translates to:
  /// **'Lighting'**
  String get adminLighting;

  /// No description provided for @adminLightingUpper.
  ///
  /// In en, this message translates to:
  /// **'LIGHTING'**
  String get adminLightingUpper;

  /// No description provided for @adminCovered.
  ///
  /// In en, this message translates to:
  /// **'Covered'**
  String get adminCovered;

  /// No description provided for @adminOpenAir.
  ///
  /// In en, this message translates to:
  /// **'Open air'**
  String get adminOpenAir;

  /// No description provided for @adminLit.
  ///
  /// In en, this message translates to:
  /// **'Lit'**
  String get adminLit;

  /// No description provided for @adminUnlit.
  ///
  /// In en, this message translates to:
  /// **'Unlit'**
  String get adminUnlit;

  /// No description provided for @adminSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get adminSelect;

  /// No description provided for @adminSelectVenue.
  ///
  /// In en, this message translates to:
  /// **'Select a venue'**
  String get adminSelectVenue;

  /// No description provided for @adminSelectSport.
  ///
  /// In en, this message translates to:
  /// **'Select a sport'**
  String get adminSelectSport;

  /// No description provided for @adminSelectType.
  ///
  /// In en, this message translates to:
  /// **'Select the type'**
  String get adminSelectType;

  /// No description provided for @adminSport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get adminSport;

  /// No description provided for @adminType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get adminType;

  /// No description provided for @adminTypeUpper.
  ///
  /// In en, this message translates to:
  /// **'TYPE'**
  String get adminTypeUpper;

  /// No description provided for @adminNewSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'New space'**
  String get adminNewSpaceTitle;

  /// No description provided for @adminNewSpaceHeading.
  ///
  /// In en, this message translates to:
  /// **'New sports space'**
  String get adminNewSpaceHeading;

  /// No description provided for @adminEditSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit space'**
  String get adminEditSpaceTitle;

  /// No description provided for @adminEditSpaceHeading.
  ///
  /// In en, this message translates to:
  /// **'Edit sports space'**
  String get adminEditSpaceHeading;

  /// No description provided for @adminSaveSpace.
  ///
  /// In en, this message translates to:
  /// **'SAVE SPACE'**
  String get adminSaveSpace;

  /// No description provided for @adminChangesSaved.
  ///
  /// In en, this message translates to:
  /// **'The changes were saved'**
  String get adminChangesSaved;

  /// No description provided for @adminGeneratedName.
  ///
  /// In en, this message translates to:
  /// **'AUTOMATICALLY GENERATED NAME'**
  String get adminGeneratedName;

  /// No description provided for @adminNameFailed.
  ///
  /// In en, this message translates to:
  /// **'The name could not be computed'**
  String get adminNameFailed;

  /// No description provided for @adminPricePerHour.
  ///
  /// In en, this message translates to:
  /// **'Price per hour'**
  String get adminPricePerHour;

  /// No description provided for @adminPricePerHourUpper.
  ///
  /// In en, this message translates to:
  /// **'PRICE PER HOUR'**
  String get adminPricePerHourUpper;

  /// No description provided for @adminGoToList.
  ///
  /// In en, this message translates to:
  /// **'GO TO THE LIST'**
  String get adminGoToList;

  /// No description provided for @adminSpaceCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Sports space created!'**
  String get adminSpaceCreatedTitle;

  /// No description provided for @adminSpaceCreatedText.
  ///
  /// In en, this message translates to:
  /// **'It is now available for users to book.'**
  String get adminSpaceCreatedText;

  /// No description provided for @adminCreateAnother.
  ///
  /// In en, this message translates to:
  /// **'Create another'**
  String get adminCreateAnother;

  /// No description provided for @adminVenueCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Venue created!'**
  String get adminVenueCreatedTitle;

  /// No description provided for @adminVenueCreatedText.
  ///
  /// In en, this message translates to:
  /// **'The venue now shows in the list and you can start adding sports spaces to it.'**
  String get adminVenueCreatedText;

  /// No description provided for @adminCreateAnotherVenue.
  ///
  /// In en, this message translates to:
  /// **'Create another venue'**
  String get adminCreateAnotherVenue;

  /// No description provided for @adminDeactivatingSpace.
  ///
  /// In en, this message translates to:
  /// **'Deactivating the space'**
  String get adminDeactivatingSpace;

  /// No description provided for @adminDeactivateSpaceButton.
  ///
  /// In en, this message translates to:
  /// **'DEACTIVATE THE SPACE'**
  String get adminDeactivateSpaceButton;

  /// No description provided for @adminTraceTitle.
  ///
  /// In en, this message translates to:
  /// **'TRACEABILITY'**
  String get adminTraceTitle;

  /// No description provided for @adminTraceCreated.
  ///
  /// In en, this message translates to:
  /// **'Booking created'**
  String get adminTraceCreated;

  /// No description provided for @adminTraceBy.
  ///
  /// In en, this message translates to:
  /// **'By {who} · {date}'**
  String adminTraceBy(Object date, Object who);

  /// No description provided for @adminTraceByReason.
  ///
  /// In en, this message translates to:
  /// **'By {who} · {date} · {reason}'**
  String adminTraceByReason(Object date, Object reason, Object who);

  /// No description provided for @adminTraceVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided by the administrator'**
  String get adminTraceVoided;

  /// No description provided for @adminTraceAnAdmin.
  ///
  /// In en, this message translates to:
  /// **'an administrator'**
  String get adminTraceAnAdmin;

  /// No description provided for @adminTraceCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled by the user'**
  String get adminTraceCanceled;

  /// No description provided for @adminTraceNoticeSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent to the user'**
  String get adminTraceNoticeSent;

  /// No description provided for @adminTraceNoticeInbox.
  ///
  /// In en, this message translates to:
  /// **'Notice in the inbox of the user'**
  String get adminTraceNoticeInbox;

  /// No description provided for @adminTracePushFailed.
  ///
  /// In en, this message translates to:
  /// **'The push was not sent'**
  String get adminTracePushFailed;

  /// No description provided for @adminVoidReasonSemantics.
  ///
  /// In en, this message translates to:
  /// **'Reason for voiding'**
  String get adminVoidReasonSemantics;

  /// No description provided for @adminVoidReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'REASON FOR VOIDING'**
  String get adminVoidReasonLabel;

  /// No description provided for @adminVoidReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'The reason is required to void'**
  String get adminVoidReasonRequired;

  /// No description provided for @adminVoidDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Void this booking?'**
  String get adminVoidDialogTitle;

  /// No description provided for @adminVoidConfirm.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM VOIDING'**
  String get adminVoidConfirm;

  /// No description provided for @adminBackUpper.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get adminBackUpper;

  /// No description provided for @adminNewVenueHeading.
  ///
  /// In en, this message translates to:
  /// **'New venue'**
  String get adminNewVenueHeading;

  /// No description provided for @adminAddVenueTitle.
  ///
  /// In en, this message translates to:
  /// **'Add venue'**
  String get adminAddVenueTitle;

  /// No description provided for @adminVenueFormHint.
  ///
  /// In en, this message translates to:
  /// **'Name, address and hours are required.'**
  String get adminVenueFormHint;

  /// No description provided for @adminVenueNameUpper.
  ///
  /// In en, this message translates to:
  /// **'VENUE NAME'**
  String get adminVenueNameUpper;

  /// No description provided for @adminVenueName.
  ///
  /// In en, this message translates to:
  /// **'Venue name'**
  String get adminVenueName;

  /// No description provided for @adminVenueNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'E.g. Haedo venue'**
  String get adminVenueNamePlaceholder;

  /// No description provided for @adminAddressUpper.
  ///
  /// In en, this message translates to:
  /// **'ADDRESS'**
  String get adminAddressUpper;

  /// No description provided for @adminAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get adminAddress;

  /// No description provided for @adminAddressPlaceholderNew.
  ///
  /// In en, this message translates to:
  /// **'Street and number'**
  String get adminAddressPlaceholderNew;

  /// No description provided for @adminAddressPlaceholderEdit.
  ///
  /// In en, this message translates to:
  /// **'Write the address'**
  String get adminAddressPlaceholderEdit;

  /// No description provided for @adminOpeningUpper.
  ///
  /// In en, this message translates to:
  /// **'OPENING TIME'**
  String get adminOpeningUpper;

  /// No description provided for @adminOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening time'**
  String get adminOpening;

  /// No description provided for @adminClosingUpper.
  ///
  /// In en, this message translates to:
  /// **'CLOSING TIME'**
  String get adminClosingUpper;

  /// No description provided for @adminClosing.
  ///
  /// In en, this message translates to:
  /// **'Closing time'**
  String get adminClosing;

  /// No description provided for @adminOpenDaysUpper.
  ///
  /// In en, this message translates to:
  /// **'OPEN DAYS'**
  String get adminOpenDaysUpper;

  /// No description provided for @adminOpenDays.
  ///
  /// In en, this message translates to:
  /// **'Open days'**
  String get adminOpenDays;

  /// No description provided for @adminSaveVenue.
  ///
  /// In en, this message translates to:
  /// **'SAVE VENUE'**
  String get adminSaveVenue;

  /// No description provided for @adminSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'SAVE CHANGES'**
  String get adminSaveChanges;

  /// No description provided for @adminDeactivatingVenue.
  ///
  /// In en, this message translates to:
  /// **'Deactivating the venue'**
  String get adminDeactivatingVenue;

  /// No description provided for @adminDeactivateVenueButton.
  ///
  /// In en, this message translates to:
  /// **'DEACTIVATE THE VENUE'**
  String get adminDeactivateVenueButton;

  /// No description provided for @adminVenueNameRequired.
  ///
  /// In en, this message translates to:
  /// **'The name is required'**
  String get adminVenueNameRequired;

  /// No description provided for @adminVenueAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'The address is required'**
  String get adminVenueAddressRequired;

  /// No description provided for @adminVenueAddressStreet.
  ///
  /// In en, this message translates to:
  /// **'Write the street and number'**
  String get adminVenueAddressStreet;

  /// No description provided for @adminOpensAtRequired.
  ///
  /// In en, this message translates to:
  /// **'The opening time is required'**
  String get adminOpensAtRequired;

  /// No description provided for @adminClosesAtRequired.
  ///
  /// In en, this message translates to:
  /// **'The closing time is required'**
  String get adminClosesAtRequired;

  /// No description provided for @adminClosesBeforeOpens.
  ///
  /// In en, this message translates to:
  /// **'The closing time must be after the opening time'**
  String get adminClosesBeforeOpens;

  /// No description provided for @adminOutsideSubject.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 future booking at {venue}} other{{count} future bookings at {venue}}}'**
  String adminOutsideSubject(num count, Object venue);

  /// No description provided for @adminOutsideStartsBefore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{starts} other{start}} before {hour}'**
  String adminOutsideStartsBefore(num count, Object hour);

  /// No description provided for @adminOutsideEndsAfter.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{ends} other{end}} after {hour}'**
  String adminOutsideEndsAfter(num count, Object hour);

  /// No description provided for @adminOutsideClosedDay.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{falls} other{fall}} on a day the venue stops opening'**
  String adminOutsideClosedDay(num count);

  /// No description provided for @adminOutsideNewSchedule.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{falls} other{fall}} outside the new schedule'**
  String adminOutsideNewSchedule(num count);

  /// No description provided for @adminOutsideKeeps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{it stays at its original time} other{they stay at their original time}}'**
  String adminOutsideKeeps(num count);

  /// No description provided for @adminOutsideNotice.
  ///
  /// In en, this message translates to:
  /// **'{subject} {reason}. If you save, {keeps}: the change applies to new bookings.'**
  String adminOutsideNotice(Object keeps, Object reason, Object subject);

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
