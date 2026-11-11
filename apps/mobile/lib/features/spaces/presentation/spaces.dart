import 'package:flutter/foundation.dart';

import '../data/spaces_repository.dart';
import '../domain/space.dart';

/// The sports spaces, seen from the screens. Notifies whoever listens each time one
/// changes.
class Spaces extends ChangeNotifier {
  Spaces({required this.repository});

  /// The reads (`catalog`, `active`) are requested directly from the repository.
  final SpacesRepository repository;

  /// The name and the number the next space of that type at that venue would have.
  Future<(String, int)> suggestedName({
    required String venueId,
    required String sport,
    required String kind,
  }) => repository.suggestedName(venueId: venueId, sport: sport, kind: kind);

  /// Creates the space with the [number] the administrator saw.
  Future<Space> create({
    required String venueId,
    required String sport,
    required String kind,
    required bool covered,
    required bool lit,
    required int pricePerHour,
    required int number,
  }) async {
    final space = await repository.create(
      venueId: venueId,
      sport: sport,
      kind: kind,
      covered: covered,
      lit: lit,
      pricePerHour: pricePerHour,
      number: number,
    );
    notifyListeners();
    return space;
  }

  /// Saves what changed of the condition, the lighting and the price of the space [id].
  Future<Space> update(
    String id, {
    bool? covered,
    bool? lit,
    int? pricePerHour,
  }) async {
    final space = await repository.update(
      id,
      covered: covered,
      lit: lit,
      pricePerHour: pricePerHour,
    );
    notifyListeners();
    return space;
  }

  /// Deactivates the space [id].
  Future<void> deactivate(String id) async {
    await repository.deactivate(id);
    notifyListeners();
  }

  /// Reports that what was seen of the spaces no longer applies (for example, one that
  /// was deactivated): whoever shows them requests them again.
  void notifyChange() => notifyListeners();
}
