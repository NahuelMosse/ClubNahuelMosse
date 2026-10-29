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
  String get bookingStatusActive => 'Active';

  @override
  String get bookingStatusCompleted => 'Completed';

  @override
  String get bookingStatusCanceled => 'Canceled';

  @override
  String get bookingStatusVoided => 'Voided';

  @override
  String get bookingMyBookings => 'My bookings';

  @override
  String get bookingTabUpcoming => 'Upcoming';

  @override
  String get bookingTabHistory => 'History';

  @override
  String get bookingNoPastTitle => 'No past bookings';

  @override
  String get bookingNoPastText =>
      'No past bookings were found for your account.';

  @override
  String get bookingNoUpcomingTitle => 'No upcoming bookings';

  @override
  String get bookingNoUpcomingText =>
      'No upcoming bookings were found for your account.';

  @override
  String bookingCancelNotice(
    Object day,
    Object kind,
    Object price,
    Object time,
    Object venue,
  ) {
    return '$kind · $venue · $day, $time · $price. The slot becomes free again.';
  }

  @override
  String get bookingCancelTitle => 'Cancel the booking?';

  @override
  String get bookingCancelConfirm => 'CANCEL BOOKING';

  @override
  String get bookingCancelKeep => 'DON\'T CANCEL';

  @override
  String get bookingModify => 'MODIFY';

  @override
  String get bookingCancel => 'CANCEL';

  @override
  String bookingModifyLabel(Object what) {
    return 'Modify the booking for $what';
  }

  @override
  String bookingCancelLabel(Object what) {
    return 'Cancel the booking for $what';
  }

  @override
  String get bookingCanceling => 'Canceling the booking';

  @override
  String get bookingModified => 'Booking modified';

  @override
  String get bookingCanceledByYou => 'Canceled by you · the slot was freed';

  @override
  String bookingCanceledByYouWithReason(Object reason) {
    return 'Canceled by you · the slot was freed · $reason';
  }

  @override
  String get bookingVoidedByAdmin => 'Voided by the administrator';

  @override
  String bookingVoidedByAdminWithReason(Object reason) {
    return 'Voided by the administrator · $reason';
  }

  @override
  String get bookingToday => 'TODAY';

  @override
  String get bookingTomorrow => 'TOMORROW';

  @override
  String bookingInDays(Object days) {
    return 'IN $days DAYS';
  }

  @override
  String bookingSpokenPrice(Object amount) {
    return '$amount pesos';
  }

  @override
  String get bookingCheer => 'GAME ON!';

  @override
  String get bookingConfirmedTitle => 'Booking confirmed!';

  @override
  String get bookingSeeMine => 'SEE MY BOOKINGS';

  @override
  String get bookingBackHome => 'Back to home';

  @override
  String get bookingReceiptNote =>
      'See you there. We\'ll remind you an hour before.';

  @override
  String get bookingStepChoose => 'Pick a court';

  @override
  String get bookingStepConfirm => 'Confirm';

  @override
  String get bookingStepDone => 'Done!';

  @override
  String bookingStepLabel(Object name, Object step, Object total) {
    return 'Step $step of $total: $name';
  }

  @override
  String get bookingRowSpace => 'Space';

  @override
  String get bookingRowCourt => 'Court';

  @override
  String get bookingRowDate => 'Date';

  @override
  String get bookingRowTime => 'Time';

  @override
  String bookingCourtValue(Object condition, Object number) {
    return 'Court $number · $condition';
  }

  @override
  String get bookingBefore => 'BEFORE';

  @override
  String get bookingNow => 'NOW';

  @override
  String get bookingConfirmTitle => 'Confirm your booking';

  @override
  String get bookingConfirmButton => 'CONFIRM BOOKING';

  @override
  String bookingTaken(Object day, Object end, Object number, Object start) {
    return 'While you were confirming, someone else booked Court $number · $day, $start – $end. Pick another available time.';
  }

  @override
  String get bookingChangeTitle => 'Confirm the change';

  @override
  String get bookingChangeSave => 'SAVE THE CHANGE';

  @override
  String get bookingChangeKeep => 'KEEP THE BOOKING AS IT IS';

  @override
  String get bookingTotal => 'TOTAL';

  @override
  String bookingPerHour(Object price) {
    return '$price per hour';
  }

  @override
  String get bookingNoTimeChosen => 'No time chosen';

  @override
  String bookingDuration(num hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String bookingModifyNote(Object day, Object duration, Object range) {
    return 'You are modifying your booking for $day, $range. It keeps the same duration of $duration and the previous time is released when you save.';
  }

  @override
  String get bookingRetry => 'RETRY';

  @override
  String get availabilityContinue => 'CONTINUE';

  @override
  String get availabilityContinueChange => 'CONTINUE WITH THE CHANGE';

  @override
  String get availabilitySelectSpace => 'SELECT A COURT';

  @override
  String get availabilityDate => 'DATE';

  @override
  String get availabilityDuration => 'DURATION';

  @override
  String get availabilitySlots => 'AVAILABLE TIME';

  @override
  String availabilityDurationHint(Object closing, Object max, Object min) {
    return 'Whole hours, $min to $max h. The venue closes at $closing.';
  }

  @override
  String get availabilityLessHour => 'One hour less';

  @override
  String get availabilityMoreHour => 'One hour more';

  @override
  String get availabilityCurrent => '(current)';

  @override
  String get availabilityNoSlots => 'No times available';

  @override
  String availabilitySomeTaken(Object count) {
    return 'Some times are already taken · $count unavailable';
  }

  @override
  String availabilityFewerStarts(Object count, Object duration) {
    return 'With $duration there are fewer possible start times · $count unavailable';
  }

  @override
  String get availabilityVenueClosed =>
      'The venue is closed that day. Try another date.';

  @override
  String availabilityNoFit(Object duration) {
    return 'No slot of $duration in a row fits before closing. Try a shorter duration, another date or another court.';
  }

  @override
  String get availabilityNoneLeft =>
      'No free slots left that day. Try another date or another court.';

  @override
  String availabilityCourt(Object number) {
    return 'Court $number';
  }

  @override
  String availabilityCourtLabel(Object condition, Object number) {
    return 'Court $number, $condition';
  }

  @override
  String get spaceSearchTitle => 'Find a court';

  @override
  String get spaceSearchHeading => 'Check courts';

  @override
  String spaceSearchIntro(Object max, Object min) {
    return 'Pick a venue, a sport and a time range. Whole hours only, $min to $max hours.';
  }

  @override
  String get spaceSearchVenue => 'Venue';

  @override
  String get spaceSearchSport => 'Sport';

  @override
  String get spaceSearchKind => 'Court type';

  @override
  String get spaceSearchDate => 'Date';

  @override
  String get spaceSearchFrom => 'From';

  @override
  String get spaceSearchTo => 'To';

  @override
  String get spaceSearchPickVenue => 'Select a venue';

  @override
  String get spaceSearchPickSport => 'Select a sport';

  @override
  String get spaceSearchAllKinds => 'All types';

  @override
  String get spaceSearchDatePlaceholder => 'DD / MM / YYYY';

  @override
  String get spaceSearchDateFormat => 'Write the date as DD / MM / YYYY';

  @override
  String get spaceSearchPickDate => 'Pick the date on the calendar';

  @override
  String get spaceSearchClear => 'CLEAR';

  @override
  String get spaceSearchRun => 'SEARCH';

  @override
  String spaceSearchSubtitle(
    Object date,
    Object from,
    Object to,
    Object venue,
    Object what,
  ) {
    return '$venue · $what · $date · $from to $to';
  }

  @override
  String spaceSearchNoAvailability(Object range, Object what) {
    return 'NO AVAILABILITY · $what · $range';
  }

  @override
  String spaceSearchResults(num count, Object range, Object what) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count COURTS AVAILABLE',
      one: '1 COURT AVAILABLE',
    );
    return '$_temp0 · $what · $range';
  }

  @override
  String get spaceSearchAll => 'All';

  @override
  String get spaceSearchEmptyTitle => 'No courts available';

  @override
  String get spaceSearchEmptyText =>
      'No court matches that time. Try another range or another venue.';

  @override
  String get spaceSearchClearFilters => 'CLEAR FILTERS';

  @override
  String get spaceSearchErrorOverline => 'COULD NOT CHECK';

  @override
  String get spaceSearchErrorTitle => 'Could not check availability';

  @override
  String get spaceSearchOffline => 'Check your connection and try again.';

  @override
  String get spaceSearchServerDown =>
      'The server did not respond. Try again later.';

  @override
  String get spaceSearchFiltersKept => 'The filters you set are kept.';

  @override
  String get spaceSearchBack => 'BACK';

  @override
  String get searchProblemPast => 'The date must be in the future';

  @override
  String searchProblemFar(Object days) {
    return 'Pick a day within the next $days';
  }

  @override
  String get searchProblemClosedDay => 'The venue is closed that day';

  @override
  String get searchProblemMinHours => 'The minimum duration is one hour';

  @override
  String searchProblemMaxHours(Object hours) {
    return 'The maximum duration is $hours hours';
  }

  @override
  String searchProblemCloses(Object time) {
    return 'The venue closes at $time';
  }

  @override
  String searchProblemOpens(Object time) {
    return 'The venue opens at $time';
  }

  @override
  String get searchProblemNotFuture => 'The time must be in the future';

  @override
  String get spaceCovered => 'Covered';

  @override
  String get spaceOpenAir => 'Open air';

  @override
  String get spaceLit => 'Lit';

  @override
  String get spaceUnlit => 'Unlit';

  @override
  String get spaceWithLighting => 'with lighting';

  @override
  String get spaceWithoutLighting => 'without lighting';

  @override
  String spacePerHour(Object price) {
    return '$price per hour';
  }

  @override
  String spaceDescription(Object condition, Object kind, Object price) {
    return '$kind · $condition · $price per hour';
  }

  @override
  String spaceSpoken(
    Object condition,
    Object kind,
    Object lighting,
    Object name,
    Object price,
  ) {
    return '$kind, $name, $condition, $lighting, $price pesos per hour';
  }

  @override
  String get spacePerHourBadge => '/ HOUR';

  @override
  String get spaceBook => 'SEE TIMES / BOOK';

  @override
  String spaceBookLabel(Object kind, Object number) {
    return '$kind, court $number';
  }

  @override
  String get spaceNoneTitle => 'There are no courts yet';

  @override
  String get spaceNoneText => 'This venue has no courts available right now.';

  @override
  String get spaceNoMatchTitle => 'No courts match this filter';

  @override
  String get spaceNoMatchText => 'Try another sport or another type.';

  @override
  String get venuesTitle => 'Venues';

  @override
  String venueCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count venues',
      one: '1 venue',
    );
    return '$_temp0';
  }

  @override
  String venueSpaceCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count courts',
      one: '1 court',
    );
    return '$_temp0';
  }

  @override
  String venuesSummary(Object spaces, Object venues) {
    return '$venues · $spaces · each with its own hours';
  }

  @override
  String get venuesNoneTitle => 'There are no venues yet';

  @override
  String get venuesNoneText => 'The club has not added its venues yet.';

  @override
  String get venuesFailedTitle => 'We couldn\'t show the venues';

  @override
  String get venuesFailedText => 'Check your connection and try again.';

  @override
  String get venueSeeCourts => 'See courts';

  @override
  String venueDaysHours(Object closing, Object days, Object opening) {
    return '$days · $opening to $closing';
  }

  @override
  String venueCardLabel(
    Object address,
    Object closing,
    Object days,
    Object name,
    Object opening,
    Object spaces,
  ) {
    return '$name, $address, $days from $opening to $closing, $spaces';
  }

  @override
  String venueAddressHours(Object address, Object closing, Object opening) {
    return '$address · $opening to $closing';
  }

  @override
  String get venueBack => 'All venues';

  @override
  String get venueAllSports => 'all sports';

  @override
  String get venueAllKinds => 'all types';

  @override
  String get venueSportTitle => 'SPORT';

  @override
  String get venueSportPrefix => 'Sport';

  @override
  String get venueKindTitle => 'COURT TYPE';

  @override
  String get venueKindPrefix => 'Type';

  @override
  String get venueKindAll => 'All';

  @override
  String get venueDaysMondayToSunday => 'Monday to Sunday';

  @override
  String get venueDaysMondayToSaturday => 'Monday to Saturday';

  @override
  String get venueDaysMondayToFriday => 'Monday to Friday';

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
