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
    _sub = _auth.onAuthStateChange.listen((state) async {
      if (!mounted) return;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _goToPasswordUpdate();
      } else {
        setState(() {});
      }
    });
    _handleInitialUrl();
  }

  Future<void> _handleInitialUrl() async {
    final uri = Uri.base;
    final hasRecovery = uri.fragment.contains('type=recovery') ||
        uri.fragment.contains('access_token=') ||
        uri.queryParameters['type'] == 'recovery' ||
        uri.queryParameters.containsKey('code');

    if (hasRecovery) {
      try {
        // 🔥 Forza il recupero sessione anche per ?code=
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (e) {
        debugPrint('Session restore failed: $e');
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
    if (_isRecovery) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isRecovery) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
