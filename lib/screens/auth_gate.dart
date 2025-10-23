import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // per AuthChangeEvent
import '../services/auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthService();
  late final Stream<AuthState> _authStream;
  StreamSubscription<AuthState>? _sub;

  @override
  void initState() {
    super.initState();
    _authStream = _auth.onAuthStateChange;

    // Ascolta cambi di stato (login, logout, password recovery, ecc.)
    _sub = _authStream.listen((state) {
      // Se l'utente ha aperto il link di reset → vai alla pagina per impostare la nuova password
      if (state.event == AuthChangeEvent.passwordRecovery && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(context, '/password_update');
        });
      }
      // Aggiorna la UI per riflettere eventuali cambi di sessione
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nessuna sessione → landing con login / guest
    if (_auth.session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('PlatyTribe', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
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

    // C'è una sessione → vai a /home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
