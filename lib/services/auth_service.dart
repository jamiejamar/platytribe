import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_singleton.dart';

class AuthService {
  Session? get session => supa.auth.currentSession;
  User? get user => supa.auth.currentUser;

  // ---- Email sign-up: assegna sempre uno username random e crea il profilo
  Future<AuthResponse> signUp(String email, String password) async {
    final res = await supa.auth.signUp(email: email, password: password);

    // Alcuni flussi non ritornano sessione subito → facciamo sign-in
    if (res.session == null) {
      await supa.auth.signInWithPassword(email: email, password: password);
    }

    await _ensureProfile(); // crea profilo + username random se manca
    return res;
  }

  Future<AuthResponse> signIn(String email, String password) =>
      supa.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => supa.auth.signOut();

  Stream<AuthState> get onAuthStateChange => supa.auth.onAuthStateChange;

  // ---- Guest login: stesso comportamento (username random)
  Future<void> signInGuest() async {
    final id = const Uuid().v4().replaceAll('-', '');
    final email = 'guest-$id@example.com';
    final password = _randPass(24);
    final username = _randomUsername();

    final res = await supa.auth.signUp(
      email: email,
      password: password,
      data: {'is_guest': true, 'username': username},
    );

    if (res.session == null) {
      await supa.auth.signInWithPassword(email: email, password: password);
    }

    await supa.from('profiles').upsert({
      'id': supa.auth.currentUser!.id,
      'username': username,
      'display_name': username,
      'is_guest': true,
    });
  }

  /// Crea profilo con username random se non esiste
  Future<void> _ensureProfile() async {
    final u = user;
    if (u == null) return;

    final existing = await supa
        .from('profiles')
        .select('id, username')
        .eq('id', u.id)
        .maybeSingle();

    if (existing == null) {
      final username = _randomUsername();
      await supa.from('profiles').insert({
        'id': u.id,
        'username': username,
        'display_name': username,
        'is_guest': false,
      });
    }
  }

  /// Aggiorna lo username
  Future<void> updateUsername(String newUsername) async {
    final u = user;
    if (u == null) return;
    await supa.from('profiles').update({'username': newUsername}).eq('id', u.id);
  }

  /// Legge il profilo corrente (username, ecc.)
  Future<Map<String, dynamic>?> getProfile() async {
    final u = user;
    if (u == null) return null;
    return await supa
        .from('profiles')
        .select('id, username, display_name, is_guest')
        .eq('id', u.id)
        .maybeSingle();
  }

  // ---- utils
  String _randomUsername() {
    final id = const Uuid().v4().replaceAll('-', '');
    return 'platy-${id.substring(0, 4)}';
  }

  String _randPass(int len) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^*-_';
    final r = Random.secure();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
