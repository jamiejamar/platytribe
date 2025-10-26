import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'supabase_singleton.dart';

class ChatService {
  // --- FEED BASE: lista casuale ---
  Future<List<ChatModel>> fetchChatsRandom() async {
    final res = await supa
        .from('chats')
        .select('*, chat_tags(tag)')
        .order('created_at', ascending: false);
    final list = (res as List)
        .map((e) => ChatModel.fromMap(e as Map<String, dynamic>))
        .toList();
    list.shuffle(Random());
    return list;
  }

  // --- CREA CHAT (supporta description + tags) ---
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

  // --- MESSAGGI ---
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
    await supa.from('messages').insert({
      'chat_id': chatId,
      'user_id': user?.id,
      'text': text,
    });
  }

  // --- RICERCA SEMPLICE: unifica name/description/tags e restituisce una sola lista ---
  Future<List<ChatModel>> searchUnified(String query) async {
    final q = query.trim();
    if (q.isEmpty) return fetchChatsRandom();

    final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(q);

    // 1) name / id
    dynamic resTitle;
    if (isUuid) {
      resTitle = await supa.from('chats').select('*, chat_tags(tag)').eq('id', q);
    } else {
      resTitle = await supa
          .from('chats')
          .select('*, chat_tags(tag)')
          .ilike('name', '%$q%');
    }
    final titleList = (resTitle as List)
        .map((e) => ChatModel.fromMap(e as Map<String, dynamic>))
        .toList();

    // 2) description
    final resDesc = await supa
        .from('chats')
        .select('*, chat_tags(tag)')
        .ilike('description', '%$q%');
    final descList = (resDesc as List)
        .map((e) => ChatModel.fromMap(e as Map<String, dynamic>))
        .toList();

    // 3) tags → prendo ids, poi carico chats
    final resTagIds =
        await supa.from('chat_tags').select('chat_id').ilike('tag', '%$q%');
    final ids = (resTagIds as List)
        .map((e) => e['chat_id'] as String)
        .toSet()
        .toList();

    List<ChatModel> tagList = [];
    if (ids.isNotEmpty) {
      final resTags = await supa
          .from('chats')
          .select('*, chat_tags(tag)')
          .inFilter('id', ids); // <- corretto con postgrest >=2.5
      tagList = (resTags as List)
          .map((e) => ChatModel.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    // Unisco e tolgo duplicati
    final map = <String, ChatModel>{};
    for (final c in [...titleList, ...descList, ...tagList]) {
      map[c.id] = c;
    }
    final merged = map.values.toList();

    // Ordine stabile: prima quelli con nome matchato, poi description, poi tag
    merged.sort((a, b) {
      int score(ChatModel c) {
        final ql = q.toLowerCase();
        if (c.name.toLowerCase().contains(ql)) return 0;
        if ((c.description ?? '').toLowerCase().contains(ql)) return 1;
        if (c.tags.any((t) => t.contains(ql))) return 2;
        return 3;
      }
      return score(a).compareTo(score(b));
    });

    return merged;
  }
}
