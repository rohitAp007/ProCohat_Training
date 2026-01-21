/// ============================================================================
/// CHAT CONSTANTS - UI & BUSINESS LOGIC CONSTANTS
/// ============================================================================
/// 
/// PURPOSE: Centralized constants for chat feature
/// 
/// USE IN: Week 2 UI implementation
///
/// ============================================================================

import 'package:flutter/material.dart';

/// ChatConstants - All constants for chat feature
class ChatConstants {
  // Private constructor to prevent instantiation
  ChatConstants._();
  
  // =========================================================================
  // MESSAGE LIMITS
  // =========================================================================
  
  /// Maximum message length (characters)
  static const int maxMessageLength = 5000;
  
  /// Maximum messages to load per page
  static const int messagesPerPage = 50;
  
  /// Maximum file size for media (5MB)
  static const int maxMediaSizeBytes = 5 * 1024 * 1024;
  
  // =========================================================================
  // COLORS (WhatsApp Style)
  // =========================================================================
  
  /// Sender message bubble color (own messages)
  static const Color senderBubbleColor = Color(0xFFDCF8C6);
  
  /// Receiver message bubble color (other user's messages)
  static const Color receiverBubbleColor = Color(0xFFFFFFFF);
  
  /// Chat background color (light)
  static const Color chatBackgroundLight = Color(0xFFECE5DD);
  
  /// Chat background color (dark)
  static const Color chatBackgroundDark = Color(0xFF0D1418);
  
  /// Message timestamp color
  static const Color timestampColor = Color(0xFF667781);
  
  /// Sending indicator color
  static const Color sendingColor = Color(0xFF8696A0);
  
  /// Delivered/read color (WhatsApp blue)
  static const Color deliveredColor = Color(0xFF53BDEB);
  
  // =========================================================================
  // SPACING
  // =========================================================================
  
  /// Message bubble padding
  static const EdgeInsets messagePadding = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 8.0,
  );
  
  /// Space between messages
  static const double messageSpacing = 4.0;
  
  /// Space between different sender messages
  static const double senderChangeSpacing = 12.0;
  
  /// Message bubble border radius
  static const double bubbleBorderRadius = 8.0;
  
  /// Message bubble tail size
  static const double bubbleTailSize = 6.0;
  
  // =========================================================================
  // ANIMATIONS
  // =========================================================================
  
  /// Message send animation duration
  static const Duration sendAnimationDuration = Duration(milliseconds: 200);
  
  /// Message appear animation duration
  static const Duration appearAnimationDuration = Duration(milliseconds: 150);
  
  /// Typing indicator animation duration
  static const Duration typingAnimationDuration = Duration(milliseconds: 500);
  
  // =========================================================================
  // TEXT STYLES
  // =========================================================================
  
  /// Message text style
  static const TextStyle messageTextStyle = TextStyle(
    fontSize: 16.0,
    color: Colors.black87,
  );
  
  /// Timestamp text style
  static const TextStyle timestampTextStyle = TextStyle(
    fontSize: 11.0,
    color: timestampColor,
  );
  
  /// Date separator text style
  static const TextStyle dateSeparatorTextStyle = TextStyle(
    fontSize: 12.0,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );
  
  // =========================================================================
  // UI STRINGS
  // =========================================================================
  
  /// Typing indicator text
  static const String typingText = 'typing...';
  
  /// Empty chat message
  static const String emptyChatMessage = 'No messages yet';
  
  /// Empty chat subtitle
  static const String emptyChatSubtitle = 'Start a conversation!';
  
  /// Message input hint
  static const String messageInputHint = 'Type a message';
  
  /// Media message placeholder
  static const String mediaMessageText = '📷 Photo';
  
  /// Deleted message text
  static const String deletedMessageText = 'This message was deleted';
  
  // =========================================================================
  // ERROR MESSAGES
  // =========================================================================
  
  /// Message too long error
  static const String messageTooLongError = 
      'Message is too long (max $maxMessageLength characters)';
  
  /// Empty message error
  static const String emptyMessageError = 'Message cannot be empty';
  
  /// Media too large error
  static const String mediaTooLargeError = 
      'File is too large (max 5MB)';
  
  /// Network error
  static const String networkError = 
      'No internet connection. Please check your network.';
  
  /// Send failed error
  static const String sendFailedError = 'Failed to send message';
  
  // =========================================================================
  // DATE FORMATS
  // =========================================================================
  
  /// Time format (e.g., "2:30 PM")
  static const String timeFormat = 'h:mm a';
  
  /// Date format (e.g., "Jan 21, 2026")
  static const String dateFormat = 'MMM d, y';
  
  /// Full date time format
  static const String fullDateTimeFormat = 'MMM d, y h:mm a';
  
  // =========================================================================
  // REALTIME
  // =========================================================================
  
  /// Realtime reconnection delay
  static const Duration reconnectDelay = Duration(seconds: 2);
  
  /// Maximum reconnection attempts
  static const int maxReconnectAttempts = 5;
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================
//
// 1. MESSAGE BUBBLE:
// ```dart
// Container(
//   padding: ChatConstants.messagePadding,
//   decoration: BoxDecoration(
//     color: isSender 
//         ? ChatConstants.senderBubbleColor
//         : ChatConstants.receiverBubbleColor,
//     borderRadius: BorderRadius.circular(
//       ChatConstants.bubbleBorderRadius,
//     ),
//   ),
//   child: Text(
//     message.text,
//     style: ChatConstants.messageTextStyle,
//   ),
// )
// ```
//
// 2. VALIDATION:
// ```dart
// if (text.length > ChatConstants.maxMessageLength) {
//   showError(ChatConstants.messageTooLongError);
// }
// ```
//
// 3. COLORS:
// ```dart
// Container(
//   color: ChatConstants.chatBackgroundLight,
//   child: ChatView(),
// )
// ```
//
// ============================================================================
