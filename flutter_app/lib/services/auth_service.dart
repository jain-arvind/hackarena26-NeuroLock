import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  bool isEduEmail(String email) {
    return email.trim().toLowerCase().endsWith('.edu');
  }

  Future<User?> signInWithEduEmail({
    required String email,
    required String password,
  }) async {
    if (!isEduEmail(email)) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message: 'Only .edu email addresses are allowed.',
      );
    }

    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
