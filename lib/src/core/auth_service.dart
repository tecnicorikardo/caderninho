import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  static const _rememberEmailKey = 'remember_email';
  static const _savedEmailKey = 'saved_email';

  Stream<User?> authChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signOut() => _auth.signOut();

  Future<void> saveRememberEmail({required bool enabled, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberEmailKey, enabled);
    if (enabled) {
      await prefs.setString(_savedEmailKey, email);
    } else {
      await prefs.remove(_savedEmailKey);
    }
  }

  Future<(bool remember, String email)> loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_rememberEmailKey) ?? true;
    final email = prefs.getString(_savedEmailKey) ?? '';
    return (remember, email);
  }

  Future<String?> signIn({
    required String email,
    required String password,
    required bool rememberEmail,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await saveRememberEmail(enabled: rememberEmail, email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    }
  }

  Future<String?> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    }
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email invalido.';
      case 'user-disabled':
        return 'Usuario desativado.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este email ja esta em uso.';
      case 'weak-password':
        return 'Senha muito fraca (minimo 6 caracteres).';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente em alguns minutos.';
      default:
        return e.message ?? 'Falha de autenticacao.';
    }
  }
}
