import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models/chat.dart';
import '../algorithm/recommender.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _chatSvc = ChatService();
  final _auth = AuthService();
  List<ChatModel> _chats = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final chats = await _chatSvc.fetchChats();
      List<String> myTags = [];
      final user = _auth.user;
      if (user != null) {
        myTags = await _chatSvc.fetchUserInterests(user.id);
      }
      final ranked = SimpleRecommender().rank(chats, userTags: myTags, seed: DateTime.now().millisecondsSinceEpoch);
      setState(() { _chats = ranked; });
    } catch (e) { setState(() { _error = '$e'; }); }
    finally { setState(() { _loading = false; }); }
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlatyTribe'),
        actions: [
          IconButton(onPressed: () => Navigator.pushNamed(context, '/create_chat').then((_) => _load()), icon: const Icon(Icons.add)),
          IconButton(onPressed: () => Navigator.pushNamed(context, '/settings').then((_) => _load()), icon: const Icon(Icons.settings)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null
              ? Center(child: Text(_error!))
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _chats.length,
                  itemBuilder: (ctx, i) => _ChatCard(chat: _chats[i]),
                )),
    );
  }
}

class _ChatCard extends StatelessWidget {
  final ChatModel chat;
  const _ChatCard({required this.chat});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/chat', arguments: chat),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (chat.backgroundUrl != null) Image.network(chat.backgroundUrl!, fit: BoxFit.cover) else Container(color: Colors.black12),
          Container(
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundImage: chat.avatarUrl != null ? NetworkImage(chat.avatarUrl!) : null,
                  child: chat.avatarUrl == null ? Text(chat.name.isNotEmpty ? chat.name[0] : '?') : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(chat.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Wrap(spacing: 6, children: chat.tags.take(6).map((t) => Chip(label: Text('#$t'))).toList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
