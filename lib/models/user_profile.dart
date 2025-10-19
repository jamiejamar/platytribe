class UserProfile {
  final String id;
  final String username;
  final bool isGuest;
  final String? displayName;
  final String? photoUrl;
  UserProfile({required this.id, required this.username, required this.isGuest, this.displayName, this.photoUrl});
  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    id: m['id'] as String,
    username: (m['username'] as String?) ?? 'platy',
    isGuest: (m['is_guest'] as bool?) ?? false,
    displayName: m['display_name'] as String?,
    photoUrl: m['photo_url'] as String?,
  );
}
