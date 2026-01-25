/// ============================================================================
/// MESSAGE BUBBLE WIDGET
/// ============================================================================
/// 
/// PURPOSE: Display individual message with sender/receiver styling
/// 
/// LEARNING: Conditional styling based on sender
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter_app/features/chat/data/message_model.dart';
import 'package:supabase_flutter_app/features/chat/utils/chat_constants.dart';
import 'package:supabase_flutter_app/features/chat/utils/chat_helpers.dart';

/// MessageBubble - Individual message display
/// 
/// **Styling based on sender:**
/// - isMe = true → Green bubble, right-aligned
/// - isMe = false → White bubble, left-aligned
/// 
/// **Message Grouping:**
/// - showAvatar = true → Show avatar (first in group)
/// - showAvatar = false → Hide avatar (grouped message)
/// 
/// **Why Grouping?**
/// Consecutive messages from same sender don't need repeated avatars.
/// This reduces visual clutter and looks cleaner (WhatsApp pattern).
/// 
/// **Example:**
/// ```
/// [Avatar] John: Hey!         ← showAvatar = true (first)
///          John: How are you? ← showAvatar = false (grouped)
///          John: What's up?   ← showAvatar = false (grouped)
/// 
/// [Avatar] You: I'm good!     ← showAvatar = true (sender changed)
/// ```
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;  // NEW: Control avatar visibility
  
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,  // Default: show avatar
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for received messages (left side)
          if (!isMe && showAvatar)
            _buildAvatar()
          else if (!isMe && !showAvatar)
            const SizedBox(width: 40), // Spacer to align grouped messages
          
          // Message bubble
          Flexible(
            child: Container(
              margin: EdgeInsets.symmetric( // Removed const
                vertical: 2, 
                horizontal: showAvatar ? 8 : 4,
              ),
              padding: ChatConstants.messagePadding,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? ChatConstants.senderBubbleColor
                    : ChatConstants.receiverBubbleColor,
                borderRadius: BorderRadius.circular(
                  ChatConstants.bubbleBorderRadius,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Message text
                  if (message.message != null && message.message!.isNotEmpty)
                    Text(
                      message.message!,
                      style: ChatConstants.messageTextStyle,
                    ),
                  
                  // Media placeholder
                  if (message.mediaUrl != null)
                    Text(
                      ChatConstants.mediaMessageText,
                      style: ChatConstants.messageTextStyle.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  
                  const SizedBox(height: 4),
                  
                  // Timestamp
                  Text(
                    ChatHelpers.formatMessageTime(message.createdAt),
                    style: ChatConstants.timestampTextStyle,
                  ),
                ],
              ),
            ),
          ),
          
          // Avatar for sent messages (right side) - optional
          // Usually we don't show avatar for own messages in chat apps
        ],
      ),
    );
  }
  
  // =========================================================================
  // AVATAR WIDGET
  // =========================================================================
  
  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFF128C7E),
      child: Text(
        message.senderId.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
