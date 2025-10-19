import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatSvc = ChatService();
  final _auth = AuthService();
  late final ChatModel chat;
  List<MessageModel> _messages = [];
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chat = ModalRoute.of(context)!.settings.arguments as ChatModel;
    _chatSvc.streamMessages(chat.id).listen((msgs) {
      if (!mounted) return;
      setState(() => _messages = msgs);
    });
  }

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await _chatSvc.sendMessage(chat.id, _ctrl.text.trim());
      _ctrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chat.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final mine = m.userId == _auth.user?.id;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: mine ? Colors.teal : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(m.text ?? '', style: TextStyle(color: mine ? Colors.white : Colors.black87)),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Scrivi un messaggio...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              IconButton(onPressed: _sending ? null : _send, icon: const Icon(Icons.send)),
            ],
          ),
        ],
      ),
    );
  }
}
