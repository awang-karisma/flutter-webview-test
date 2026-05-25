/// Data model for a chat user.
class ChatUser {
  /// Unique identifier for the user.
  final String id;
  
  /// Display name of the user.
  final String name;
  
  /// Optional URL for the user's avatar image.
  final String? avatarUrl;
  
  /// Whether the user is currently online.
  final bool isOnline;

  const ChatUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
  });

  /// Create a copy of this user with updated fields.
  ChatUser copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isOnline,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
