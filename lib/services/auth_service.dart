import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_singleton.dart';

class AuthService {
  Session? get session => supa.auth.currentSession;
  User? get user => supa.auth.currentUser;

  /// Standard sign up with email + password
  Future<AuthResponse> signUp(String email, String password) =>
      supa.auth.signUp(email: email, password: password);

  /// Sign in with email + password
  Future<AuthResponse> signIn(String email, String password) =>
      supa.auth.signInWithPassword(email: email, password: password);

  /// Sign out current session
  Future<void> signOut() => supa.auth.signOut();

  /// Stream for auth state changes (login, logout, recovery, etc.)
  Stream<AuthState> get onAuthStateChange => supa.auth.onAuthStateChange;

  /// Sign in anonymously (guest mode)
  Future<void> signInGuest() async {
    final id = const Uuid().v4().replaceAll('-', '');
    final email = 'guest-$id@example.com';
    final password = _randPass(24);
    final username = 'platy-${id.substring(0, 4)}';

    final res = await supa.auth.signUp(
      email: email,
      password: password,
      data: {'is_guest': true, 'username': username},
    );

    if (res.session == null) {
      await supa.auth.signInWithPassword(email: email, password: password);
    }

    final uid = supa.auth.currentUser!.id;
    await supa.from('profiles').upsert({
      'id': uid,
      'username': username,
      'is_guest': true,
      'display_name': username,
    });
  }

  /// NEW: Send password reset email
  Future<void> sendPasswordReset(String email) async {
    final mail = email.trim();
    if (mail.isEmpty) throw 'Please enter your email first.';

    const base = 'https://platytribe.pages.dev'; // your hosted URL
    await supa.auth.resetPasswordForEmail(
      mail,
      redirectTo: '$base#/password_update',
    );
  }

  /// Helper: random password generator for guests
  String _randPass(int len) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^*-_';
    final r = Random.secure();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
