import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<void> signUpWithEmail(String email, String password, {String? emailRedirectTo});
  Future<void> signInWithEmail(String email, String password);
  Future<void> signOut();
  Future<void> sendEmailOtp(String email);
  Future<void> verifyEmailOtp(String email, String token);

  User? get currentUser;
  Stream<AuthState> get onAuthStateChange;
}
