import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  _LocalUser? _user;

  _LocalUser? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get userId => _user?.id;
  String? get userName => _user?.name;
  String? get userEmail => _user?.email;
  String? get userPhoto => _user?.photoURL;

  Stream<bool> get authStateChanges => Stream.value(_isLoggedIn);

  AuthService();

  Future<bool> signInWithGoogle() async {
    return signInAsLocal();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    return signInAsLocal();
  }

  Future<bool> registerWithEmail(String email, String password, String name) async {
    _user = _LocalUser(id: 'local_user', name: name, email: email);
    _isLoggedIn = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> signUpWithEmail(String email, String password,
          [String name = 'User']) =>
      registerWithEmail(email, password, name);

  Future<bool> signInAsLocal() async {
    _user = _LocalUser(id: 'local_user', name: 'Local User');
    _isLoggedIn = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}

class _LocalUser {
  final String id;
  final String? name;
  final String? email;
  final String? photoURL;

  _LocalUser({required this.id, this.name, this.email, this.photoURL});
}
