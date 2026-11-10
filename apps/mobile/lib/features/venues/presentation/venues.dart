import 'package:flutter/foundation.dart';

import '../data/venues_repository.dart';
import '../domain/venue.dart';

/// The venues of the club, seen from the screens. Notifies whoever listens each time one
/// changes.
class Venues extends ChangeNotifier {
  Venues({required this.repository});

  /// The read requests (`active`) are made directly on the repository.
  final VenuesRepository repository;

  /// Creates the venue and returns the one that was saved.
  Future<Venue> create({
    required String name,
    required String address,
    required String opening,
    required String closing,
    required List<int> days,
  }) async {
    final venue = await repository.create(
      name: name,
      address: address,
      opening: opening,
      closing: closing,
      days: days,
    );
    notifyListeners();
    return venue;
  }

  /// Saves the new data of the venue [id] and returns how it ended up.
  Future<Venue> update(
    String id, {
    required String name,
    required String address,
    required String opening,
    required String closing,
    required List<int> days,
    bool confirm = false,
  }) async {
    final venue = await repository.update(
      id,
      name: name,
      address: address,
      opening: opening,
      closing: closing,
      days: days,
      confirm: confirm,
    );
    notifyListeners();
    return venue;
  }

  /// Deactivates the venue [id] and its spaces.
  Future<void> deactivate(String id) async {
    await repository.deactivate(id);
    notifyListeners();
  }

  /// Reports that what was seen of the venues no longer applies (for example, one that
  /// was deactivated): whoever shows them requests them again.
  void notifyChange() => notifyListeners();
}
