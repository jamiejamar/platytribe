import 'dart:async'; // per Timer (debounce)
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models/chat.dart';
import '../widgets/chat_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _chatSvc = ChatService();
  final _auth = AuthService();
  final _page = PageController();

  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<ChatModel> _chats = [];
  bool _loading = true;
  bool _searching = false;
  String? _error;

  // risultati split (se la query non è vuota)
  SearchResults? _split;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _split = null; });
    try {
      final chats = await _chatSvc.fetchChatsRandom(); // feed casuale
      setState(() { _chats = chats; });
    } catch (e) {
      setState(() { _error = '$e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _runSearch(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      await _load();
      return;
    }
    setState(() { _searching = true; _error = null; });
    try {
      final res = await _chatSvc.searchChatsSplit(query);
      setState(() { _split = res; });
    } catch (e) {
      setState(() { _error = '$e'; });
    } finally {
      setState(() { _searching = false; });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(_searchCtrl.text);
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => _onSearchChanged(_searchCtrl.text));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _page.dispose();
    super.dispose();
  }

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

  void _openFromSearch(ChatModel chat) {
    // Mostra quella chat direttamente nel feed verticale
    setState(() {
      _split = null;
      _chats = [chat];
    });
    _page.jumpToPage(0);
  }

  Widget _section(String title, List<ChatModel> list) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          ...list.map((c) {
            final subtitlePieces = <String>[];
            if ((c.description ?? '').isNotEmpty) {
              final d = c.description!;
              subtitlePieces.add(d.length > 80 ? '${d.substring(0, 80)}…' : d);
            }
            if (c.tags.isNotEmpty) {
              subtitlePieces.add(c.tags.take(5).join(', '));
            }
            final subtitle = subtitlePieces.isEmpty ? null : subtitlePieces.join('  ·  ');
            return ListTile(
              title: Text(c.name),
              subtitle: subtitle == null ? null : Text(subtitle),
              onTap: () => _openFromSearch(c),
            );
          }),
        ],
      ),
    );
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

    final searchBar = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search by Title, ID, Description or Tags…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: (_searchCtrl.text.isNotEmpty)
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear(); // triggerà _load via listener
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _runSearch(_searchCtrl.text),
      ),
    );

    final searchIndicator = (_searching)
        ? const LinearProgressIndicator(minHeight: 2)
        : const SizedBox(height: 2);

    Widget bodyContent;
    if (_loading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      bodyContent = Center(child: Text(_error!));
    } else if (_split != null && _searchCtrl.text.trim().isNotEmpty) {
      // Vista risultati split
      final s = _split!;
      bodyContent = ListView(
        children: [
          _section('Title / ID', s.titleOrId),
          _section('Description', s.description),
          _section('Tags', s.tags),
          const SizedBox(height: 24),
        ],
      );
    } else if (_chats.isEmpty) {
      bodyContent = const Center(child: Text('No chats found'));
    } else {
      // Feed verticale con ChatView
      bodyContent = Stack(
        children: [
          PageView.builder(
            controller: _page,
            scrollDirection: Axis.vertical,
            itemCount: _chats.length,
            itemBuilder: (ctx, i) => ChatView(
              chat: _chats[i],
              onSwipeUp: _next,
              onSwipeDown: _prev,
            ),
          ),
          navButtons,
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlatyTribe'),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/create_chat').then((_) => _load()),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/settings').then((_) => _load()),
            icon: const Icon(Icons.settings),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              searchBar,
              searchIndicator,
            ],
          ),
        ),
      ),
      body: bodyContent,
    );
  }
}
