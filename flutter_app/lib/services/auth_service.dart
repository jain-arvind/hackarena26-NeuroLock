import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

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

  Future<User?> signInWithGoogleEdu() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);
    final User? user = userCredential.user;
    final String? email = user?.email;

    if (email == null || !isEduEmail(email)) {
      await signOut();
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message: 'Google account must use a .edu email.',
      );
    }

    return user;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
