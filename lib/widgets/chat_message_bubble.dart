import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../utils/date_formatter.dart';

/// Widget that displays a single chat message bubble.
class ChatMessageBubble extends StatelessWidget {
  /// The message to display.
  final ChatMessage message;
  
  /// Whether to show the timestamp.
  final bool showTimestamp;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    final isSent = message.isSent;
    
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSent 
              ? const Color(0xFF667eea) 
              : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isSent ? 16 : 4),
            bottomRight: Radius.circular(isSent ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isSent ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (showTimestamp) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormatter.formatTime(message.timestamp),
                    style: TextStyle(
                      color: isSent 
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  if (isSent) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(message.status, isSent),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build the status indicator icon for sent messages.
  Widget _buildStatusIcon(MessageStatus status, bool isSent) {
    IconData iconData;
    Color color;
    double size = 14;

    switch (status) {
      case MessageStatus.sending:
        iconData = Icons.access_time;
        color = Colors.white.withValues(alpha: 0.7);
        break;
      case MessageStatus.sent:
        iconData = Icons.check;
        color = Colors.white.withValues(alpha: 0.7);
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all;
        color = Colors.white.withValues(alpha: 0.7);
        break;
      case MessageStatus.read:
        iconData = Icons.done_all;
        color = Colors.white.withValues(alpha: 0.9);
        break;
      case MessageStatus.failed:
        iconData = Icons.error_outline;
        color = Colors.red[300]!;
        size = 16;
        break;
    }

    return Icon(
      iconData,
      size: size,
      color: color,
    );
  }
}
