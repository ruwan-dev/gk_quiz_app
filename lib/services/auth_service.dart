import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // Browser තොරතුරු ලබා ගැනීමට

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // 🚀 Hosted Domain එකේදී මේ Client ID එක අනිවාර්යයි
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? "128784053347-fhld2nolbkkdea1ufa4v580t38ovl1il.apps.googleusercontent.com" : null,
  );
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 📧 Existing Email Methods
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      await _logAuthFailure(email, e.code, e.message ?? "No message", "Email-Login");
      rethrow; 
    }
  }

  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      await _logAuthFailure(email, e.code, e.message ?? "No message", "Email-Register");
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
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

  // 🚀 Updated Google Sign-In with Detailed Debugging
  Future<User?> signInWithGoogle() async {
    try {
      debugPrint("AuthService: Starting Google Sign-In...");
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        await _logDebugAuthError(
          method: "Google-Login",
          errorCode: "user-cancelled",
          errorMessage: "Popup was closed by the user or blocked.",
        );
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
      
    } catch (e, stackTrace) {
      // 🚨 ඕනෑම Error එකක් මෙතනදී Firestore එකට ලොග් වෙනවා
      await _logDebugAuthError(
        method: "Google-Login-Exception",
        errorCode: e is FirebaseAuthException ? e.code : "unknown-exception",
        errorMessage: e.toString(),
        stackTrace: stackTrace.toString(),
      );
      
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }

  // 🚪 Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Sign Out Error: $e");
    }
  }

  // 🛡️ ADVANCED DEBUG LOGGING
  Future<void> _logDebugAuthError({
    required String method,
    required String errorCode,
    required String errorMessage,
    String? stackTrace,
  }) async {
    try {
      await _firestore.collection('auth_debug_logs').add({
        'method': method,
        'errorCode': errorCode,
        'errorMessage': errorMessage,
        'stackTrace': stackTrace ?? "N/A",
        'platform': kIsWeb ? "Web" : "Mobile",
        // Web එකේදී එන ප්‍රශ්න හොයන්න User Agent එක වැදගත්
        'userAgent': kIsWeb ? html.window.navigator.userAgent : "Mobile",
        'location': kIsWeb ? html.window.location.href : "N/A",
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Logging to Firestore failed: $e");
    }
  }

  // Generic Failure Logging
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