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
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });
  
  @override
  Widget build(BuildContext context) {
    return Align(
      // Right for sender, left for receiver
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: ChatConstants.messagePadding,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? ChatConstants.senderBubbleColor
              : ChatConstants.receiverBubbleColor,
          borderRadius: BorderRadius.circular(ChatConstants.bubbleBorderRadius),
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
    );
  }
}
