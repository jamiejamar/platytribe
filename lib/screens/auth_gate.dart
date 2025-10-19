import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthService();
  @override
  void initState() { super.initState(); _auth.onAuthStateChange.listen((_) => mounted ? setState(() {}) : null); }
  @override
  Widget build(BuildContext context) {
    if (_auth.session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('PlatyTribe', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Accedi / Registrati')),
              const SizedBox(height: 12),
              TextButton(onPressed: () async { await _auth.signInGuest(); if (!mounted) return; Navigator.pushReplacementNamed(context, '/home'); }, child: const Text('Continua come Ospite')),
            ],
          ),
        ),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pushReplacementNamed(context, '/home'));
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
