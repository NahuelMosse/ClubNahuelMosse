// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/price_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/domain/space_exceptions.dart';
import '../../spaces/presentation/spaces.dart';
import '../../venues/domain/venue.dart';
import '../../venues/presentation/venues.dart';
import '../data/api_failures.dart';
import '../domain/name_missing.dart';
import '../domain/new_space_field.dart';
import '../domain/space_price.dart';
import 'space_form_fields.dart';

/// What is still pending to report after a request: the session expired, or the network failed.
typedef CreationFailure = ({bool expired, Object? failure});

/// What was chosen and typed when creating a space, with the composed name that the API
/// computes and the requests that load and save it. Notifies every change.
class NewSpaceForm extends ChangeNotifier {
  NewSpaceForm({required this.spaces, required this.venues}) {
    var previous = price.text;
    price.addListener(() {
      if (price.text == previous) return;
      previous = price.text;
      serverErrors.remove(NewSpaceField.price);
      notifyListeners();
    });
  }

  final Spaces spaces;
  final Venues venues;

  List<Venue>? venueOptions;
  Catalog? catalog;
  bool loading = true;

  Venue? venue;
  Sport? sport;
  SpaceKind? type;
  bool? roofed;
  bool? lit;
  final price = TextEditingController();

  /// The composed name and the number that the API computed for the chosen venue, sport and
  /// type.
  (String, int)? suggested;
  bool computing = false;
  int _nameRequest = 0;

  /// Why the name could not be computed, to offer a retry.
  Object? nameFailure;

  final serverErrors = <NewSpaceField, String>{};
  String? notice;
  bool attemptedSave = false;
  bool submitting = false;
  final noticeKey = GlobalKey();
  bool _closed = false;

  @override
  void notifyListeners() {
    if (!_closed) super.notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    price.dispose();
    super.dispose();
  }

  bool _isCurrent(int request) => !_closed && request == _nameRequest;

  bool get canComputeName => venue != null && sport != null && type != null;

  /// Loads the catalog and the venues; returns why it failed, or `null` if it went well.
  Future<CreationFailure?> load() async {
    loading = true;
    notifyListeners();
    Object? failure;
    var expired = false;
    try {
      final loadedCatalog = await spaces.repository.catalog();
      final loadedVenues = await venues.repository.active();
      if (_closed) return null;
      catalog = loadedCatalog;
      venueOptions = loadedVenues;
      loading = false;
      notifyListeners();
      return null;
    } on SessionExpired {
      expired = true;
    } on FalloDeRed catch (e) {
      failure = e;
    }
    if (_closed) return null;
    loading = false;
    notifyListeners();
    return (expired: expired, failure: failure);
  }

  /// Asks the API for the name of the next space; if the choice changed meanwhile, the old
  /// response is discarded. Returns whether the expired session must be reported.
  Future<bool> computeName() async {
    final chosenVenue = venue;
    final chosenSport = sport;
    final chosenType = type;
    final request = ++_nameRequest;
    suggested = null;
    nameFailure = null;
    computing = canComputeName;
    notifyListeners();
    if (chosenVenue == null || chosenSport == null || chosenType == null) {
      return false;
    }
    var expired = false;
    try {
      final name = await spaces.suggestedName(
        venueId: chosenVenue.id,
        sport: chosenSport.key,
        kind: chosenType.key,
      );
      if (_isCurrent(request)) {
        suggested = name;
        notifyListeners();
      }
    } on SpaceRejected catch (e) {
      if (_isCurrent(request)) showErrors(e.errors);
    } on SessionExpired {
      expired = true;
    } on SinConexion catch (e) {
      _failName(request, e);
    } on ErrorDelServidor catch (e) {
      _failName(request, e);
    } finally {
      if (_isCurrent(request)) {
        computing = false;
        notifyListeners();
      }
    }
    return expired && _isCurrent(request);
  }

  void _failName(int request, Object error) {
    if (!_isCurrent(request)) return;
    nameFailure = error;
    notifyListeners();
  }

  void showErrors(Map<String, String> errors) {
    for (final MapEntry(:key, :value) in errors.entries) {
      final field = NewSpaceField.values
          .where((c) => c.apiKey == key)
          .firstOrNull;
      if (field != null) serverErrors[field] = value;
    }
    notifyListeners();
  }

  bool _isMissing(NewSpaceField field) => switch (field) {
    NewSpaceField.venue => venue == null,
    NewSpaceField.sport => sport == null,
    NewSpaceField.type => type == null,
    NewSpaceField.roofing => roofed == null,
    NewSpaceField.lighting => lit == null,
    NewSpaceField.price => !validPricePerHour(readPrice(price.text)),
  };

  String? _ruleError(NewSpaceField field, AppLocalizations l10n) {
    if (!_isMissing(field)) return null;
    return field == NewSpaceField.price
        ? priceError(l10n, price.text)
        : l10n.adminRequiredField;
  }

  String? error(NewSpaceField field, AppLocalizations l10n) =>
      serverErrors[field] ?? (attemptedSave ? _ruleError(field, l10n) : null);

  bool get isComplete =>
      !NewSpaceField.values.any(_isMissing) &&
      serverErrors.isEmpty &&
      suggested != null;

  NameMissing get missingForName {
    if (venue == null && sport == null && type == null) {
      return NameMissing.venueSportAndType;
    }
    if (venue == null) return NameMissing.venue;
    if (sport == null) return NameMissing.sport;
    return NameMissing.type;
  }

  Future<bool> pickVenue(Venue chosen) {
    venue = chosen;
    serverErrors.remove(NewSpaceField.venue);
    notifyListeners();
    return computeName();
  }

  Future<bool> pickSport(Sport chosen) {
    sport = chosen;
    // The types depend on the sport: the one chosen before no longer applies.
    type = null;
    serverErrors
      ..remove(NewSpaceField.sport)
      ..remove(NewSpaceField.type);
    notifyListeners();
    return computeName();
  }

  Future<bool> pickType(SpaceKind chosen) {
    type = chosen;
    serverErrors.remove(NewSpaceField.type);
    notifyListeners();
    return computeName();
  }

  void pickYesNo(NewSpaceField field, {required bool value}) {
    if (field == NewSpaceField.roofing) {
      roofed = value;
    } else {
      lit = value;
    }
    serverErrors.remove(field);
    notifyListeners();
  }

  void markSaveAttempt() {
    attemptedSave = true;
    notifyListeners();
  }

  void closeNotice() {
    notice = null;
    notifyListeners();
  }

  /// Creates the space with what is shown now, which must be [isComplete]. If it is
  /// created, calls [onCreated] and returns `null`; otherwise returns what is left to report.
  Future<CreationFailure?> submit({
    required void Function(Space) onCreated,
  }) async {
    submitting = true;
    notice = null;
    notifyListeners();
    Object? failure;
    var expired = false;
    try {
      onCreated(
        await spaces.create(
          venueId: venue!.id,
          sport: sport!.key,
          kind: type!.key,
          covered: roofed!,
          lit: lit!,
          pricePerHour: readPrice(price.text)!,
          number: suggested!.$2,
        ),
      );
      return null;
    } on NameTaken catch (e) {
      if (!_closed) _reportNameTaken(e);
    } on SpaceRejected catch (e) {
      if (!_closed) showErrors(e.errors);
    } on SessionExpired {
      expired = true;
    } on FalloDeRed catch (e) {
      failure = e;
    } finally {
      if (!_closed) {
        submitting = false;
        notifyListeners();
      }
    }
    if (_closed) return null;
    return (expired: expired, failure: failure);
  }

  void _reportNameTaken(NameTaken e) {
    notice = e.message;
    suggested = (e.name, e.number);
    notifyListeners();
    // The notice is above the form: bring it into view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final noticeContext = noticeKey.currentContext;
      if (noticeContext != null && noticeContext.mounted) {
        Scrollable.ensureVisible(noticeContext);
      }
    });
  }
}
