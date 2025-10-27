import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/chat.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService();
  final _svc = ChatService();

  final _usernameCtrl = TextEditingController();

  String? _uid;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  List<ChatModel> _myChats = const [];
  List<ChatModel> _followed = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final u = _auth.user;
      _uid = u?.id;

      final p = await _auth.getProfile();
      if (p != null && p['username'] != null) {
        _usernameCtrl.text = '${p['username']}';
      }

      if (u != null) {
        final mine = await _svc.listMyChats(u.id);
        final foll = await _svc.listFollowedChats(u.id);
        _myChats = mine;
        _followed = foll;
      } else {
        _myChats = const [];
        _followed = const [];
      }
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      final username = _usernameCtrl.text.trim();
      if (username.isEmpty) throw 'Username cannot be empty.';
      await _auth.updateUsername(username);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Widget _list(String title, List<ChatModel> items) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('— empty —', style: TextStyle(color: Colors.black54))
          else
            ...items.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• ${c.name}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14)),
                )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = _auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_uid != null)
                    Text('UID: $_uid', style: Theme.of(context).textTheme.bodySmall),

                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'e.g., platy-1a2b',
                    ),
                  ),

                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const CircularProgressIndicator()
                              : const Text('Save'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () async {
                                await _auth.signOut();
                                if (!mounted) return;
                                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                              },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  if (u == null)
                    const Text(
                      'Sign in to see your lists.',
                      style: TextStyle(color: Colors.black54),
                    )
                  else ...[
                    _list('My Chats', _myChats),
                    _list('Followed Chats', _followed),
                  ],
                ],
              ),
            ),
    );
  }
}
