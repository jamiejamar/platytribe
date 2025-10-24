import 'dart:async'; // Stream/StreamSubscription
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthService();
  StreamSubscription<AuthState>? _sub;
  bool _isRecovery = false; // quando true evitiamo redirect a /home

  @override
  void initState() {
    super.initState();

    // 1️⃣ Ascolta evento emesso da Supabase (arrivo da link email in alcuni casi)
    _sub = _auth.onAuthStateChange.listen((state) async {
      if (!mounted) return;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _goToPasswordUpdate();
      } else {
        setState(() {}); // refresh normale (login/logout)
      }
    });

    // 2️⃣ Gestisci subito l’URL corrente (web): #type=recovery oppure ?code=...
    _handleInitialUrl();
  }

  Future<void> _handleInitialUrl() async {
    final uri = Uri.base;

    // Riconosci entrambi i formati (vecchio e nuovo)
    final hasFragmentRecovery = uri.fragment.contains('type=recovery');
    final hasTokenInFragment  = uri.fragment.contains('access_token=');
    final hasQueryCode        = uri.queryParameters['code']?.isNotEmpty == true;
    final hasQueryRecovery    = uri.queryParameters['type'] == 'recovery';

    if (hasFragmentRecovery || hasTokenInFragment || hasQueryCode || hasQueryRecovery) {
      try {
        // ✅ Crea la sessione a partire dall’URL (gestisce sia #... che ?code=...)
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (_) {
        // anche se fallisce, proviamo comunque ad aprire la pagina di update
      }
      _goToPasswordUpdate();
    }
  }

  void _goToPasswordUpdate() {
    if (!mounted) return;
    setState(() => _isRecovery = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamed(context, '/password_update');
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Durante il recovery non redirezionare a /home
    if (_isRecovery) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Nessuna sessione → landing
    if (_auth.session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PlatyTribe',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Log in / Sign up'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await _auth.signInGuest();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: const Text('Continue as Guest'),
              ),
            ],
          ),
        ),
      );
    }

    // Sessione presente → /home (ma non durante recovery)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isRecovery) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
