import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatView extends StatefulWidget {
  final ChatModel chat;
  const ChatView({super.key, required this.chat});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView>
    with AutomaticKeepAliveClientMixin {
  final _svc = ChatService();
  final _auth = AuthService();
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await _svc.sendMessage(widget.chat.id, _ctrl.text.trim());
      _ctrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.chat.backgroundUrl != null)
          Image.network(widget.chat.backgroundUrl!, fit: BoxFit.cover)
        else
          Container(color: Colors.black12),

        SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: widget.chat.avatarUrl != null
                          ? NetworkImage(widget.chat.avatarUrl!)
                          : null,
                      child: widget.chat.avatarUrl == null
                          ? Text(widget.chat.name.isNotEmpty
                              ? widget.chat.name[0]
                              : '?')
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.chat.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Messaggi
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _svc.streamMessages(widget.chat.id),
                  builder: (context, snap) {
                    final items = snap.data ?? const <MessageModel>[];
                    if (snap.connectionState == ConnectionState.waiting &&
                        items.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final m = items[i];
                        final mine = m.userId == _auth.user?.id;
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: mine ? Colors.teal : Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              m.text ?? '',
                              style: TextStyle(
                                  color: mine ? Colors.white : Colors.white),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Input sempre in basso
              Padding(
                padding: EdgeInsets.only(
                  left: 8,
                  right: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                  top: 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        decoration: InputDecoration(
                          hintText: 'Scrivi qui…',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sending ? null : _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
