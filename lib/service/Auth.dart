import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Sign in failed';

      switch (e.code) {
        case 'invalid-credential':
          errorMessage = 'email or password is incorrect';
          break;
        case 'user-not-found':
          errorMessage = 'email not found';
          break;
        case 'wrong-password':
          errorMessage = 'password is incorrect';
          break;
        case 'user-disabled':
          errorMessage = 'account is disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'too many requests, please try again later';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message ?? e.toString()}';
      }
      throw Exception(errorMessage);
    }
  }

  // Sign up
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Sign up failed';

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Email is already in use';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message ?? e.toString()}';
      }
      throw Exception(errorMessage);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
