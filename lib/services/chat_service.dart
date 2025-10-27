import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat.dart';
import '../models/message.dart';
import 'supabase_singleton.dart';

class SearchResults {
  final List<ChatModel> titleOrId;
  final List<ChatModel> description;
  final List<ChatModel> tags;
  const SearchResults({
    required this.titleOrId,
    required this.description,
    required this.tags,
  });
}

class ChatService {
  // === FEED BASE ===
  Future<List<ChatModel>> fetchChats() async {
    final res = await supa
        .from('chats')
        .select('*, chat_tags(tag)')
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => ChatModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Feed casuale lato client
  Future<List<ChatModel>> fetchChatsRandom() async {
    final list = await fetchChats();
    list.shuffle(Random());
    return list;
  }

  // === INTERESSI UTENTE (se ti servono altrove)
  Future<List<String>> fetchUserInterests(String userId) async {
    final res =
        await supa.from('user_interests').select('tag').eq('user_id', userId);
    return (res as List).map((e) => e['tag'] as String).toList();
  }

  // === CREAZIONE CHAT (supporta description + tags)
  Future<String> createChat({
    required String name,
    String? description,
    required List<String> tags,
    String? avatarUrl,
    String? backgroundUrl,
    bool isGroup = false,
  }) async {
    final user = supa.auth.currentUser;
    final inserted = await supa
        .from('chats')
        .insert({
          'name': name,
          'description': description,
          'avatar_url': avatarUrl,
          'background_url': backgroundUrl,
          'is_group': isGroup,
          'created_by': user?.id,
        })
        .select()
        .single();

    final chatId = inserted['id'] as String;

    final cleaned = tags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .map((t) => t.toLowerCase())
        .toList();

    if (cleaned.isNotEmpty) {
      await supa.from('chat_tags').insert(
            cleaned.map((t) => {'chat_id': chatId, 'tag': t}).toList(),
          );
    }
    return chatId;
  }

  // === FOLLOW / UNFOLLOW
  Future<void> followChat(String chatId, {required bool follow}) async {
    final user = supa.auth.currentUser;
    if (user == null) return;
    if (follow) {
      await supa
          .from('chat_followers')
          .upsert({'chat_id': chatId, 'user_id': user.id});
    } else {
      await supa
          .from('chat_followers')
          .delete()
          .match({'chat_id': chatId, 'user_id': user.id});
    }
  }

  Future<bool> isFollowing(String chatId) async {
    final user = supa.auth.currentUser;
    if (user == null) return false;
    final row = await supa
        .from('chat_followers')
        .select('chat_id')
        .eq('chat_id', chatId)
        .eq('user_id', user.id)
        .maybeSingle();
    return row != null;
  }

  // === LISTE: My Chats / Followed Chats
  Future<List<ChatModel>> listMyChats(String userId) async {
    final res = await supa
        .from('chats')
        .select('id,name,description,created_at,chat_tags(tag),avatar_url,background_url,is_group,created_by')
        .eq('created_by', userId)
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => ChatModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatModel>> listFollowedChats(String userId) async {
    final idsRes = await supa
        .from('chat_followers')
        .select('chat_id')
        .eq('user_id', userId);
    final ids = (idsRes as List).map((e) => e['chat_id'] as String).toList();
    if (ids.isEmpty) return const [];

    final res = await supa
        .from('chats')
        .select('id,name,description,created_at,chat_tags(tag),avatar_url,background_url,is_group,created_by')
        .inFilter('id', ids)
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => ChatModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // === MESSAGGI
  Future<List<MessageModel>> fetchMessages(String chatId) async {
    final res = await supa
        .from('messages')
        .select('*')
        .eq('chat_id', chatId)
        .order('created_at');
    return (res as List).map((e) => MessageModel.fromMap(e)).toList();
  }

  Stream<List<MessageModel>> streamMessages(String chatId) {
    final stream = supa
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at');
    return stream.map((rows) => rows.map((e) => MessageModel.fromMap(e)).toList());
  }

  Future<void> sendMessage(String chatId, String text) async {
    final user = supa.auth.currentUser;
    await supa
        .from('messages')
        .insert({'chat_id': chatId, 'user_id': user?.id, 'text': text});
  }

  Future<void> saveInterests(List<String> tags) async {
    final user = supa.auth.currentUser;
    if (user == null) return;
    await supa.from('user_interests').delete().eq('user_id', user.id);
    if (tags.isNotEmpty) {
      await supa.from('user_interests').insert(
        tags.map((t) => {'user_id': user.id, 'tag': t.trim().toLowerCase()}).toList(),
      );
    }
  }

  // === SEARCH SPLIT: Title/ID, Description, Tags
  Future<SearchResults> searchChatsSplit(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      final random = await fetchChatsRandom();
      return SearchResults(titleOrId: random, description: const [], tags: const []);
    }

    final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(q);

    // 1) Title / ID
    dynamic resTitle;
    if (isUuid) {
      resTitle = await supa.from('chats').select('*, chat_tags(tag)').eq('id', q);
    } else {
      resTitle = await supa.from('chats').select('*, chat_tags(tag)').ilike('name', '%$q%');
    }
    final titleList = (resTitle as List).map((e) => ChatModel.fromMap(e as Map<String, dynamic>)).toList();

    // 2) Description
    final resDesc = await supa.from('chats').select('*, chat_tags(tag)').ilike('description', '%$q%');
    final descList = (resDesc as List).map((e) => ChatModel.fromMap(e as Map<String, dynamic>)).toList();

    // 3) Tags
    final resTagsIds = await supa.from('chat_tags').select('chat_id').ilike('tag', '%$q%');
    final ids = (resTagsIds as List).map((e) => e['chat_id'] as String).toSet().toList();

    List<ChatModel> tagsList = [];
    if (ids.isNotEmpty) {
      final resTags = await supa.from('chats').select('*, chat_tags(tag)').inFilter('id', ids);
      tagsList = (resTags as List).map((e) => ChatModel.fromMap(e as Map<String, dynamic>)).toList();
    }

    // dedupe per lista
    List<ChatModel> _dedupe(List<ChatModel> list) {
      final map = <String, ChatModel>{};
      for (final c in list) map[c.id] = c;
      return map.values.toList();
    }

    return SearchResults(
      titleOrId: _dedupe(titleList),
      description: _dedupe(descList),
      tags: _dedupe(tagsList),
    );
  }
}
