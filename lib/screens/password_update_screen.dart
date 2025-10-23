import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_singleton.dart';

class PasswordUpdateScreen extends StatefulWidget {
  const PasswordUpdateScreen({super.key});

  @override
  State<PasswordUpdateScreen> createState() => _PasswordUpdateScreenState();
}

class _PasswordUpdateScreenState extends State<PasswordUpdateScreen> {
  final _new1 = TextEditingController();
  final _new2 = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _save() async {
    if (_new1.text.isEmpty || _new2.text.isEmpty) {
      setState(() => _error = 'Please fill both fields');
      return;
    }
    if (_new1.text != _new2.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() => _loading = true);
    try {
      // Con il link email, Supabase crea una recovery session
      await supa.auth.updateUser(UserAttributes(password: _new1.text.trim()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please log in.')),
      );
      // Chiudi la sessione di recovery e torna al login
      await supa.auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set new password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _new1,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            TextField(
              controller: _new2,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Save new password'),
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

