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
  bool _isRecovery = false; // 👈 se true, portiamo a /password_update

  @override
  void initState() {
    super.initState();

    // 1) Intercetta l’evento emesso da Supabase quando arrivi dal link email
    _sub = _auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery && mounted) {
        _goToPasswordUpdate();
      } else if (mounted) {
        setState(() {}); // refresh normale (login/logout)
      }
    });

    // 2) Web: se la pagina si apre *già* con #type=recovery nell’URL
    _checkInitialRecoveryFromUrl();
  }

  void _checkInitialRecoveryFromUrl() {
    // Su Web il link di Supabase aggiunge nel fragment: ...#access_token=...&type=recovery
    final frag = Uri.base.fragment; // es: "access_token=...&type=recovery&..."
    if (frag.contains('type=recovery')) {
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
    // Se siamo in recovery, non forzare redirect a /home
    if (_isRecovery) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Nessuna sessione → landing
    if (_auth.session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('PlatyTribe',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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

    // Sessione presente → vai a /home (ma non in recovery)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isRecovery) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
