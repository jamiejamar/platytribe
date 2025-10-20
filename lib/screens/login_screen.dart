import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.signIn(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _error = '$e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _signup() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.signUp(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _error = '$e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _guest() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.signInGuest();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _error = '$e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    try {
      await _auth.sendPasswordReset(_email.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signin,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Log in'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : _signup,
                    child: const Text('Sign up'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : _resetPassword,
              child: const Text('Forgot password?'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loading ? null : _guest,
              child: const Text('Continue as Guest'),
            ),
          ],
        ),
      ),
    );
  }
}
