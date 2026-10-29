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
  String get adminPanelTitle => 'ADMIN PANEL';

  @override
  String get adminRetry => 'RETRY';

  @override
  String get adminVenuesTitle => 'Venues';

  @override
  String get adminAddVenue => 'ADD VENUE';

  @override
  String adminActiveVenues(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ACTIVE VENUES',
      one: '1 ACTIVE VENUE',
    );
    return '$_temp0';
  }

  @override
  String get adminNoVenues => 'No venues yet';

  @override
  String get adminSpacesTitle => 'Spaces';

  @override
  String get adminAddSpace => 'ADD SPACE';

  @override
  String adminSpacesSummary(num spaces, num venues) {
    String _temp0 = intl.Intl.pluralLogic(
      spaces,
      locale: localeName,
      other: '$spaces ACTIVE SPACES',
      one: '1 ACTIVE SPACE',
    );
    String _temp1 = intl.Intl.pluralLogic(
      venues,
      locale: localeName,
      other: '$venues VENUES',
      one: '1 VENUE',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get adminNoSpaces => 'No spaces yet';

  @override
  String adminCourtsLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'COURTS',
      one: 'COURT',
    );
    return '$_temp0';
  }

  @override
  String adminCourtsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count courts',
      one: '1 court',
    );
    return '$_temp0';
  }

  @override
  String adminVenueSchedule(Object days, Object opening, Object closing) {
    return '$days from $opening to $closing';
  }

  @override
  String adminVenueScheduleShort(Object days, Object opening, Object closing) {
    return '$days · $opening to $closing';
  }

  @override
  String get adminEditVenue => 'Edit venue';

  @override
  String adminEditVenueNamed(Object name) {
    return 'Edit venue $name';
  }

  @override
  String get adminDeactivateVenue => 'Deactivate';

  @override
  String adminDeactivateVenueNamed(Object name) {
    return 'Deactivate $name';
  }

  @override
  String get adminEditSpace => 'Edit';

  @override
  String adminEditSpaceNamed(Object name) {
    return 'Edit $name';
  }

  @override
  String get adminDeactivateSpace => 'Deactivate';

  @override
  String adminDeactivateSpaceNamed(Object name) {
    return 'Deactivate $name';
  }

  @override
  String adminDeactivatingNamed(Object name) {
    return 'Deactivating $name';
  }

  @override
  String get adminSpaceDeactivated => 'Sports space deactivated';

  @override
  String get adminLoadingBookings => 'Loading bookings…';

  @override
  String get adminNoResults => 'No results';

  @override
  String get adminNoResultsText => 'No booking matches the applied filters.';

  @override
  String get adminClearFilters => 'CLEAR FILTERS';

  @override
  String get adminNoBookings => 'No bookings';

  @override
  String get adminNoBookingsText =>
      'No booking has been registered in the system yet.';

  @override
  String get adminStatusActive => 'ACTIVE';

  @override
  String get adminStatusCompleted => 'COMPLETED';

  @override
  String get adminStatusCanceled => 'CANCELED';

  @override
  String get adminStatusVoided => 'VOIDED';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminFilterActive => 'Active';

  @override
  String get adminFilterCompleted => 'Completed';

  @override
  String get adminFilterCanceled => 'Canceled';

  @override
  String get adminFilterVoided => 'Voided';

  @override
  String get adminVoidBooking => 'VOID BOOKING';

  @override
  String adminVoidBookingLabel(
    Object user,
    Object sport,
    Object date,
    Object schedule,
  ) {
    return 'Void the booking of $user, $sport, $date, $schedule';
  }

  @override
  String adminVoidBookingFor(Object user) {
    return 'Void the booking of $user';
  }

  @override
  String get adminVoidingBooking => 'Voiding the booking';

  @override
  String get adminBackToList => 'BACK TO THE LIST';

  @override
  String get adminVenueWord => 'venue';

  @override
  String get adminUserWord => 'user';

  @override
  String get adminBack => 'Back';

  @override
  String get adminBookingDetailTitle => 'Booking detail';

  @override
  String get adminVenueUpper => 'VENUE';

  @override
  String get adminSportUpper => 'SPORT';

  @override
  String get adminStatusUpper => 'STATUS';

  @override
  String get adminDateRangeUpper => 'DATE RANGE';

  @override
  String get adminSearchBooking => 'Search booking';

  @override
  String get adminSearchShort => 'Search';

  @override
  String get adminFilters => 'Filters';

  @override
  String get adminUser => 'User';

  @override
  String get adminVenue => 'Venue';

  @override
  String get adminCourt => 'Court';

  @override
  String get adminWhen => 'When';

  @override
  String get adminAmount => 'Amount';

  @override
  String get adminBookingsTitle => 'Bookings';

  @override
  String adminResultsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count RESULTS',
      one: '1 RESULT',
    );
    return '$_temp0';
  }

  @override
  String adminTotalBookings(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count BOOKINGS IN TOTAL',
      one: '1 BOOKING IN TOTAL',
    );
    return '$_temp0';
  }

  @override
  String get adminDeactivateVenueTitle => 'Deactivate the venue?';

  @override
  String get adminDeactivateConfirm => 'DEACTIVATE';

  @override
  String get adminCancel => 'CANCEL';

  @override
  String get adminAccept => 'ACCEPT';

  @override
  String get adminVenueHasBookingsTitle => 'The venue cannot be deactivated';

  @override
  String get adminVenueHasBookingsText =>
      'The venue has future bookings on its sports spaces. Manage them first.';

  @override
  String get adminDeactivateSpaceTitle => 'Deactivate the space?';

  @override
  String adminDeactivateSpaceText(Object name) {
    return '$name. This action is permanent.';
  }

  @override
  String get adminDeactivateSpaceConfirm => 'CONFIRM DEACTIVATION';

  @override
  String get adminSpaceHasBookingsTitle => 'The space cannot be deactivated';

  @override
  String get adminSpaceHasBookingsText =>
      'The space has future bookings. Manage them first.';

  @override
  String adminDeactivateVenueText(Object name, Object address) {
    return '$name · $address. Its sports spaces stop being available.';
  }

  @override
  String get adminVenueDeactivated => 'The venue was deactivated';

  @override
  String get adminSpaceDeactivatedDone => 'The space was deactivated';

  @override
  String get adminClear => 'CLEAR';

  @override
  String get adminApply => 'APPLY';

  @override
  String get adminClose => 'Close';

  @override
  String get adminSince => 'From';

  @override
  String get adminUntil => 'To';

  @override
  String get adminDatePlaceholder => 'DD / MM / YYYY';

  @override
  String get adminInvalidDate => 'Invalid date';

  @override
  String get adminSinceAfterUntil => 'From cannot be later than To';

  @override
  String get adminUntilBeforeSince => 'To cannot be earlier than From';

  @override
  String get adminRequiredField => 'This field is required';

  @override
  String get adminPriceRange => 'Enter a price between \$ 1 and \$ 9.999.999';

  @override
  String get adminMissingAll => 'Complete venue, sport and type';

  @override
  String get adminMissingVenue => 'The venue is missing';

  @override
  String get adminMissingSport => 'The sport is missing';

  @override
  String get adminMissingType => 'The court type is missing';

  @override
  String get adminSpaceFormHint =>
      'The name is built from the venue, the address, the sport, the type and the number.';

  @override
  String get adminCondition => 'Condition';

  @override
  String get adminConditionUpper => 'CONDITION';

  @override
  String get adminLighting => 'Lighting';

  @override
  String get adminLightingUpper => 'LIGHTING';

  @override
  String get adminCovered => 'Covered';

  @override
  String get adminOpenAir => 'Open air';

  @override
  String get adminLit => 'Lit';

  @override
  String get adminUnlit => 'Unlit';

  @override
  String get adminSelect => 'Select';

  @override
  String get adminSelectVenue => 'Select a venue';

  @override
  String get adminSelectSport => 'Select a sport';

  @override
  String get adminSelectType => 'Select the type';

  @override
  String get adminSport => 'Sport';

  @override
  String get adminType => 'Type';

  @override
  String get adminTypeUpper => 'TYPE';

  @override
  String get adminNewSpaceTitle => 'New space';

  @override
  String get adminNewSpaceHeading => 'New sports space';

  @override
  String get adminEditSpaceTitle => 'Edit space';

  @override
  String get adminEditSpaceHeading => 'Edit sports space';

  @override
  String get adminSaveSpace => 'SAVE SPACE';

  @override
  String get adminChangesSaved => 'The changes were saved';

  @override
  String get adminGeneratedName => 'AUTOMATICALLY GENERATED NAME';

  @override
  String get adminNameFailed => 'The name could not be computed';

  @override
  String get adminPricePerHour => 'Price per hour';

  @override
  String get adminPricePerHourUpper => 'PRICE PER HOUR';

  @override
  String get adminGoToList => 'GO TO THE LIST';

  @override
  String get adminSpaceCreatedTitle => 'Sports space created!';

  @override
  String get adminSpaceCreatedText => 'It is now available for users to book.';

  @override
  String get adminCreateAnother => 'Create another';

  @override
  String get adminVenueCreatedTitle => 'Venue created!';

  @override
  String get adminVenueCreatedText =>
      'The venue now shows in the list and you can start adding sports spaces to it.';

  @override
  String get adminCreateAnotherVenue => 'Create another venue';

  @override
  String get adminDeactivatingSpace => 'Deactivating the space';

  @override
  String get adminDeactivateSpaceButton => 'DEACTIVATE THE SPACE';

  @override
  String get adminTraceTitle => 'TRACEABILITY';

  @override
  String get adminTraceCreated => 'Booking created';

  @override
  String adminTraceBy(Object who, Object date) {
    return 'By $who · $date';
  }

  @override
  String adminTraceByReason(Object who, Object date, Object reason) {
    return 'By $who · $date · $reason';
  }

  @override
  String get adminTraceVoided => 'Voided by the administrator';

  @override
  String get adminTraceAnAdmin => 'an administrator';

  @override
  String get adminTraceCanceled => 'Canceled by the user';

  @override
  String get adminTraceNoticeSent => 'Notification sent to the user';

  @override
  String get adminTraceNoticeInbox => 'Notice in the inbox of the user';

  @override
  String get adminTracePushFailed => 'The push was not sent';

  @override
  String get adminVoidReasonSemantics => 'Reason for voiding';

  @override
  String get adminVoidReasonLabel => 'REASON FOR VOIDING';

  @override
  String get adminVoidReasonRequired => 'The reason is required to void';

  @override
  String get adminVoidDialogTitle => 'Void this booking?';

  @override
  String get adminVoidConfirm => 'CONFIRM VOIDING';

  @override
  String get adminBackUpper => 'BACK';

  @override
  String get adminNewVenueHeading => 'New venue';

  @override
  String get adminAddVenueTitle => 'Add venue';

  @override
  String get adminVenueFormHint => 'Name, address and hours are required.';

  @override
  String get adminVenueNameUpper => 'VENUE NAME';

  @override
  String get adminVenueName => 'Venue name';

  @override
  String get adminVenueNamePlaceholder => 'E.g. Haedo venue';

  @override
  String get adminAddressUpper => 'ADDRESS';

  @override
  String get adminAddress => 'Address';

  @override
  String get adminAddressPlaceholderNew => 'Street and number';

  @override
  String get adminAddressPlaceholderEdit => 'Write the address';

  @override
  String get adminOpeningUpper => 'OPENING TIME';

  @override
  String get adminOpening => 'Opening time';

  @override
  String get adminClosingUpper => 'CLOSING TIME';

  @override
  String get adminClosing => 'Closing time';

  @override
  String get adminOpenDaysUpper => 'OPEN DAYS';

  @override
  String get adminOpenDays => 'Open days';

  @override
  String get adminSaveVenue => 'SAVE VENUE';

  @override
  String get adminSaveChanges => 'SAVE CHANGES';

  @override
  String get adminDeactivatingVenue => 'Deactivating the venue';

  @override
  String get adminDeactivateVenueButton => 'DEACTIVATE THE VENUE';

  @override
  String get adminVenueNameRequired => 'The name is required';

  @override
  String get adminVenueAddressRequired => 'The address is required';

  @override
  String get adminVenueAddressStreet => 'Write the street and number';

  @override
  String get adminOpensAtRequired => 'The opening time is required';

  @override
  String get adminClosesAtRequired => 'The closing time is required';

  @override
  String get adminClosesBeforeOpens =>
      'The closing time must be after the opening time';

  @override
  String adminOutsideSubject(num count, Object venue) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count future bookings at $venue',
      one: '1 future booking at $venue',
    );
    return '$_temp0';
  }

  @override
  String adminOutsideStartsBefore(num count, Object hour) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'start',
      one: 'starts',
    );
    return '$_temp0 before $hour';
  }

  @override
  String adminOutsideEndsAfter(num count, Object hour) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'end',
      one: 'ends',
    );
    return '$_temp0 after $hour';
  }

  @override
  String adminOutsideClosedDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'fall',
      one: 'falls',
    );
    return '$_temp0 on a day the venue stops opening';
  }

  @override
  String adminOutsideNewSchedule(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'fall',
      one: 'falls',
    );
    return '$_temp0 outside the new schedule';
  }

  @override
  String adminOutsideKeeps(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'they stay at their original time',
      one: 'it stays at its original time',
    );
    return '$_temp0';
  }

  @override
  String adminOutsideNotice(Object subject, Object reason, Object keeps) {
    return '$subject $reason. If you save, $keeps: the change applies to new bookings.';
  }

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
