import 'dart:async';
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
  bool _isRecovery = false;

  @override
  void initState() {
    super.initState();

    // 1) Ascolta evento Supabase (arriva dal link email in alcuni casi)
    _sub = _auth.onAuthStateChange.listen((state) async {
      if (!mounted) return;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _goToPasswordUpdate();
      } else {
        setState(() {}); // normale refresh login/logout
      }
    });

    // 2) Gestisci subito URL corrente (web):
    _handleInitialUrl();
  }

  Future<void> _handleInitialUrl() async {
    // a) Fragment: ...#access_token=...&type=recovery
    final frag = Uri.base.fragment;
    if (frag.contains('type=recovery')) {
      _goToPasswordUpdate();
      return;
    }

    // b) Query string: ...?code=XXXX  (o ?token=...&type=recovery)
    final qp = Uri.base.queryParameters;
    final code = qp['code'];             // nuovo formato in alcuni flussi
    final token = qp['token'];           // vecchio formato
    final type = qp['type'];             // "recovery" se presente

    try {
      if (code != null && code.isNotEmpty) {
        // Prova a scambiare il "code" per una sessione
        await Supabase.instance.client.auth.exchangeCodeForSession(code);
        _goToPasswordUpdate();
        return;
      }
      if ((type == 'recovery') || (token != null && token.isNotEmpty)) {
        // In alcuni casi arriva token+type=recovery; su Flutter non sempre serve verifyOtp,
        // apriamo direttamente la pagina di update (la sessione è già di "recovery").
        _goToPasswordUpdate();
        return;
      }
    } catch (_) {
      // Se fallisce lo scambio, rimani nel flow normale (login/guest)
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

    // Sessione presente → /home (ma non durante recovery)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isRecovery) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
