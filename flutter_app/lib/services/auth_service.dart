import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Future<User?> signInAnonymously() async {
    final UserCredential credential = await _auth.signInAnonymously();
    return credential.user;
  }
}
