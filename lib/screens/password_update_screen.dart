import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PasswordUpdateScreen extends StatefulWidget {
  const PasswordUpdateScreen({super.key});

  @override
  State<PasswordUpdateScreen> createState() => _PasswordUpdateScreenState();
}

class _PasswordUpdateScreenState extends State<PasswordUpdateScreen> {
  final _newPass = TextEditingController();
  final _confirmPass = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreSessionIfNeeded();
  }

  Future<void> _restoreSessionIfNeeded() async {
    final uri = Uri.base;
    try {
      // gestisce sia #access_token=... che ?code=...
      if (uri.fragment.contains('access_token=') ||
          uri.queryParameters.containsKey('code')) {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    } catch (e) {
      debugPrint('Session restore failed: $e');
    }
  }

  Future<void> _updatePassword() async {
    final newPass = _newPass.text.trim();
    final confirm = _confirmPass.text.trim();
    if (newPass != confirm) {
      setState(() => _error = "Passwords don't match");
      return;
    }
    if (newPass.length < 6) {
      setState(() => _error = "Password too short");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully")),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      setState(() => _error = "$e");
    } finally {
      setState(() => _loading = false);
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
              controller: _newPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _updatePassword,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Save new password'),
            ),
          ],
        ),
      ),
    );
  }
}

