class MessageModel {
  final String id; final String chatId; final String? userId;
  final String? text; final String? mediaUrl;
  final DateTime createdAt; final DateTime? editedAt;
  MessageModel({required this.id, required this.chatId, this.userId, this.text, this.mediaUrl, required this.createdAt, this.editedAt});
  factory MessageModel.fromMap(Map<String, dynamic> m) => MessageModel(
    id: m['id'],
    chatId: m['chat_id'],
    userId: m['user_id'],
    text: m['text'],
    mediaUrl: m['media_url'],
    createdAt: DateTime.parse(m['created_at']),
    editedAt: m['edited_at']!=null?DateTime.parse(m['edited_at']):null,
  );
}
