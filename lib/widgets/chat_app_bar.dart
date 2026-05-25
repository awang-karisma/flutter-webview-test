import 'package:flutter/material.dart';
import '../models/chat_user.dart';

/// Custom app bar for the chat screen.
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The user being chatted with.
  final ChatUser contact;
  
  /// Callback when back button is tapped.
  final VoidCallback? onBackTap;
  
  /// Callback when call button is tapped.
  final VoidCallback? onCallTap;
  
  /// Callback when video call button is tapped.
  final VoidCallback? onVideoTap;
  
  /// Callback when more options button is tapped.
  final VoidCallback? onMoreTap;

  const ChatAppBar({
    super.key,
    required this.contact,
    this.onBackTap,
    this.onCallTap,
    this.onVideoTap,
    this.onMoreTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF667eea),
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackTap ?? () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: contact.avatarUrl != null
                ? NetworkImage(contact.avatarUrl!)
                : null,
            child: contact.avatarUrl == null
                ? Text(
                    contact.name.isNotEmpty
                        ? contact.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  contact.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (onCallTap != null)
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: onCallTap,
          ),
        if (onVideoTap != null)
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: onVideoTap,
          ),
        if (onMoreTap != null)
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: onMoreTap,
          ),
      ],
    );
  }
}
