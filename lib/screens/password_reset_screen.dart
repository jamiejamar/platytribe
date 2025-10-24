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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.sendPasswordReset(_email.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email.')),
      );
      Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Reset password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _sendReset,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Send reset link'),
                  ),
                ),
              ],
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
                    'Note: For the password recovery process to work correctly, '
                    'please avoid using Private / Incognito mode or in-app browsers (like Gmail or Outlook preview). '
                    'Some browsers block secure session storage in private mode, which may prevent us from verifying your reset link. '
                    'If you have trouble, open the link directly in Safari or Chrome in a normal window.',
                    style: noteStyle,
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
