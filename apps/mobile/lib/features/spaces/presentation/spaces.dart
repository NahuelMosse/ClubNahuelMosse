import 'package:flutter/foundation.dart';

import '../data/spaces_repository.dart';
import '../domain/space.dart';

/// Los espacios deportivos, vistos desde las pantallas. Avisa a quien escucha cada vez que
/// uno cambia.
class Spaces extends ChangeNotifier {
  Spaces({required this.repository});

  /// Las lecturas (`catalog`, `active`) se piden directo al repositorio.
  final SpacesRepository repository;

  /// El nombre y el número que tendría el próximo espacio de ese tipo en esa sede.
  Future<(String, int)> suggestedName({
    required String venueId,
    required String sport,
    required String kind,
  }) => repository.suggestedName(venueId: venueId, sport: sport, kind: kind);

  /// Da de alta el espacio con el [number] que vio el administrador.
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

  /// Guarda lo que cambió de la condición, la iluminación y el precio del espacio [id].
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

  /// Da de baja el espacio [id].
  Future<void> deactivate(String id) async {
    await repository.deactivate(id);
    notifyListeners();
  }

  /// Avisa que lo que se vio de los espacios ya no vale (por ejemplo, uno que se dio de
  /// baja): quien los muestra los vuelve a pedir.
  void notifyChange() => notifyListeners();
}
