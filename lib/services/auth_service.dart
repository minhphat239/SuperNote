import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  auth.User? get currentUser => _firebaseAuth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<auth.UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _ensureUserDocument(credential.user);
      notifyListeners();
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<auth.UserCredential> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _ensureUserDocument(credential.user);
      notifyListeners();
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<auth.UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      await _ensureUserDocument(userCredential.user);
      notifyListeners();
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    notifyListeners();
  }

  Future<void> _ensureUserDocument(auth.User? user) async {
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  String? get userId => currentUser?.uid;
}
