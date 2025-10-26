import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_singleton.dart';

class AuthService {
  Session? get session => supa.auth.currentSession;
  User? get user => supa.auth.currentUser;

  /// Sign up with email + password, ensure profile row exists
  Future<AuthResponse> signUp(String email, String password) async {
    final res = await supa.auth.signUp(email: email, password: password);

    // crea/aggiorna profilo di base (serve ai trigger username)
    final uid = supa.auth.currentUser?.id;
    if (uid != null) {
      final base = email.split('@').first;
      await supa.from('profiles').upsert({
        'id': uid,
        'username': base,
        'is_guest': false,
        'display_name': base,
      });
    }
    return res;
  }

  /// Sign in with email + password
  Future<AuthResponse> signIn(String email, String password) =>
      supa.auth.signInWithPassword(email: email, password: password);

  /// Sign out
  Future<void> signOut() => supa.auth.signOut();

  /// Auth state changes
  Stream<AuthState> get onAuthStateChange => supa.auth.onAuthStateChange;

  /// Guest sign-in
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

  /// NEW: send password reset email and redirect back to update page
  Future<void> sendPasswordReset(String email) async {
    final mail = email.trim();
    if (mail.isEmpty) throw 'Please enter your email first.';

    // usa il tuo dominio pubblico
    const base = 'https://platytribe.pages.dev';
    await supa.auth.resetPasswordForEmail(
      mail,
      redirectTo: '$base#/password_update',
    );
  }

  String _randPass(int len) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^*-_';
    final r = Random.secure();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
