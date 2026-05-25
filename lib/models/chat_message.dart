/// Data model for a chat message.
class ChatMessage {
  /// Unique identifier for the message.
  final String id;
  
  /// The text content of the message.
  final String text;
  
  /// ID of the user who sent the message.
  final String senderId;
  
  /// Timestamp when the message was sent.
  final DateTime timestamp;
  
  /// Whether this message was sent by the current user.
  final bool isSent;
  
  /// Current status of the message.
  final MessageStatus status;
  
  /// Optional URL for any attachment.
  final String? attachmentUrl;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    required this.isSent,
    this.status = MessageStatus.sent,
    this.attachmentUrl,
  });

  /// Create a copy of this message with updated fields.
  ChatMessage copyWith({
    String? id,
    String? text,
    String? senderId,
    DateTime? timestamp,
    bool? isSent,
    MessageStatus? status,
    String? attachmentUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      isSent: isSent ?? this.isSent,
      status: status ?? this.status,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }
}

/// Status of a chat message.
enum MessageStatus {
  /// Message is being sent.
  sending,
  
  /// Message has been sent.
  sent,
  
  /// Message has been delivered to recipient.
  delivered,
  
  /// Message has been read by recipient.
  read,
  
  /// Message failed to send.
  failed,
}
