import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 📧 Email Sign In
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      await _logAuthFailure(email, e.code, e.message ?? "No message", "Email-Login");
      rethrow; 
    }
  }

  // 📝 Email Register
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      await _logAuthFailure(email, e.code, e.message ?? "No message", "Email-Register");
      rethrow;
    }
  }

  // 🔑 PASSWORD RESET WITH TRACKING
  Future<void> resetPassword(String email) async {
    try {
      // Firebase හරහා reset email එක යවනවා
      await _auth.sendPasswordResetEmail(email: email);

      // 🚀 Tracking: Reset එක ඉල්ලපු කෙනාව ලොග් කරනවා
      await _firestore.collection('password_reset_logs').add({
        'email': email,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? "Web" : "Mobile",
        'status': 'Requested',
      });
    } on FirebaseAuthException catch (e) {
      await _logAuthFailure(email, "reset-failed", e.code, "Password-Reset");
      rethrow;
    }
  }

  // 🚀 Google Sign-In (Web & Mobile)
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        await _logAuthFailure("N/A", "user-cancelled", "Popup closed", "Google-Login");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      await _logAuthFailure("Google User", "exception", e.toString(), "Google-Login");
      return null;
    }
  }

  // 🚪 Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 🛡️ ERROR LOGGING (The Failure Table)
  Future<void> _logAuthFailure(String email, String code, String message, String method) async {
    try {
      await _firestore.collection('auth_failures').add({
        'email': email,
        'errorCode': code,
        'errorMessage': message,
        'method': method,
        'platform': kIsWeb ? "Web" : "Mobile",
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Logging Failed: $e");
    }
  }
}