import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatView extends StatefulWidget {
  final ChatModel chat;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;

  const ChatView({
    super.key,
    required this.chat,
    this.onSwipeUp,
    this.onSwipeDown,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with AutomaticKeepAliveClientMixin {
  final _svc = ChatService();
  final _auth = AuthService();
  final _ctrl = TextEditingController();

  bool _sending = false;
  bool _followLoading = false;
  bool _isFollowed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initFollow();
  }

  Future<void> _initFollow() async {
    final logged = _auth.session != null;
    if (!logged) {
      setState(() => _isFollowed = false);
      return;
    }
    final isF = await _svc.isFollowing(widget.chat.id);
    if (mounted) setState(() => _isFollowed = isF);
  }

  Future<void> _toggleFollow() async {
    if (_auth.session == null) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign in required'),
          content: const Text('You need to log in to follow chats.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Log in'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _followLoading = true);
    try {
      final wantFollow = !_isFollowed;
      await _svc.followChat(widget.chat.id, follow: wantFollow);
      if (mounted) setState(() => _isFollowed = wantFollow);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty) return;

    if (_auth.session == null) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign in required'),
          content: const Text('You need to log in to post messages.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Log in'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await _svc.sendMessage(widget.chat.id, _ctrl.text.trim());
      _ctrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final desc = (widget.chat.description ?? '').trim();
    final hasDesc = desc.isNotEmpty;
    final tagsText = widget.chat.tags.isNotEmpty ? widget.chat.tags.take(6).join(', ') : '';

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
              // Header: avatar + titolo + (desc+tags) + stellina
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: widget.chat.avatarUrl != null
                          ? NetworkImage(widget.chat.avatarUrl!)
                          : null,
                      child: widget.chat.avatarUrl == null
                          ? Text(widget.chat.name.isNotEmpty ? widget.chat.name[0] : '?')
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.chat.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasDesc)
                            Text(
                              desc,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (tagsText.isNotEmpty)
                            Text(
                              tagsText,
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _followLoading ? null : _toggleFollow,
                      icon: Icon(_isFollowed ? Icons.star : Icons.star_border_outlined),
                      color: Colors.amber,
                      tooltip: _isFollowed ? 'Following' : 'Follow',
                    ),
                  ],
                ),
              ),

              // Messages + swipe edge-detect
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _svc.streamMessages(widget.chat.id),
                  builder: (context, snap) {
                    final items = snap.data ?? const <MessageModel>[];
                    if (snap.connectionState == ConnectionState.waiting && items.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.atEdge) {
                          final delta = (n is ScrollUpdateNotification) ? (n.scrollDelta ?? 0) : 0.0;
                          final atTop = n.metrics.pixels <= n.metrics.minScrollExtent;
                          final atBottom = n.metrics.pixels >= n.metrics.maxScrollExtent;
                          if (atTop && delta < 0) widget.onSwipeDown?.call();
                          if (atBottom && delta > 0) widget.onSwipeUp?.call();
                        }
                        if (n is OverscrollNotification) {
                          if (n.overscroll < 0) widget.onSwipeDown?.call();
                          if (n.overscroll > 0) widget.onSwipeUp?.call();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final m = items[i];
                          final mine = m.userId == _auth.user?.id;
                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: mine ? Colors.teal : Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if ((m.authorUsername ?? '').isNotEmpty)
                                    Text(
                                      m.authorUsername!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  Text(
                                    m.text ?? '',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // Composer
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
                          hintText: 'Type a message…',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
