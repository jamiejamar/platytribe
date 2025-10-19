import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});
  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final _name = TextEditingController();
  final _tags = TextEditingController();
  final _svc = ChatService();
  bool _loading = false;
  String? _error;

  Future<void> _create() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _svc.createChat(
        name: _name.text.trim(),
        tags: _tags.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) { setState(() { _error = '$e'; }); }
    finally { setState(() { _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crea Chat')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nome chat')),
            TextField(controller: _tags, decoration: const InputDecoration(labelText: 'Tag (separati da virgola)')),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loading ? null : _create, child: _loading ? const CircularProgressIndicator() : const Text('Crea')),
          ],
        ),
      ),
    );
  }
}
