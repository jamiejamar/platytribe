import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _sendReset() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _auth.sendPasswordReset(_email.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email.')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() { _error = '$e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _sendReset,
                    child: _loading ? const CircularProgressIndicator() : const Text('Send reset link'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
