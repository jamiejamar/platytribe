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

    // crea/aggiorna profilo di base
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

  /// Send password reset email and redirect back to update page
  Future<void> sendPasswordReset(String email) async {
    final mail = email.trim();
    if (mail.isEmpty) throw 'Please enter your email first.';
    const base = 'https://platytribe.pages.dev'; // dominio pubblico
    await supa.auth.resetPasswordForEmail(
      mail,
      redirectTo: '$base#/password_update',
    );
  }

  /// ✅ Get current user's profile (creates a default one if missing)
  Future<Map<String, dynamic>> getProfile() async {
    final uid = user?.id;
    if (uid == null) {
      throw 'Not authenticated';
    }

    final res = await supa
        .from('profiles')
        .select()
        .eq('id', uid)
        .limit(1);

    final list = (res as List);
    if (list.isEmpty) {
      // crea profilo base se non esiste
      final base = user!.email?.split('@').first ?? 'user';
      final row = {
        'id': uid,
        'username': base,
        'display_name': base,
        'is_guest': false,
      };
      await supa.from('profiles').upsert(row);
      return Map<String, dynamic>.from(row);
    }
    return Map<String, dynamic>.from(list.first as Map);
  }

  /// ✅ Update username (and display_name for coherence)
  Future<void> updateUsername(String username) async {
    final uid = user?.id;
    if (uid == null) throw 'Not authenticated';

    final name = username.trim();
    if (name.isEmpty) throw 'Username cannot be empty';

    try {
      await supa
          .from('profiles')
          .update({'username': name, 'display_name': name})
          .eq('id', uid);
    } on PostgrestException catch (e) {
      // opzionale: intercetta unique violation (23505)
      if (e.code == '23505') {
        throw 'Username already taken';
      }
      rethrow;
    }
  }

  String _randPass(int len) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^*-_';
    final r = Random.secure();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
