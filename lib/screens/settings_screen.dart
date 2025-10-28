import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/chat.dart';
import '../services/supabase_singleton.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService();
  final _usernameCtrl = TextEditingController();

  String? _uid;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  // liste
  List<ChatModel> _myChats = const [];
  List<ChatModel> _followedChats = const [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // profilo / username
      final u = _auth.user;
      _uid = u?.id;

      final p = await _auth.getProfile();
      if (p != null && p['username'] != null) {
        _usernameCtrl.text = '${p['username']}';
      }

      // --- le mie chat (create_by = me) ---
      if (_uid != null) {
        final rows = await supa
            .from('chats')
            .select('id,name,avatar_url,background_url,is_group,created_by,created_at, chat_tags(tag)')
            .eq('created_by', _uid)
            .order('created_at', ascending: false);
        _myChats = (rows as List)
            .map((e) => ChatModel.fromMap(e as Map<String, dynamic>))
            .toList();
      }

      // --- chat seguite ---
      if (_uid != null) {
        final idsRes = await supa
            .from('chat_followers')
            .select('chat_id')
            .eq('user_id', _uid);
        final ids = (idsRes as List).map((e) => e['chat_id'] as String).toList();

        if (ids.isNotEmpty) {
          final rows = await supa
              .from('chats')
              .select('id,name,avatar_url,background_url,is_group,created_by,created_at, chat_tags(tag)')
              .inFilter('id', ids);
          _followedChats = (rows as List)
              .map((e) => ChatModel.fromMap(e as Map<String, dynamic>))
              .toList();
          // ordina un minimo
          _followedChats.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        } else {
          _followedChats = const [];
        }
      }
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final username = _usernameCtrl.text.trim();
      if (username.isEmpty) throw 'Username cannot be empty.';
      await _auth.updateUsername(username);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Username updated')));
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _chatList(String title, List<ChatModel> items) {
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
            ...items.map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ${c.name}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14)),
                    // 👇 ID in piccolo e grigio
                    Text(
                      c.id,
                      style: const TextStyle(color: Colors.black45, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_uid != null)
                      Text('UID: $_uid',
                          style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),

                    // Username
                    TextField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'e.g., platy-1a2b',
                      ),
                    ),
                    const SizedBox(height: 12),
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
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/login', (_) => false);
                                },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),

                    // Liste
                    _chatList('My Chats', _myChats),
                    _chatList('Followed Chats', _followedChats),
                  ],
                ),
              ),
            ),
    );
  }
}
