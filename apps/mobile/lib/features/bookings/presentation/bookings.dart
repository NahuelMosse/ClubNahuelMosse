import 'package:flutter/foundation.dart';

import '../data/bookings_api.dart';
import '../domain/booking.dart';
import '../domain/booking_choice.dart';

/// The bookings of the signed-in person, read through [BookingsApi]. Notifies listeners
/// every time one is booked, canceled or modified.
class Bookings extends ChangeNotifier {
  Bookings(this._api);

  final BookingsApi _api;

  /// All the upcoming ones (nearest first) or the whole history (most recent first).
  Future<List<Booking>> mine({required bool history}) =>
      _api.mine(history: history);

  /// Books what was chosen on the availability screen.
  Future<Booking> book(BookingChoice choice) async {
    final booking = await _api.book(choice);
    notifyListeners();
    return booking;
  }

  /// Cancels [booking]; the slot becomes free again.
  Future<Booking> cancel(Booking booking) async {
    final canceled = await _api.cancel(booking);
    notifyListeners();
    return canceled;
  }

  /// Moves [booking] to the space, day and hour of [next], with the same duration.
  Future<Booking> modify(Booking booking, BookingChoice next) async {
    final modified = await _api.modify(booking, next);
    notifyListeners();
    return modified;
  }
}
