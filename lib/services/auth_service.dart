import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_singleton.dart';

class AuthService {
  Session? get session => supa.auth.currentSession;
  User? get user => supa.auth.currentUser;

  Future<AuthResponse> signUp(String email, String password) => supa.auth.signUp(email: email, password: password);
  Future<AuthResponse> signIn(String email, String password) => supa.auth.signInWithPassword(email: email, password: password);
  Future<void> signOut() => supa.auth.signOut();
  Stream<AuthState> get onAuthStateChange => supa.auth.onAuthStateChange;

  Future<void> signInGuest() async {
    final id = const Uuid().v4().replaceAll('-', '');
    final email = 'guest-$id@guest.local';
    final password = _randPass(24);
    final username = 'platy-${id.substring(0,4)}';
    final res = await supa.auth.signUp(email: email, password: password, data: {'is_guest': true, 'username': username});
    if (res.session == null) {
      await supa.auth.signInWithPassword(email: email, password: password);
    }
    final uid = supa.auth.currentUser!.id;
    await supa.from('profiles').upsert({'id': uid, 'username': username, 'is_guest': true, 'display_name': username});
  }

  String _randPass(int len) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^*-_';
    final r = Random.secure();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
