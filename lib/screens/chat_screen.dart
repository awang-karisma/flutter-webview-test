import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/chat_user.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_input_field.dart';
import '../utils/date_formatter.dart';

/// Screen that displays a chat conversation.
class ChatScreen extends StatefulWidget {
  /// The user being chatted with.
  final ChatUser contact;

  const ChatScreen({
    super.key,
    required this.contact,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMockMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load mock messages for testing.
  void _loadMockMessages() {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.addAll(_getMockMessages());
          _isLoading = false;
        });
        _scrollToBottom();
      }
    });
  }

  /// Generate mock messages for testing.
  List<ChatMessage> _getMockMessages() {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: '1',
        text: 'Hello! Welcome to Gesit Solution. How can I help you today?',
        senderId: widget.contact.id,
        timestamp: now.subtract(const Duration(minutes: 30)),
        isSent: false,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '2',
        text: 'Hi! I need help with my account settings.',
        senderId: 'current_user',
        timestamp: now.subtract(const Duration(minutes: 28)),
        isSent: true,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '3',
        text: 'Of course! I\'d be happy to help you with your account settings. What specifically would you like to change?',
        senderId: widget.contact.id,
        timestamp: now.subtract(const Duration(minutes: 25)),
        isSent: false,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '4',
        text: 'I want to update my email address and phone number.',
        senderId: 'current_user',
        timestamp: now.subtract(const Duration(minutes: 20)),
        isSent: true,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '5',
        text: 'Great! To update your email and phone number, you can go to Settings > Account > Profile Information. From there, you can edit your contact details.',
        senderId: widget.contact.id,
        timestamp: now.subtract(const Duration(minutes: 18)),
        isSent: false,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '6',
        text: 'Would you like me to guide you through the process step by step?',
        senderId: widget.contact.id,
        timestamp: now.subtract(const Duration(minutes: 17)),
        isSent: false,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '7',
        text: 'Yes, please! That would be very helpful.',
        senderId: 'current_user',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isSent: true,
        status: MessageStatus.delivered,
      ),
    ];
  }

  /// Handle sending a new message.
  void _handleSendMessage(String text) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      senderId: 'current_user',
      timestamp: DateTime.now(),
      isSent: true,
      status: MessageStatus.sending,
    );

    setState(() {
      _messages.add(message);
    });

    _scrollToBottom();

    // Simulate message being sent
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = message.copyWith(status: MessageStatus.sent);
          }
        });

        // Simulate auto-reply
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _handleAutoReply(text);
          }
        });
      }
    });
  }

  /// Handle automatic reply for demo purposes.
  void _handleAutoReply(String userMessage) {
    final reply = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _getAutoReplyMessage(userMessage),
      senderId: widget.contact.id,
      timestamp: DateTime.now(),
      isSent: false,
      status: MessageStatus.sent,
    );

    setState(() {
      _messages.add(reply);
    });

    _scrollToBottom();
  }

  /// Get an auto-reply message based on the user's message.
  String _getAutoReplyMessage(String userMessage) {
    final replies = [
      'Thank you for your message! Our team will assist you shortly.',
      'I understand. Let me check that for you.',
      'Is there anything else I can help you with?',
      'Great question! Here\'s what you need to know...',
      'I\'ve noted your request. We\'ll process it right away.',
    ];

    // Simple keyword-based reply
    if (userMessage.toLowerCase().contains('thank')) {
      return 'You\'re welcome! Feel free to ask if you have any other questions.';
    } else if (userMessage.toLowerCase().contains('help')) {
      return 'I\'m here to help! Please tell me more about what you need.';
    }

    return replies[DateTime.now().second % replies.length];
  }

  /// Scroll to the bottom of the message list.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Handle attachment button tap.
  void _handleAttachment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attachment feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: ChatAppBar(
        contact: widget.contact,
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF667eea),
                    ),
                  )
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),
          // Input field
          ChatInputField(
            onSend: _handleSendMessage,
            onAttachmentTap: _handleAttachment,
          ),
        ],
      ),
    );
  }

  /// Build the empty state when there are no messages.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with ${widget.contact.name}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the message list with date separators.
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final showDateSeparator = index == 0 ||
            !_isSameDay(
              _messages[index - 1].timestamp,
              message.timestamp,
            );

        return Column(
          children: [
            if (showDateSeparator) _buildDateSeparator(message.timestamp),
            ChatMessageBubble(message: message),
          ],
        );
      },
    );
  }

  /// Build a date separator.
  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            DateFormatter.formatDate(date),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Check if two dates are on the same day.
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
