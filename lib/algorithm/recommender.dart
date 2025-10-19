import '../models/chat.dart';
import 'dart:math';
class SimpleRecommender {
  List<ChatModel> rank(List<ChatModel> chats, {List<String> userTags = const [], int? seed}) {
    final s = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    int score(ChatModel c) {
      final tset = c.tags.map((e) => e.toLowerCase()).toSet();
      final uset = userTags.map((e) => e.toLowerCase()).toSet();
      return tset.intersection(uset).length;
    }
    final scored = chats.map((c)=> (c, score(c))).toList();
    scored.sort((a,b){
      final diff = b.$2.compareTo(a.$2);
      if (diff != 0) return diff;
      final jA = a.$1.name.hashCode ^ s.nextInt(1<<20);
      final jB = b.$1.name.hashCode ^ s.nextInt(1<<20);
      return jB.compareTo(jA);
    });
    return scored.map((e)=>e.$1).toList();
  }
}
