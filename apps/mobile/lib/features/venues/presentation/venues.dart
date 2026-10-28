import 'package:flutter/foundation.dart';

import '../data/venues_repository.dart';
import '../domain/venue.dart';

/// Las sedes del club, vistas desde las pantallas. Avisa a quien escucha cada vez que una
/// cambia.
class Venues extends ChangeNotifier {
  Venues({required this.repository});

  /// Los pedidos de lectura (`active`) se hacen directo sobre el repositorio.
  final VenuesRepository repository;

  /// Da de alta la sede y devuelve la que quedó guardada.
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

  /// Guarda los datos nuevos de la sede [id] y devuelve cómo quedó.
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

  /// Da de baja la sede [id] y sus espacios.
  Future<void> deactivate(String id) async {
    await repository.deactivate(id);
    notifyListeners();
  }

  /// Avisa que lo que se vio de las sedes ya no vale (por ejemplo, una que se dio de baja):
  /// quien las muestra las vuelve a pedir.
  void notifyChange() => notifyListeners();
}
