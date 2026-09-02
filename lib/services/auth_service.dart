import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

import 'firestore_repository.dart';

class AuthService extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();
  final _authStreamController = StreamController<bool>.broadcast();
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get userId => _user?.uid;
  String? get userName => _user?.displayName;
  String? get userEmail => _user?.email;
  String? get userPhoto => _user?.photoURL;
  String? get errorMessage => _errorMessage;

  Stream<bool> get authStateChanges => _authStreamController.stream;

  AuthService() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      _user = user;
      _authStreamController.add(user != null);
      notifyListeners();
    }, onError: (Object e) {
      developer.log('Auth state stream error', error: e, name: 'AuthService');
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  static String parseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return 'Sai mật khẩu. Vui lòng thử lại.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'email-already-in-use':
        return 'Email đã được sử dụng. Vui lòng chọn email khác.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Cần ít nhất 6 ký tự.';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng đợi và thử lại sau.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Kiểm tra Internet và thử lại.';
      case 'popup-closed-by-user':
        return 'Bạn đã đóng cửa sổ đăng nhập.';
      case 'popup-blocked':
        return 'Cửa sổ popup bị chặn. Vui lòng cho phép popup.';
      case 'cancelled-popup-redirect':
        return 'Đăng nhập bị hủy.';
      case 'unauthorized-domain':
        return 'Tên miền không được ủy quyền.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập chưa được kích hoạt.';
      case 'requires-recent-login':
        return 'Vui lòng đăng nhập lại để tiếp tục.';
      case 'account-exists-with-different-credential':
        return 'Email này đã được đăng ký với phương thức khác.';
      case 'invalid-verification-code':
        return 'Mã xác minh không đúng.';
      case 'invalid-verification-id':
        return 'ID xác minh không hợp lệ.';
      case 'quota-exceeded':
        return 'Đã vượt quá giới hạn. Thử lại sau.';
      default:
        return 'Lỗi: ${e.message ?? 'Không xác định'}';
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Kết nối Google quá thời gian. Vui lòng thử lại!'),
          );
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Xác thực Firebase quá thời gian. Vui lòng thử lại!'),
          );

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await FirestoreRepository().createUserProfile(
          uid: userCredential.user!.uid,
          displayName: userCredential.user!.displayName ?? '',
          email: userCredential.user!.email ?? '',
          photoUrl: userCredential.user!.photoURL,
        );
      }

      return true;
    } on FirebaseAuthException catch (e) {
      _setError(parseAuthError(e));
      developer.log('Google sign in failed', error: e, name: 'AuthService');
      return false;
    } on TimeoutException catch (e) {
      _setError(e.toString());
      developer.log('Google sign in timeout', error: e, name: 'AuthService');
      return false;
    } catch (e) {
      _setError('Lỗi không xác định. Vui lòng thử lại.');
      developer.log('Google sign in failed', error: e, name: 'AuthService');
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Kết nối Firebase quá thời gian. Vui lòng thử lại!'),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(parseAuthError(e));
      developer.log('Email sign in failed', error: e, name: 'AuthService');
      return false;
    } on TimeoutException catch (e) {
      _setError(e.toString());
      developer.log('Email sign in timeout', error: e, name: 'AuthService');
      return false;
    } catch (e) {
      _setError('Lỗi không xác định. Vui lòng thử lại.');
      developer.log('Email sign in failed', error: e, name: 'AuthService');
      return false;
    }
  }

  Future<bool> registerWithEmail(
      String email, String password, String name) async {
    try {
      _setLoading(true);
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Kết nối Firebase quá thời gian. Vui lòng thử lại!'),
      );

      await result.user?.updateDisplayName(name);

      await FirestoreRepository().createUserProfile(
        uid: result.user!.uid,
        displayName: name,
        email: email.trim(),
      );

      await result.user?.reload();
      _user = _auth.currentUser;
      _authStreamController.add(true);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(parseAuthError(e));
      developer.log('Register failed', error: e, name: 'AuthService');
      return false;
    } on TimeoutException catch (e) {
      _setError(e.toString());
      developer.log('Register timeout', error: e, name: 'AuthService');
      return false;
    } catch (e) {
      _setError('Lỗi không xác định. Vui lòng thử lại.');
      developer.log('Register failed', error: e, name: 'AuthService');
      return false;
    }
  }

  Future<bool> signInAsLocal() async {
    try {
      _setLoading(true);
      await _auth.signInAnonymously().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Kết nối Firebase quá thời gian. Kiểm tra Internet và thử lại!'),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(parseAuthError(e));
      developer.log('Anonymous sign in failed', error: e, name: 'AuthService');
      return false;
    } on TimeoutException catch (e) {
      _setError(e.toString());
      developer.log('Anonymous sign in timeout', error: e, name: 'AuthService');
      return false;
    } catch (e) {
      _setError('Lỗi không xác định. Vui lòng thử lại.');
      developer.log('Anonymous sign in failed', error: e, name: 'AuthService');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      developer.log('Sign out failed', error: e, name: 'AuthService');
    } finally {
      _user = null;
      _errorMessage = null;
      _authStreamController.add(false);
      notifyListeners();
    }
  }

  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      developer.log('Clear session failed', error: e, name: 'AuthService');
    }
    _user = null;
    _errorMessage = null;
    _authStreamController.add(false);
    notifyListeners();
  }

  void syncFromFirebase(User? user) {
    _user = user;
    _authStreamController.add(user != null);
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authStreamController.close();
    super.dispose();
  }
}
