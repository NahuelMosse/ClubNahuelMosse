import 'package:firebase_auth/firebase_auth.dart';

import '../../../api/api_client.dart';
import '../domain/session_exceptions.dart';

/// Who checks the email and the password, and keeps the session on the device.
abstract interface class Credentials {
  bool get hasAccount;

  /// Lanza [InvalidCredentials], [NoConnection] o [ServerError].
  Future<void> signIn(String email, String password);

  Future<String?> token();

  Future<void> signOut();
}

class FirebaseCredentials implements Credentials {
  FirebaseCredentials(this._auth);

  final FirebaseAuth _auth;

  // Firebase does not tell a nonexistent email from a wrong password
  // (`invalid-credential`) when enumeration protection is on.
  static const _rejections = {
    'invalid-credential',
    'invalid-email',
    'user-not-found',
    'wrong-password',
    'user-disabled',
    'missing-password',
    'too-many-requests',
  };

  @override
  bool get hasAccount => _auth.currentUser != null;

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') throw const NoConnection();
      if (_rejections.contains(e.code)) throw const InvalidCredentials();
      throw const ServerError(0);
    }
  }

  // The account no longer applies: there is no token to refresh.
  static const _deadAccount = {
    'user-token-expired',
    'user-disabled',
    'user-not-found',
    'invalid-user-token',
  };

  @override
  Future<String?> token() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') throw const NoConnection();
      if (_deadAccount.contains(e.code)) throw const InvalidCredentials();
      throw const ServerError(0);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
