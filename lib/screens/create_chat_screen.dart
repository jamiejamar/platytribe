import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});
  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();           // NEW
  final _keywords = TextEditingController();             // NEW
  final _svc = ChatService();
  bool _loading = false;
  String? _error;

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Inserisci un nome per la chat');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final tags = _keywords.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await _svc.createChat(
        name: name,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        tags: tags,
      );

      if (!mounted) return;
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
      appBar: AppBar(title: const Text('Crea Chat')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome chat'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrizione (opzionale)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _keywords,
              decoration: const InputDecoration(
                labelText: 'Tag / Keywords (separati da virgola)',
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _create,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Crea'),
            ),
          ],
        ),
      ),
    );
  }
}
