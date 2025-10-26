class ChatModel {
  final String id;
  final String name;
  final String? description;           // NEW
  final String? avatarUrl;
  final String? backgroundUrl;
  final bool isGroup;
  final String? createdBy;
  final DateTime createdAt;
  final List<String> tags;

  ChatModel({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.backgroundUrl,
    required this.isGroup,
    this.createdBy,
    required this.createdAt,
    required this.tags,
  });

  factory ChatModel.fromMap(Map<String, dynamic> m) => ChatModel(
        id: m['id'],
        name: m['name'],
        description: m['description'], // NEW
        avatarUrl: m['avatar_url'],
        backgroundUrl: m['background_url'],
        isGroup: (m['is_group'] ?? false) as bool,
        createdBy: m['created_by'],
        createdAt: DateTime.parse(m['created_at']),
        tags: (m['chat_tags'] as List?)
                ?.map((e) => e['tag'] as String)
                .toList() ??
            const [],
      );
}
