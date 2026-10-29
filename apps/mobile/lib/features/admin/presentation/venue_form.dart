// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/dates.dart';
import '../../../common/missing_fields.dart';
import '../../../l10n/app_localizations.dart';
import '../../venues/domain/venue.dart';
import '../../venues/domain/venue_exceptions.dart';
import '../../venues/presentation/venues.dart';
import '../data/api_failures.dart';
import '../domain/venue_field.dart';
import '../domain/venue_problem.dart';
import '../domain/venue_rules.dart';
import 'venue_problem_text.dart';

/// What is left to handle after a submit that did not save the venue.
typedef PendingVenue = ({
  int? outside,
  bool gone,
  bool expired,
  Object? failure,
});

/// What was typed and picked in a venue form, with its errors and the submit.
/// Without [editing] it creates a new venue; with [editing], it fixes that one. Notifies
/// every change.
class VenueForm extends ChangeNotifier {
  VenueForm({required this.venues, this.editing})
    : name = TextEditingController(text: editing?.name),
      address = TextEditingController(text: editing?.address),
      opensAt = editing == null ? null : parseWholeHour(editing.opening),
      closesAt = editing == null ? null : parseWholeHour(editing.closing),
      openDays = editing?.days ?? OpenDays.mondayToSunday.days {
    for (final (focus, field) in [
      (nameFocus, VenueField.name),
      (addressFocus, VenueField.address),
    ]) {
      focus.addListener(() {
        // Leaving an empty field marks nothing: the save attempt does that.
        if (!focus.hasFocus && _controller(field).text.trim().isNotEmpty) {
          touched.add(field);
          notifyListeners();
        }
      });
    }
    for (final (controller, field) in [
      (name, VenueField.name),
      (address, VenueField.address),
    ]) {
      var previous = controller.text;
      controller.addListener(() {
        // The controller also notifies when the cursor moves: only the text counts.
        if (controller.text == previous) return;
        previous = controller.text;
        serverErrors.remove(field);
        // When editing the data comes loaded: the error shows as soon as one types.
        if (isEditing) touched.add(field);
        notifyListeners();
      });
    }
  }

  final Venues venues;
  final Venue? editing;
  final TextEditingController name;
  final TextEditingController address;
  final nameFocus = FocusNode();
  final addressFocus = FocusNode();
  int? opensAt;
  int? closesAt;
  List<int> openDays;
  final touched = <VenueField>{};
  final serverErrors = <VenueField, String>{};
  bool attemptedSave = false;
  bool submitting = false;
  bool _deactivating = false;

  /// A previous submit was cut off: the API may have saved the venue without the
  /// response arriving.
  bool hadCutoff = false;
  bool _closed = false;

  bool get isEditing => editing != null;

  bool get deactivating => _deactivating;

  set deactivating(bool value) {
    _deactivating = value;
    notifyListeners();
  }

  /// Saving or deactivating: the form is not touched and cannot be left.
  bool get busy => submitting || _deactivating;

  @override
  void notifyListeners() {
    if (!_closed) super.notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    name.dispose();
    address.dispose();
    nameFocus.dispose();
    addressFocus.dispose();
    super.dispose();
  }

  TextEditingController _controller(VenueField field) =>
      field == VenueField.name ? name : address;

  VenueProblem? _problem(VenueField field) => switch (field) {
    VenueField.name => venueNameProblem(name.text),
    VenueField.address => venueAddressProblem(address.text),
    VenueField.opensAt => opensAtProblem(opensAt),
    VenueField.closesAt => closesAtProblem(
      closesAt: closesAt,
      opensAt: opensAt,
    ),
    VenueField.openDays => null,
  };

  String? _ruleError(VenueField field, AppLocalizations l10n) {
    final problem = _problem(field);
    return problem == null ? null : venueProblemText(l10n, problem);
  }

  String? error(VenueField field, AppLocalizations l10n) => errorToShow(
    serverError: serverErrors[field],
    ruleError: _ruleError(field, l10n),
    attempted: attemptedSave,
    touched: touched.contains(field),
  );

  bool get isComplete =>
      VenueField.values.every((f) => _problem(f) == null) &&
      serverErrors.isEmpty;

  /// The fields that can be focused or not, with their error, in the order they show.
  List<(FocusNode?, String?)> missing(AppLocalizations l10n) => [
    (nameFocus, _ruleError(VenueField.name, l10n)),
    (addressFocus, _ruleError(VenueField.address, l10n)),
    (null, _ruleError(VenueField.opensAt, l10n)),
    (null, _ruleError(VenueField.closesAt, l10n)),
  ];

  void markSaveAttempt() {
    attemptedSave = true;
    notifyListeners();
  }

  /// Stores the [hour] picked for the opening or closing; `null` if it was closed
  /// without picking.
  void pickHour(VenueField field, int? hour) {
    if (hour != null) {
      touched.add(field);
      if (field == VenueField.closesAt) {
        closesAt = hour;
      } else {
        opensAt = hour;
      }
      serverErrors
        ..remove(VenueField.opensAt)
        ..remove(VenueField.closesAt);
    }
    notifyListeners();
  }

  void pickDays(OpenDays picked) {
    openDays = picked.days;
    serverErrors.remove(VenueField.openDays);
    notifyListeners();
  }

  void _showErrors(Map<String, String> errors) {
    for (final MapEntry(:key, :value) in errors.entries) {
      final field = VenueField.values.where((f) => f.apiKey == key).firstOrNull;
      if (field != null) serverErrors[field] = value;
    }
    notifyListeners();
  }

  Future<Venue> _request(int opensAt, int closesAt, {required bool confirm}) {
    final typedName = name.text.trim();
    final typedAddress = address.text.trim();
    final venue = editing;
    return venue == null
        ? venues.create(
            name: typedName,
            address: typedAddress,
            opening: wholeHour(opensAt),
            closing: wholeHour(closesAt),
            days: openDays,
          )
        : venues.update(
            venue.id,
            name: typedName,
            address: typedAddress,
            opening: wholeHour(opensAt),
            closing: wholeHour(closesAt),
            days: openDays,
            confirm: confirm,
          );
  }

  /// Saves the venue as it looks now, which must be [isComplete]. If it is saved, calls
  /// [onSaved] and returns `null`; otherwise returns what is left to handle.
  Future<PendingVenue?> submit(
    int opensAt,
    int closesAt, {
    required bool confirm,
    required void Function(Venue) onSaved,
  }) async {
    submitting = true;
    notifyListeners();
    Object? failure;
    var expired = false;
    int? outside;
    var gone = false;
    try {
      onSaved(await _request(opensAt, closesAt, confirm: confirm));
      return null;
    } on BookingsOutsideHours catch (e) {
      outside = e.count;
    } on VenueUnavailable {
      gone = true;
    } on VenueRejected catch (e) {
      final saved = !isEditing && e.duplicate && hadCutoff
          ? await _savedVenue(opensAt, closesAt)
          : null;
      if (saved != null) {
        onSaved(saved);
        return null;
      }
      if (!_closed) _showErrors(e.errors);
    } on SessionExpired {
      expired = true;
    } on SinConexion catch (e) {
      hadCutoff = true;
      failure = e;
    } on ErrorDelServidor catch (e) {
      failure = e;
    } finally {
      if (!_closed) {
        submitting = false;
        notifyListeners();
      }
    }
    if (_closed) return null;
    return (outside: outside, gone: gone, expired: expired, failure: failure);
  }

  /// The venue the cut-off submit saved, if it is this very one: so the retry does not
  /// mistake it for another that already had the name.
  Future<Venue?> _savedVenue(int opensAt, int closesAt) async {
    String normal(String text) =>
        text.trim().split(RegExp(r'\s+')).join(' ').toLowerCase();
    try {
      final active = await venues.repository.active();
      return active
          .where(
            (s) =>
                normal(s.name) == normal(name.text) &&
                normal(s.address) == normal(address.text) &&
                s.opening == wholeHour(opensAt) &&
                s.closing == wholeHour(closesAt) &&
                weekdaysLabel(s.days) == weekdaysLabel(openDays),
          )
          .firstOrNull;
    } on Exception {
      return null;
    }
  }
}
