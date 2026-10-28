import 'package:firebase_auth/firebase_auth.dart';

import '../../../api/api_client.dart';
import '../domain/session_exceptions.dart';

/// Quién comprueba el correo y la contraseña, y guarda la sesión en el dispositivo.
abstract interface class Credentials {
  bool get hasAccount;

  /// Lanza [InvalidCredentials], [SinConexion] o [ErrorDelServidor].
  Future<void> signIn(String email, String password);

  Future<String?> token();

  Future<void> signOut();
}

class FirebaseCredentials implements Credentials {
  FirebaseCredentials(this._auth);

  final FirebaseAuth _auth;

  // Firebase no distingue correo inexistente de contraseña incorrecta
  // (`invalid-credential`) cuando la protección contra enumeración está activa.
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
      if (e.code == 'network-request-failed') throw const SinConexion();
      if (_rejections.contains(e.code)) throw const InvalidCredentials();
      throw const ErrorDelServidor(0);
    }
  }

  // La cuenta ya no vale: no hay token que refrescar.
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
      if (e.code == 'network-request-failed') throw const SinConexion();
      if (_deadAccount.contains(e.code)) throw const InvalidCredentials();
      throw const ErrorDelServidor(0);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
