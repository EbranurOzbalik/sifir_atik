import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth? _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleInitializeFuture;

  bool get isFirebaseReady => Firebase.apps.isNotEmpty;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges {
    if (!isFirebaseReady) return Stream<User?>.value(null);

    return _auth.authStateChanges();
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _checkFirebase();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageForCode(error.code));
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    _checkFirebase();

    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageForCode(error.code));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _checkFirebase();

    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageForCode(error.code));
    }
  }

  Future<void> signInWithGoogle() async {
    _checkFirebase();

    try {
      _googleInitializeFuture ??= _googleSignIn.initialize(
        clientId: _googleClientId,
        serverClientId:
            '785812597526-uutfsod3rgqsnnv0i25s4one5hfc4n6f.apps.googleusercontent.com',
      );
      await _googleInitializeFuture;

      final googleUser = await _googleSignIn.authenticate();
      final googleAuthentication = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuthentication.idToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageForCode(error.code));
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthServiceException('Google girişi iptal edildi.');
      }

      throw const AuthServiceException(
        'Google ile giriş sırasında bir sorun oluştu.',
      );
    }
  }

  String? get _googleClientId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return '785812597526-isorej3bv13sr8dt8h5r4dcogr13m2af.apps.googleusercontent.com';
    }

    return null;
  }

  void _checkFirebase() {
    if (!isFirebaseReady) {
      throw const AuthServiceException('Firebase bağlantısı hazır değil.');
    }
  }

  String _messageForCode(String code) {
    return switch (code) {
      'invalid-email' => 'E-posta adresi geçerli değil.',
      'user-disabled' => 'Bu kullanıcı hesabı devre dışı bırakılmış.',
      'user-not-found' => 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.',
      'wrong-password' || 'invalid-credential' => 'E-posta veya şifre hatalı.',
      'email-already-in-use' => 'Bu e-posta ile daha önce hesap oluşturulmuş.',
      'weak-password' => 'Şifre daha güçlü olmalıdır.',
      'operation-not-allowed' =>
        'Bu giriş yöntemi Firebase üzerinde aktif değil.',
      'network-request-failed' => 'İnternet bağlantısını kontrol edin.',
      _ => 'Giriş sırasında bir sorun oluştu.',
    };
  }
}

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;
}
