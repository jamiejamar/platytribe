import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'supabase_singleton.dart';

class ChatService {
  Future<List<ChatModel>> fetchChats() async {
    final res = await supa.from('chats').select('*, chat_tags(tag)').order('created_at', ascending: false);
    return (res as List).map((e) => ChatModel.fromMap(e as Map<String, dynamic>)).toList();
  }
  Future<List<String>> fetchUserInterests(String userId) async {
    final res = await supa.from('user_interests').select('tag').eq('user_id', userId);
    return (res as List).map((e) => e['tag'] as String).toList();
  }
  Future<String> createChat({required String name, required List<String> tags, String? avatarUrl, String? backgroundUrl, bool isGroup=false}) async {
    final user = supa.auth.currentUser;
    final inserted = await supa.from('chats').insert({'name': name,'avatar_url': avatarUrl,'background_url': backgroundUrl,'is_group': isGroup,'created_by': user?.id,}).select().single();
    final chatId = inserted['id'] as String;
    if (tags.isNotEmpty) {
      await supa.from('chat_tags').insert(tags.map((t)=>{'chat_id': chatId, 'tag': t.trim().toLowerCase()}).toList());
    }
    return chatId;
  }
  Future<void> followChat(String chatId, {required bool follow}) async {
    final user = supa.auth.currentUser; if (user == null) return;
    if (follow) { await supa.from('chat_followers').upsert({'chat_id': chatId, 'user_id': user.id}); }
    else { await supa.from('chat_followers').delete().match({'chat_id': chatId, 'user_id': user.id}); }
  }
  Future<List<MessageModel>> fetchMessages(String chatId) async {
    final res = await supa.from('messages').select('*').eq('chat_id', chatId).order('created_at');
    return (res as List).map((e) => MessageModel.fromMap(e)).toList();
  }
  Stream<List<MessageModel>> streamMessages(String chatId) {
    final stream = supa.from('messages').stream(primaryKey: ['id']).eq('chat_id', chatId).order('created_at');
    return stream.map((rows)=>rows.map((e)=>MessageModel.fromMap(e)).toList());
  }
  Future<void> sendMessage(String chatId, String text) async {
    final user = supa.auth.currentUser;
    await supa.from('messages').insert({'chat_id': chatId, 'user_id': user?.id, 'text': text});
  }
  Future<void> saveInterests(List<String> tags) async {
    final user = supa.auth.currentUser; if (user == null) return;
    await supa.from('user_interests').delete().eq('user_id', user.id);
    if (tags.isNotEmpty) {
      await supa.from('user_interests').insert(tags.map((t)=>{'user_id': user.id, 'tag': t.trim().toLowerCase()}).toList());
    }
  }
}
