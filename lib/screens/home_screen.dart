// lib/screens/home_screen.dart
import 'dart:async';
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

  @override
  void initState() {
    super.initState();
    _loadRandomFeed();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _page.dispose();
    super.dispose();
  }

  // ---------- FIX: salta alla prima pagina solo quando il PageView è pronto
  void _jumpToFirst() {
    if (_chats.isEmpty) return;
    if (_page.hasClients) {
      _page.jumpToPage(0);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _page.hasClients && _chats.isNotEmpty) {
          _page.jumpToPage(0);
        }
      });
    }
  }

  // ---------- FEED RANDOM
  Future<void> _loadRandomFeed() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _chatSvc.fetchChatsRandom();
      setState(() => _chats = list);
      _jumpToFirst(); // usa il fix
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- SEARCH (semplificata: unisce titolo/descrizione/tag)
  Future<void> _applySearch(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) {
      await _loadRandomFeed();
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      // Usa la tua search split e unisci risultati unici per id
      final split = await _chatSvc.searchChatsSplit(q);
      final map = <String, ChatModel>{};
      for (final c in split.titleOrId) map[c.id] = c;
      for (final c in split.description) map[c.id] = c;
      for (final c in split.tags) map[c.id] = c;
      final merged = map.values.toList();

      setState(() => _chats = merged);
      _jumpToFirst(); // usa il fix
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applySearch(_searchCtrl.text);
    });
  }

  void _next() {
    final i = _page.page?.round() ?? 0;
    if (i < _chats.length - 1) {
      _page.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _prev() {
    final i = _page.page?.round() ?? 0;
    if (i > 0) {
      _page.previousPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
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

    final searchBar = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search by title, description or tags…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: (_searchCtrl.text.isNotEmpty)
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear(); // torni al feed casuale
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
        onSubmitted: (_) => _applySearch(_searchCtrl.text),
      ),
    );

    final searchIndicator =
        _searching ? const LinearProgressIndicator(minHeight: 2) : const SizedBox(height: 2);

    Widget bodyContent;
    if (_loading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      bodyContent = Center(child: Text(_error!));
    } else if (_chats.isEmpty) {
      bodyContent = const Center(child: Text('No chats found'));
    } else {
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
                Navigator.pushNamed(context, '/create_chat').then((_) => _loadRandomFeed()),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/settings').then((_) => _loadRandomFeed()),
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
