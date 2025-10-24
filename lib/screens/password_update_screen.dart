import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _restoreSessionIfNeeded();
  }

  Future<void> _restoreSessionIfNeeded() async {
    final uri = Uri.base;
    try {
      // Support both #access_token=... and ?code=...
      if (uri.fragment.contains('access_token=') ||
          uri.queryParameters.containsKey('code') ||
          uri.queryParameters['type'] == 'recovery') {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    } catch (e) {
      // best effort; on Safari Private it can still be blocked
      debugPrint('Session restore attempt: $e');
    }
  }

  Future<void> _save() async {
    final a = _new1.text.trim();
    final b = _new2.text.trim();

    if (a.isEmpty || b.isEmpty) {
      setState(() => _error = 'Please fill both fields.');
      return;
    }
    if (a != b) {
      setState(() => _error = "Passwords don't match.");
      return;
    }
    if (a.length < 6) {
      setState(() => _error = 'Password too short.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: a),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please log in.')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: Colors.black54, fontStyle: FontStyle.italic);

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
            const SizedBox(height: 12),
            TextField(
              controller: _new2,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
            const SizedBox(height: 12),
            // 👇 Info message (English)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.info_outline, size: 16, color: Colors.black54),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: If you opened the reset link in Private / Incognito mode or an in-app browser, '
                    'session storage might be blocked and the update can fail. '
                    'If you see an error, open the reset link in a normal Safari or Chrome window and try again.',
                    style: noteStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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

