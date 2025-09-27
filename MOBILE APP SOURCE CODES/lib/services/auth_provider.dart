import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // 🔐 Sign In with Email and Password
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw Exception('Sign in failed: ${e.message}');
    }
  }

  // 🆕 Sign Up with Email and Password
  Future<void> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw Exception('Sign up failed: ${e.message}');
    }
  }

  // 🚪 Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // 🔁 Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to send reset email: ${e.message}');
    }
  }

  // 👤 Update Display Name and/or Photo URL
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      if (displayName != null) {
        await currentUser?.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await currentUser?.updatePhotoURL(photoUrl);
      }
      await currentUser?.reload(); // Refresh user info
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw Exception('Profile update failed: ${e.message}');
    }
  }

  // 🔑 Change Password
  Future<void> changePassword(String newPassword) async {
    try {
      await currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception('Password change failed: ${e.message}');
    }
  }

  // 📧 Update Email
  Future<void> updateEmail(String newEmail) async {
    try {
      await currentUser?.updateEmail(newEmail);
      await currentUser?.reload();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw Exception('Email update failed: ${e.message}');
    }
  }

  // ❌ Delete Account
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw Exception('Account deletion failed: ${e.message}');
    }
  }

  // 🔐 Re-authenticate before sensitive actions
  Future<void> reauthenticate(String email, String password) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await currentUser?.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception('Re-authentication failed: ${e.message}');
    }
  }
}
