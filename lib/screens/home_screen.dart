import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models/chat.dart';
import '../algorithm/recommender.dart';
import '../widgets/chat_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _chatSvc = ChatService();
  final _auth = AuthService();
  final _page = PageController();           // 👈 controller
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
      final ranked = SimpleRecommender()
          .rank(chats, userTags: myTags, seed: DateTime.now().millisecondsSinceEpoch);
      setState(() { _chats = ranked; });
    } catch (e) { setState(() { _error = '$e'; }); }
    finally { setState(() { _loading = false; }); }
  }

  @override
  void initState() { super.initState(); _load(); }

  void _next() {
    final i = _page.page?.round() ?? 0;
    if (i < _chats.length - 1) {
      _page.nextPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  void _prev() {
    final i = _page.page?.round() ?? 0;
    if (i > 0) {
      _page.previousPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navButtons = Positioned(
      right: 8,
      top: MediaQuery.of(context).size.height / 2 - 64,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: 'nav_up',
            onPressed: _prev,
            child: const Icon(Icons.keyboard_arrow_up),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'nav_down',
            onPressed: _next,
            child: const Icon(Icons.keyboard_arrow_down),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlatyTribe'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/create_chat').then((_) => _load()),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings').then((_) => _load()),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null
              ? Center(child: Text(_error!))
              : Stack(
                  children: [
                    PageView.builder(
                      controller: _page,
                      scrollDirection: Axis.vertical,
                      itemCount: _chats.length,
                      itemBuilder: (ctx, i) => ChatView(
                        chat: _chats[i],
                        onSwipeUp: _next,      // 👈 swipe dalla chat
                        onSwipeDown: _prev,    // 👈 swipe dalla chat
                      ),
                    ),
                    navButtons,               // 👈 bottoni laterali
                  ],
                )),
    );
  }
}
