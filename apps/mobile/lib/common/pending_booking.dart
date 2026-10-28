// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
/// The booking that was about to be confirmed when the session expired: on signing back in
/// with the same account, the app leads again to the confirmation. It lives while the app is
/// open.
class PendingBooking<T extends Object> {
  T? _choice;
  String? _email;

  void save(T choice, String email) {
    _choice = choice;
    _email = email.trim().toLowerCase();
  }

  /// Whether there is a pending one for the account [email]; if it belongs to another, it is
  /// discarded.
  bool isFor(String email) {
    if (_choice == null) return false;
    if (_email == email.trim().toLowerCase()) return true;
    _choice = null;
    _email = null;
    return false;
  }

  /// The pending choice, which stops being pending.
  T? take() {
    final choice = _choice;
    _choice = null;
    _email = null;
    return choice;
  }
}
