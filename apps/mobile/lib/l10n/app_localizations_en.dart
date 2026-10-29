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
  String adminVenueSchedule(Object closing, Object days, Object opening) {
    return '$days from $opening to $closing';
  }

  @override
  String adminVenueScheduleShort(Object closing, Object days, Object opening) {
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
    Object date,
    Object schedule,
    Object sport,
    Object user,
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
  String adminDeactivateVenueText(Object address, Object name) {
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
  String get loginSignIn => 'SIGN IN';

  @override
  String get loginEmailRequired => 'Enter your email address';

  @override
  String get loginPasswordRequired => 'Enter your password';

  @override
  String get loginInvalidCredentials =>
      'Could not sign in. Check your details and try again.';
}
