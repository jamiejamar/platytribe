import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService();
  final _chatSvc = ChatService();
  final _tagsCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _load() async {
    final user = _auth.user;
    if (user == null) return;
    final tags = await _chatSvc.fetchUserInterests(user.id);
    _tagsCtrl.text = tags.join(', ');
  }

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final tags = _tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      await _chatSvc.saveInterests(tags);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Interessi salvati')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final logged = _auth.user != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UID: ${_auth.user?.id ?? '-'}'),
            const SizedBox(height: 6),
            TextField(controller: _tagsCtrl, decoration: const InputDecoration(labelText: 'Hashtag interessi (separati da virgola)'), enabled: logged),
            const SizedBox(height: 12),
            Row(children: [
              ElevatedButton(onPressed: logged && !_saving ? _save : null, child: const Text('Salva')),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: _logout, child: const Text('Logout'))
            ]),
          ],
        ),
      ),
    );
  }
}
