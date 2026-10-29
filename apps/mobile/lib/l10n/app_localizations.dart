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

  /// No description provided for @bookingStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get bookingStatusActive;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get bookingStatusCanceled;

  /// No description provided for @bookingStatusVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get bookingStatusVoided;

  /// No description provided for @bookingMyBookings.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get bookingMyBookings;

  /// No description provided for @bookingTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get bookingTabUpcoming;

  /// No description provided for @bookingTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get bookingTabHistory;

  /// No description provided for @bookingNoPastTitle.
  ///
  /// In en, this message translates to:
  /// **'No past bookings'**
  String get bookingNoPastTitle;

  /// No description provided for @bookingNoPastText.
  ///
  /// In en, this message translates to:
  /// **'No past bookings were found for your account.'**
  String get bookingNoPastText;

  /// No description provided for @bookingNoUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'No upcoming bookings'**
  String get bookingNoUpcomingTitle;

  /// No description provided for @bookingNoUpcomingText.
  ///
  /// In en, this message translates to:
  /// **'No upcoming bookings were found for your account.'**
  String get bookingNoUpcomingText;

  /// No description provided for @bookingCancelNotice.
  ///
  /// In en, this message translates to:
  /// **'{kind} · {venue} · {day}, {time} · {price}. The slot becomes free again.'**
  String bookingCancelNotice(
    Object day,
    Object kind,
    Object price,
    Object time,
    Object venue,
  );

  /// No description provided for @bookingCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel the booking?'**
  String get bookingCancelTitle;

  /// No description provided for @bookingCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'CANCEL BOOKING'**
  String get bookingCancelConfirm;

  /// No description provided for @bookingCancelKeep.
  ///
  /// In en, this message translates to:
  /// **'DON\'T CANCEL'**
  String get bookingCancelKeep;

  /// No description provided for @bookingModify.
  ///
  /// In en, this message translates to:
  /// **'MODIFY'**
  String get bookingModify;

  /// No description provided for @bookingCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get bookingCancel;

  /// No description provided for @bookingModifyLabel.
  ///
  /// In en, this message translates to:
  /// **'Modify the booking for {what}'**
  String bookingModifyLabel(Object what);

  /// No description provided for @bookingCancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel the booking for {what}'**
  String bookingCancelLabel(Object what);

  /// No description provided for @bookingCanceling.
  ///
  /// In en, this message translates to:
  /// **'Canceling the booking'**
  String get bookingCanceling;

  /// No description provided for @bookingModified.
  ///
  /// In en, this message translates to:
  /// **'Booking modified'**
  String get bookingModified;

  /// No description provided for @bookingCanceledByYou.
  ///
  /// In en, this message translates to:
  /// **'Canceled by you · the slot was freed'**
  String get bookingCanceledByYou;

  /// No description provided for @bookingCanceledByYouWithReason.
  ///
  /// In en, this message translates to:
  /// **'Canceled by you · the slot was freed · {reason}'**
  String bookingCanceledByYouWithReason(Object reason);

  /// No description provided for @bookingVoidedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Voided by the administrator'**
  String get bookingVoidedByAdmin;

  /// No description provided for @bookingVoidedByAdminWithReason.
  ///
  /// In en, this message translates to:
  /// **'Voided by the administrator · {reason}'**
  String bookingVoidedByAdminWithReason(Object reason);

  /// No description provided for @bookingToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get bookingToday;

  /// No description provided for @bookingTomorrow.
  ///
  /// In en, this message translates to:
  /// **'TOMORROW'**
  String get bookingTomorrow;

  /// No description provided for @bookingInDays.
  ///
  /// In en, this message translates to:
  /// **'IN {days} DAYS'**
  String bookingInDays(Object days);

  /// No description provided for @bookingSpokenPrice.
  ///
  /// In en, this message translates to:
  /// **'{amount} pesos'**
  String bookingSpokenPrice(Object amount);

  /// No description provided for @bookingCheer.
  ///
  /// In en, this message translates to:
  /// **'GAME ON!'**
  String get bookingCheer;

  /// No description provided for @bookingConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed!'**
  String get bookingConfirmedTitle;

  /// No description provided for @bookingSeeMine.
  ///
  /// In en, this message translates to:
  /// **'SEE MY BOOKINGS'**
  String get bookingSeeMine;

  /// No description provided for @bookingBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get bookingBackHome;

  /// No description provided for @bookingReceiptNote.
  ///
  /// In en, this message translates to:
  /// **'See you there. We\'ll remind you an hour before.'**
  String get bookingReceiptNote;

  /// No description provided for @bookingStepChoose.
  ///
  /// In en, this message translates to:
  /// **'Pick a court'**
  String get bookingStepChoose;

  /// No description provided for @bookingStepConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get bookingStepConfirm;

  /// No description provided for @bookingStepDone.
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get bookingStepDone;

  /// No description provided for @bookingStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}: {name}'**
  String bookingStepLabel(Object name, Object step, Object total);

  /// No description provided for @bookingRowSpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get bookingRowSpace;

  /// No description provided for @bookingRowCourt.
  ///
  /// In en, this message translates to:
  /// **'Court'**
  String get bookingRowCourt;

  /// No description provided for @bookingRowDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get bookingRowDate;

  /// No description provided for @bookingRowTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get bookingRowTime;

  /// No description provided for @bookingCourtValue.
  ///
  /// In en, this message translates to:
  /// **'Court {number} · {condition}'**
  String bookingCourtValue(Object condition, Object number);

  /// No description provided for @bookingBefore.
  ///
  /// In en, this message translates to:
  /// **'BEFORE'**
  String get bookingBefore;

  /// No description provided for @bookingNow.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get bookingNow;

  /// No description provided for @bookingConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your booking'**
  String get bookingConfirmTitle;

  /// No description provided for @bookingConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM BOOKING'**
  String get bookingConfirmButton;

  /// No description provided for @bookingTaken.
  ///
  /// In en, this message translates to:
  /// **'While you were confirming, someone else booked Court {number} · {day}, {start} – {end}. Pick another available time.'**
  String bookingTaken(Object day, Object end, Object number, Object start);

  /// No description provided for @bookingChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm the change'**
  String get bookingChangeTitle;

  /// No description provided for @bookingChangeSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE THE CHANGE'**
  String get bookingChangeSave;

  /// No description provided for @bookingChangeKeep.
  ///
  /// In en, this message translates to:
  /// **'KEEP THE BOOKING AS IT IS'**
  String get bookingChangeKeep;

  /// No description provided for @bookingTotal.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get bookingTotal;

  /// No description provided for @bookingPerHour.
  ///
  /// In en, this message translates to:
  /// **'{price} per hour'**
  String bookingPerHour(Object price);

  /// No description provided for @bookingNoTimeChosen.
  ///
  /// In en, this message translates to:
  /// **'No time chosen'**
  String get bookingNoTimeChosen;

  /// No description provided for @bookingDuration.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}}'**
  String bookingDuration(num hours);

  /// No description provided for @bookingModifyNote.
  ///
  /// In en, this message translates to:
  /// **'You are modifying your booking for {day}, {range}. It keeps the same duration of {duration} and the previous time is released when you save.'**
  String bookingModifyNote(Object day, Object duration, Object range);

  /// No description provided for @bookingRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get bookingRetry;

  /// No description provided for @availabilityContinue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get availabilityContinue;

  /// No description provided for @availabilityContinueChange.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITH THE CHANGE'**
  String get availabilityContinueChange;

  /// No description provided for @availabilitySelectSpace.
  ///
  /// In en, this message translates to:
  /// **'SELECT A COURT'**
  String get availabilitySelectSpace;

  /// No description provided for @availabilityDate.
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get availabilityDate;

  /// No description provided for @availabilityDuration.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get availabilityDuration;

  /// No description provided for @availabilitySlots.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE TIME'**
  String get availabilitySlots;

  /// No description provided for @availabilityDurationHint.
  ///
  /// In en, this message translates to:
  /// **'Whole hours, {min} to {max} h. The venue closes at {closing}.'**
  String availabilityDurationHint(Object closing, Object max, Object min);

  /// No description provided for @availabilityLessHour.
  ///
  /// In en, this message translates to:
  /// **'One hour less'**
  String get availabilityLessHour;

  /// No description provided for @availabilityMoreHour.
  ///
  /// In en, this message translates to:
  /// **'One hour more'**
  String get availabilityMoreHour;

  /// No description provided for @availabilityCurrent.
  ///
  /// In en, this message translates to:
  /// **'(current)'**
  String get availabilityCurrent;

  /// No description provided for @availabilityNoSlots.
  ///
  /// In en, this message translates to:
  /// **'No times available'**
  String get availabilityNoSlots;

  /// No description provided for @availabilitySomeTaken.
  ///
  /// In en, this message translates to:
  /// **'Some times are already taken · {count} unavailable'**
  String availabilitySomeTaken(Object count);

  /// No description provided for @availabilityFewerStarts.
  ///
  /// In en, this message translates to:
  /// **'With {duration} there are fewer possible start times · {count} unavailable'**
  String availabilityFewerStarts(Object count, Object duration);

  /// No description provided for @availabilityVenueClosed.
  ///
  /// In en, this message translates to:
  /// **'The venue is closed that day. Try another date.'**
  String get availabilityVenueClosed;

  /// No description provided for @availabilityNoFit.
  ///
  /// In en, this message translates to:
  /// **'No slot of {duration} in a row fits before closing. Try a shorter duration, another date or another court.'**
  String availabilityNoFit(Object duration);

  /// No description provided for @availabilityNoneLeft.
  ///
  /// In en, this message translates to:
  /// **'No free slots left that day. Try another date or another court.'**
  String get availabilityNoneLeft;

  /// No description provided for @availabilityCourt.
  ///
  /// In en, this message translates to:
  /// **'Court {number}'**
  String availabilityCourt(Object number);

  /// No description provided for @availabilityCourtLabel.
  ///
  /// In en, this message translates to:
  /// **'Court {number}, {condition}'**
  String availabilityCourtLabel(Object condition, Object number);

  /// No description provided for @spaceSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a court'**
  String get spaceSearchTitle;

  /// No description provided for @spaceSearchHeading.
  ///
  /// In en, this message translates to:
  /// **'Check courts'**
  String get spaceSearchHeading;

  /// No description provided for @spaceSearchIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick a venue, a sport and a time range. Whole hours only, {min} to {max} hours.'**
  String spaceSearchIntro(Object max, Object min);

  /// No description provided for @spaceSearchVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get spaceSearchVenue;

  /// No description provided for @spaceSearchSport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get spaceSearchSport;

  /// No description provided for @spaceSearchKind.
  ///
  /// In en, this message translates to:
  /// **'Court type'**
  String get spaceSearchKind;

  /// No description provided for @spaceSearchDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get spaceSearchDate;

  /// No description provided for @spaceSearchFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get spaceSearchFrom;

  /// No description provided for @spaceSearchTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get spaceSearchTo;

  /// No description provided for @spaceSearchPickVenue.
  ///
  /// In en, this message translates to:
  /// **'Select a venue'**
  String get spaceSearchPickVenue;

  /// No description provided for @spaceSearchPickSport.
  ///
  /// In en, this message translates to:
  /// **'Select a sport'**
  String get spaceSearchPickSport;

  /// No description provided for @spaceSearchAllKinds.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get spaceSearchAllKinds;

  /// No description provided for @spaceSearchDatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'DD / MM / YYYY'**
  String get spaceSearchDatePlaceholder;

  /// No description provided for @spaceSearchDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Write the date as DD / MM / YYYY'**
  String get spaceSearchDateFormat;

  /// No description provided for @spaceSearchPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick the date on the calendar'**
  String get spaceSearchPickDate;

  /// No description provided for @spaceSearchClear.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get spaceSearchClear;

  /// No description provided for @spaceSearchRun.
  ///
  /// In en, this message translates to:
  /// **'SEARCH'**
  String get spaceSearchRun;

  /// No description provided for @spaceSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{venue} · {what} · {date} · {from} to {to}'**
  String spaceSearchSubtitle(
    Object date,
    Object from,
    Object to,
    Object venue,
    Object what,
  );

  /// No description provided for @spaceSearchNoAvailability.
  ///
  /// In en, this message translates to:
  /// **'NO AVAILABILITY · {what} · {range}'**
  String spaceSearchNoAvailability(Object range, Object what);

  /// No description provided for @spaceSearchResults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 COURT AVAILABLE} other{{count} COURTS AVAILABLE}} · {what} · {range}'**
  String spaceSearchResults(num count, Object range, Object what);

  /// No description provided for @spaceSearchAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get spaceSearchAll;

  /// No description provided for @spaceSearchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No courts available'**
  String get spaceSearchEmptyTitle;

  /// No description provided for @spaceSearchEmptyText.
  ///
  /// In en, this message translates to:
  /// **'No court matches that time. Try another range or another venue.'**
  String get spaceSearchEmptyText;

  /// No description provided for @spaceSearchClearFilters.
  ///
  /// In en, this message translates to:
  /// **'CLEAR FILTERS'**
  String get spaceSearchClearFilters;

  /// No description provided for @spaceSearchErrorOverline.
  ///
  /// In en, this message translates to:
  /// **'COULD NOT CHECK'**
  String get spaceSearchErrorOverline;

  /// No description provided for @spaceSearchErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not check availability'**
  String get spaceSearchErrorTitle;

  /// No description provided for @spaceSearchOffline.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get spaceSearchOffline;

  /// No description provided for @spaceSearchServerDown.
  ///
  /// In en, this message translates to:
  /// **'The server did not respond. Try again later.'**
  String get spaceSearchServerDown;

  /// No description provided for @spaceSearchFiltersKept.
  ///
  /// In en, this message translates to:
  /// **'The filters you set are kept.'**
  String get spaceSearchFiltersKept;

  /// No description provided for @spaceSearchBack.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get spaceSearchBack;

  /// No description provided for @searchProblemPast.
  ///
  /// In en, this message translates to:
  /// **'The date must be in the future'**
  String get searchProblemPast;

  /// No description provided for @searchProblemFar.
  ///
  /// In en, this message translates to:
  /// **'Pick a day within the next {days}'**
  String searchProblemFar(Object days);

  /// No description provided for @searchProblemClosedDay.
  ///
  /// In en, this message translates to:
  /// **'The venue is closed that day'**
  String get searchProblemClosedDay;

  /// No description provided for @searchProblemMinHours.
  ///
  /// In en, this message translates to:
  /// **'The minimum duration is one hour'**
  String get searchProblemMinHours;

  /// No description provided for @searchProblemMaxHours.
  ///
  /// In en, this message translates to:
  /// **'The maximum duration is {hours} hours'**
  String searchProblemMaxHours(Object hours);

  /// No description provided for @searchProblemCloses.
  ///
  /// In en, this message translates to:
  /// **'The venue closes at {time}'**
  String searchProblemCloses(Object time);

  /// No description provided for @searchProblemOpens.
  ///
  /// In en, this message translates to:
  /// **'The venue opens at {time}'**
  String searchProblemOpens(Object time);

  /// No description provided for @searchProblemNotFuture.
  ///
  /// In en, this message translates to:
  /// **'The time must be in the future'**
  String get searchProblemNotFuture;

  /// No description provided for @spaceCovered.
  ///
  /// In en, this message translates to:
  /// **'Covered'**
  String get spaceCovered;

  /// No description provided for @spaceOpenAir.
  ///
  /// In en, this message translates to:
  /// **'Open air'**
  String get spaceOpenAir;

  /// No description provided for @spaceLit.
  ///
  /// In en, this message translates to:
  /// **'Lit'**
  String get spaceLit;

  /// No description provided for @spaceUnlit.
  ///
  /// In en, this message translates to:
  /// **'Unlit'**
  String get spaceUnlit;

  /// No description provided for @spaceWithLighting.
  ///
  /// In en, this message translates to:
  /// **'with lighting'**
  String get spaceWithLighting;

  /// No description provided for @spaceWithoutLighting.
  ///
  /// In en, this message translates to:
  /// **'without lighting'**
  String get spaceWithoutLighting;

  /// No description provided for @spacePerHour.
  ///
  /// In en, this message translates to:
  /// **'{price} per hour'**
  String spacePerHour(Object price);

  /// No description provided for @spaceDescription.
  ///
  /// In en, this message translates to:
  /// **'{kind} · {condition} · {price} per hour'**
  String spaceDescription(Object condition, Object kind, Object price);

  /// No description provided for @spaceSpoken.
  ///
  /// In en, this message translates to:
  /// **'{kind}, {name}, {condition}, {lighting}, {price} pesos per hour'**
  String spaceSpoken(
    Object condition,
    Object kind,
    Object lighting,
    Object name,
    Object price,
  );

  /// No description provided for @spacePerHourBadge.
  ///
  /// In en, this message translates to:
  /// **'/ HOUR'**
  String get spacePerHourBadge;

  /// No description provided for @spaceBook.
  ///
  /// In en, this message translates to:
  /// **'SEE TIMES / BOOK'**
  String get spaceBook;

  /// No description provided for @spaceBookLabel.
  ///
  /// In en, this message translates to:
  /// **'{kind}, court {number}'**
  String spaceBookLabel(Object kind, Object number);

  /// No description provided for @spaceNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'There are no courts yet'**
  String get spaceNoneTitle;

  /// No description provided for @spaceNoneText.
  ///
  /// In en, this message translates to:
  /// **'This venue has no courts available right now.'**
  String get spaceNoneText;

  /// No description provided for @spaceNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No courts match this filter'**
  String get spaceNoMatchTitle;

  /// No description provided for @spaceNoMatchText.
  ///
  /// In en, this message translates to:
  /// **'Try another sport or another type.'**
  String get spaceNoMatchText;

  /// No description provided for @venuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Venues'**
  String get venuesTitle;

  /// No description provided for @venueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 venue} other{{count} venues}}'**
  String venueCount(num count);

  /// No description provided for @venueSpaceCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 court} other{{count} courts}}'**
  String venueSpaceCount(num count);

  /// No description provided for @venuesSummary.
  ///
  /// In en, this message translates to:
  /// **'{venues} · {spaces} · each with its own hours'**
  String venuesSummary(Object spaces, Object venues);

  /// No description provided for @venuesNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'There are no venues yet'**
  String get venuesNoneTitle;

  /// No description provided for @venuesNoneText.
  ///
  /// In en, this message translates to:
  /// **'The club has not added its venues yet.'**
  String get venuesNoneText;

  /// No description provided for @venuesFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t show the venues'**
  String get venuesFailedTitle;

  /// No description provided for @venuesFailedText.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get venuesFailedText;

  /// No description provided for @venueSeeCourts.
  ///
  /// In en, this message translates to:
  /// **'See courts'**
  String get venueSeeCourts;

  /// No description provided for @venueDaysHours.
  ///
  /// In en, this message translates to:
  /// **'{days} · {opening} to {closing}'**
  String venueDaysHours(Object closing, Object days, Object opening);

  /// No description provided for @venueCardLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}, {address}, {days} from {opening} to {closing}, {spaces}'**
  String venueCardLabel(
    Object address,
    Object closing,
    Object days,
    Object name,
    Object opening,
    Object spaces,
  );

  /// No description provided for @venueAddressHours.
  ///
  /// In en, this message translates to:
  /// **'{address} · {opening} to {closing}'**
  String venueAddressHours(Object address, Object closing, Object opening);

  /// No description provided for @venueBack.
  ///
  /// In en, this message translates to:
  /// **'All venues'**
  String get venueBack;

  /// No description provided for @venueAllSports.
  ///
  /// In en, this message translates to:
  /// **'all sports'**
  String get venueAllSports;

  /// No description provided for @venueAllKinds.
  ///
  /// In en, this message translates to:
  /// **'all types'**
  String get venueAllKinds;

  /// No description provided for @venueSportTitle.
  ///
  /// In en, this message translates to:
  /// **'SPORT'**
  String get venueSportTitle;

  /// No description provided for @venueSportPrefix.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get venueSportPrefix;

  /// No description provided for @venueKindTitle.
  ///
  /// In en, this message translates to:
  /// **'COURT TYPE'**
  String get venueKindTitle;

  /// No description provided for @venueKindPrefix.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get venueKindPrefix;

  /// No description provided for @venueKindAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get venueKindAll;

  /// No description provided for @venueDaysMondayToSunday.
  ///
  /// In en, this message translates to:
  /// **'Monday to Sunday'**
  String get venueDaysMondayToSunday;

  /// No description provided for @venueDaysMondayToSaturday.
  ///
  /// In en, this message translates to:
  /// **'Monday to Saturday'**
  String get venueDaysMondayToSaturday;

  /// No description provided for @venueDaysMondayToFriday.
  ///
  /// In en, this message translates to:
  /// **'Monday to Friday'**
  String get venueDaysMondayToFriday;

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
