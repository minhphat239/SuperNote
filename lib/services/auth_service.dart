import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firestore_repository.dart';

class AuthService extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();
  final _authStreamController = StreamController<bool>.broadcast();
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLocalGuest = false;

  User? get user => _user;
  bool get isLoggedIn => _user != null || _isLocalGuest;
  bool get isLoading => _isLoading;
  bool get isLocalGuest => _isLocalGuest;
  String? get userId => _user?.uid ?? (_isLocalGuest ? _localGuestId : null);
  String? get userName => _user?.displayName ?? (_isLocalGuest ? 'Khách' : null);
  String? get userEmail => _user?.email;
  String? get userPhoto => _user?.photoURL;
  String? get errorMessage => _errorMessage;
  String? _localGuestId;

  Stream<bool> get authStateChanges => _authStreamController.stream;

  Future<void> init() async {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (!_isLocalGuest) {
        _user = user;
        _authStreamController.add(user != null);
        notifyListeners();
      }
    }, onError: (Object e) {
      debugPrint('[AuthService] Auth state stream error: $e');
    });
    await _restoreLocalGuest();
  }

  Future<void> _restoreLocalGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool('local_guest') ?? false;
      final guestId = prefs.getString('guest_id');
      if (isGuest && guestId != null) {
        _isLocalGuest = true;
        _localGuestId = guestId;
        _authStreamController.add(true);
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('[AuthService] Restore local guest failed: $e');
    }
    _authStreamController.add(false);
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
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Kết nối Google quá thời gian. Vui lòng thử lại!'),
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
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Xác thực Firebase quá thời gian. Vui lòng thử lại!'),
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
      debugPrint('[AuthService] Google sign in failed: $e');
      return false;
    } on TimeoutException catch (e) {
      _setError(e.toString());
      debugPrint('[AuthService] Google sign in timeout: $e');
      return false;
    } catch (e) {
      _setError('Lỗi không xác định. Vui lòng thử lại.');
      debugPrint('[AuthService] Google sign in failed: $e');
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
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Kết nối Firebase quá thời gian. Vui lòng thử lại!'),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(parseAuthError(e));
      debugPrint('[AuthService] Email sign in failed: $e');
      return false;
    } on TimeoutException catch (e) {
      _setError(e.toString());
      debugPrint('[AuthService] Email sign in timeout: $e');
      return false;
    } catch (e) {
      _setError('Lỗi không xác định. Vui lòng thử lại.');
      debugPrint('[AuthService] Email sign in failed: $e');
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      await _auth.sendPasswordResetEmail(email: email.trim()).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Kết nối Firebase quá thời gian. Vui lòng thử lại!'),
      );
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(parseAuthError(e));
      debugPrint('[AuthService] Password reset failed: $e');
      return false;
    } on TimeoutException catch (e) {
      _setError(e.toString());
      debugPrint('[AuthService] Password reset timeout: $e');
      return false;
    } catch (e) {
      _setError('Lỗi không xác định. Vui lòng thử lại.');
      debugPrint('[AuthService] Password reset failed: $e');
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
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Kết nối Firebase quá thời gian. Vui lòng thử lại!'),
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
      debugPrint('[AuthService] Register failed: $e');
      return false;
    } on TimeoutException catch (e) {
      _setError(e.toString());
      debugPrint('[AuthService] Register timeout: $e');
      return false;
    } catch (e) {
      _setError('Lỗi không xác định. Vui lòng thử lại.');
      debugPrint('[AuthService] Register failed: $e');
      return false;
    }
  }

  Future<bool> signInAsLocal() async {
    try {
      _setLoading(true);
      await _auth.signInAnonymously().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Firebase timeout'),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Anonymous sign in failed: $e');
      return _signInAsLocalFallback();
    } on TimeoutException catch (e) {
      debugPrint('[AuthService] Anonymous sign in timeout, falling back to local');
      return _signInAsLocalFallback();
    } catch (e, stackTrace) {
      debugPrint('[AuthService] signInAsLocal FAILED: ${e.runtimeType}: $e');
      return _signInAsLocalFallback();
    }
  }

  Future<bool> _signInAsLocalFallback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var guestId = prefs.getString('guest_id');
      if (guestId == null) {
        guestId = 'local_guest_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('guest_id', guestId);
      }
      await prefs.setBool('local_guest', true);
      _isLocalGuest = true;
      _localGuestId = guestId;
      _authStreamController.add(true);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      debugPrint('[AuthService] Local guest sign-in OK: $guestId');
      return true;
    } catch (e) {
      debugPrint('[AuthService] Local fallback failed: $e');
      _setError('Không thể đăng nhập. Vui lòng thử lại.');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      if (_isLocalGuest) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('local_guest');
        await prefs.remove('guest_id');
      } else {
        await _googleSignIn.signOut();
        await _auth.signOut();
      }
    } catch (e) {
      debugPrint('[AuthService] Sign out failed: $e');
    } finally {
      _user = null;
      _isLocalGuest = false;
      _localGuestId = null;
      _errorMessage = null;
      _authStreamController.add(false);
      notifyListeners();
    }
  }

  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Only remove user-specific keys, preserve app settings
      final keys = prefs.getKeys().where((k) =>
        k.startsWith('tasks_') ||
        k.startsWith('notes_') ||
        k == 'local_guest' ||
        k == 'guest_id'
      ).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('[AuthService] Clear session failed: $e');
    }
    _user = null;
    _isLocalGuest = false;
    _localGuestId = null;
    _errorMessage = null;
    _authStreamController.add(false);
    notifyListeners();
  }

  void syncFromFirebase(User? user) {
    _user = user;
    _isLocalGuest = false;
    _localGuestId = null;
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
