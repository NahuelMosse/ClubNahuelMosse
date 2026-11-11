import 'package:flutter/foundation.dart';

import '../../../common/network_failure.dart';
import '../data/session_repository.dart';
import '../domain/profile.dart';
import '../domain/session_exceptions.dart';
import '../domain/token_source.dart';

/// The app's session: signs in, resumes the one that was stored and closes it.
class Session extends ChangeNotifier implements TokenSource {
  Session({required SessionRepository repository}) : _repository = repository;

  final SessionRepository _repository;

  /// What must be started with the session still open when closing it, like telling the
  /// API that this phone stops receiving notices: it receives the token of the session
  /// being closed. If something fails, the session closes anyway.
  final onClose = <Future<void> Function(String)>[];

  /// What must be done every time the phone leaves a session, whatever the path: closing
  /// it, an account that no longer applies or a deletion. If something fails, it goes on
  /// anyway.
  final onExit = <Future<void> Function()>[];

  Profile? _profile;

  Profile? get profile => _profile;

  set _current(Profile? profile) {
    _profile = profile;
    notifyListeners();
  }

  /// Throws [InvalidCredentials], [NoConnection] or [ServerError]. If it fails after
  /// Firebase accepted the password, it does not leave a half-open session.
  Future<Profile> signIn(String email, String password) async {
    await _repository.credentials.signIn(email.trim().toLowerCase(), password);
    try {
      final profile = await _repository.fetchProfile();
      _current = profile;
      return profile;
    } on Object {
      await _leave();
      rethrow;
    }
  }

  /// The session left open on the device, if it still applies.
  ///
  /// It only closes it if the account is no longer valid. Without network or with the API
  /// down it keeps the session and throws [NoConnection] or [ServerError] so the startup
  /// offers to retry.
  Future<Profile?> resume() async {
    if (!_repository.hasAccount) return null;
    try {
      final profile = await _repository.fetchProfile();
      _current = profile;
      return profile;
    } on InvalidCredentials {
      await _leave();
      return null;
    }
  }

  /// Asks the API for the profile again: the data is not stored on the device.
  ///
  /// Throws [SessionExpired], [NoConnection] or [ServerError].
  Future<Profile> refresh() async {
    final before = _profile;
    final Profile profile;
    try {
      profile = await _repository.fetchProfile();
    } on InvalidCredentials {
      throw const SessionExpired();
    }
    _ifStillSame(before, profile);
    return profile;
  }

  /// Stores [profile] only if the session is the same as when the request went out: if in
  /// the meantime it closed or another account signed in, the response no longer belongs
  /// to it.
  void _ifStillSame(Profile? before, Profile profile) {
    if (!identical(_profile, before)) throw const SessionExpired();
    _current = profile;
  }

  /// Saves the personal data and returns the profile that stayed in the API.
  ///
  /// Throws [DataRejected], [SessionExpired], [NoConnection] or [ServerError].
  Future<Profile> updateProfile({
    required String firstName,
    required String lastName,
    required String dni,
    required String birthDate,
  }) async {
    final token = await this.token();
    final before = _profile;
    final profile = await _repository.updateProfile(
      token,
      firstName: firstName,
      lastName: lastName,
      dni: dni,
      birthDate: birthDate,
    );
    _ifStillSame(before, profile);
    return profile;
  }

  /// Lanza [PasswordRejected], [SessionExpired], [NoConnection] o [ServerError].
  Future<void> changePassword(String current, String newPassword) async {
    final profile = _profile;
    final token = await this.token();
    if (profile == null) throw const SessionExpired();
    await _repository.changePassword(
      token,
      profile.email,
      current,
      newPassword,
    );
  }

  /// Deletes the account and closes the session of the device.
  ///
  /// Throws [SessionExpired], [NoConnection] or [ServerError]; in those cases the account
  /// stays as it was.
  Future<void> deactivate() async {
    final token = await this.token();
    final before = _profile;
    await _repository.deactivate(token);
    // If in the meantime the session closed or another account signed in, it is not
    // touched.
    if (!identical(_profile, before)) return;
    try {
      await _leave();
    } on Exception {
      // The account no longer exists in the API: the next startup finds the Firebase
      // session that was left expired and closes it.
    }
    _current = null;
  }

  /// The ID token of whoever has the session, for the requests of other screens.
  ///
  /// Throws [SessionExpired], [NoConnection] or [ServerError].
  @override
  Future<String> token() => _repository.token();

  /// If Firebase cannot delete the session from the device, it throws and the session
  /// stays open.
  Future<void> close() async {
    final deactivations = <Future<void>>[];
    if (onClose.isNotEmpty) {
      String? token;
      try {
        token = await _repository.currentToken().timeout(
          const Duration(seconds: 2),
        );
      } on Exception {
        // Without a token there is nothing to tell the API: the session closes anyway.
      }
      if (token != null) {
        // The error is hooked up when each request is created: if it fails before the
        // session finishes closing, no uncaught error is left.
        for (final f in onClose) {
          deactivations.add(
            f(token)
                .timeout(const Duration(seconds: 3))
                .then((_) {}, onError: (Object _) {}),
          );
        }
      }
    }
    await _repository.credentials.signOut();
    _current = null;
    // The screen already shows the login: what remains is done without making the person
    // wait.
    await _notifyExit();
    await Future.wait(deactivations);
  }

  /// Deletes the Firebase session from the device and tells whoever needs it that the
  /// phone is no longer of that account. What fails after leaving does not change that it
  /// was left.
  Future<void> _leave() async {
    await _repository.credentials.signOut();
    await _notifyExit();
  }

  Future<void> _notifyExit() async {
    for (final f in [...onExit]) {
      try {
        await f().timeout(const Duration(seconds: 3));
      } on Exception {
        // Without network or with the service down, the person left anyway.
      }
    }
  }
}
