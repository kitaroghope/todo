import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  bool _loading = false;
  String? _error;
  User? _user;
  StreamSubscription<AuthState>? _sub;

  AuthProvider(this._authRepository) {
    _user = _authRepository.currentUser;
    _sub = _authRepository.onAuthStateChange.listen((event) {
      _user = event.session?.user;
      notifyListeners();
    });
  }

  bool get loading => _loading;
  String? get error => _error;
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isEmailVerified => _user?.emailConfirmedAt != null;
  String? get userEmail => _user?.email;

  Future<void> signUp(String email, String password, {String? emailRedirectTo}) async {
    _setLoading(true);
    try {
      await _authRepository.signUpWithEmail(email, password, emailRedirectTo: emailRedirectTo);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _authRepository.signInWithEmail(email, password);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendEmailOtp(String email) async {
    _setLoading(true);
    try {
      await _authRepository.sendEmailOtp(email);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyEmailOtp(String email, String token) async {
    _setLoading(true);
    try {
      await _authRepository.verifyEmailOtp(email, token);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
