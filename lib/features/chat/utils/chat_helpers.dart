/// ============================================================================
/// CHAT HELPERS - UTILITY FUNCTIONS FOR CHAT FEATURE
/// ============================================================================
/// 
/// PURPOSE: Reusable helper functions for chat
/// 
/// USE IN: Week 2 UI implementation
///
/// ============================================================================

import 'package:intl/intl.dart';
import 'chat_constants.dart';

/// ChatHelpers - Utility functions for chat feature
class ChatHelpers {
  // Private constructor
  ChatHelpers._();
  
  // =========================================================================
  // TIMESTAMP FORMATTING
  // =========================================================================
  
  /// Format timestamp for message (e.g., "2:30 PM")
  /// 
  /// **Example:**
  /// ```dart
  /// final time = ChatHelpers.formatMessageTime(message.createdAt);
  /// // "2:30 PM"
  /// ```
  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    // If today, show time only
    if (difference.inDays == 0) {
      return DateFormat(ChatConstants.timeFormat).format(dateTime);
    }
    
    // If yesterday, show "Yesterday"
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    
    // If within week, show day name (e.g., "Monday")
    if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    }
    
    // Older: show date (e.g., "Jan 15")
    return DateFormat('MMM d').format(dateTime);
  }
  
  /// Format timestamp for chat list (shorter format)
  /// 
  /// **Example:**
  /// ```dart
  /// final time = ChatHelpers.formatChatListTime(chat.lastMessageAt);
  /// // "2:30 PM" or "Yesterday" or "Jan 15"
  /// ```
  static String formatChatListTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );
    final difference = today.difference(messageDate).inDays;
    
    // Today: show time
    if (difference == 0) {
      return DateFormat(ChatConstants.timeFormat).format(dateTime);
    }
    
    // Yesterday
    if (difference == 1) {
      return 'Yesterday';
    }
    
    // This week: show day
    if (difference < 7) {
      return DateFormat('EEE').format(dateTime);
    }
    
    // Older: show date
    return DateFormat('MMM d').format(dateTime);
  }
  
  /// Get date separator text (e.g., "Today", "Yesterday", "Jan 15, 2026")
  /// 
  /// **Used for**: Date separators between messages
  static String getDateSeparator(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );
    final difference = today.difference(messageDate).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    
    return DateFormat(ChatConstants.dateFormat).format(dateTime);
  }
  
  // =========================================================================
  // MESSAGE VALIDATION
  // =========================================================================
  
  /// Validate message text
  /// 
  /// **Returns**: Error message or null if valid
  /// 
  /// **Example:**
  /// ```dart
  /// final error = ChatHelpers.validateMessage(text);
  /// if (error != null) {
  ///   showError(error);
  ///   return;
  /// }
  /// ```
  static String? validateMessage(String text) {
    // Check if empty
    if (text.trim().isEmpty) {
      return ChatConstants.emptyMessageError;
    }
    
    // Check length
    if (text.length > ChatConstants.maxMessageLength) {
      return ChatConstants.messageTooLongError;
    }
    
    return null;  // Valid!
  }
  
  /// Check if text is only whitespace
  static bool isWhitespace(String text) {
    return text.trim().isEmpty;
  }
  
  /// Get character count with limit indicator
  /// 
  /// **Example:**
  /// ```dart
  /// final count = ChatHelpers.getCharacterCount(text);
  /// // "450/5000"
  /// ```
  static String getCharacterCount(String text) {
    final count = text.length;
    final max = ChatConstants.maxMessageLength;
    return '$count/$max';
  }
  
  // =========================================================================
  // MESSAGE GROUPING
  // =========================================================================
  
  /// Check if messages should be grouped (same sender, close timing)
  /// 
  /// **Use**: To show/hide avatar and sender name
  /// 
  /// **Example:**
  /// ```dart
  /// final shouldGroup = ChatHelpers.shouldGroupMessages(
  ///   previous: previousMessage,
  ///   current: currentMessage,
  /// );
  /// ```
  static bool shouldGroupMessages({
    required dynamic previous,
    required dynamic current,
  }) {
    // Different senders: don't group
    if (previous.senderId != current.senderId) {
      return false;
    }
    
    // Too much time between: don't group (> 5 minutes)
    final timeDiff = current.createdAt.difference(previous.createdAt);
    if (timeDiff.inMinutes > 5) {
      return false;
    }
    
    return true;  // Group them!
  }
  
  /// Check if date separator is needed between messages
  static bool needsDateSeparator({
    required DateTime? previousDate,
    required DateTime currentDate,
  }) {
    if (previousDate == null) return true;
    
    final prev = DateTime(
      previousDate.year,
      previousDate.month,
      previousDate.day,
    );
    final curr = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    
    return !prev.isAtSameMomentAs(curr);
  }
  
  // =========================================================================
  // TEXT PROCESSING
  // =========================================================================
  
  /// Truncate text with ellipsis
  /// 
  /// **Example:**
  /// ```dart
  /// final preview = ChatHelpers.truncateText(
  ///   'This is a very long message...',
  ///   maxLength: 50,
  /// );
  /// // "This is a very long message..."
  /// ```
  static String truncateText(String text, {int maxLength = 50}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  /// Get initials from name
  /// 
  /// **Example:**
  /// ```dart
  /// final initials = ChatHelpers.getInitials('John Doe');
  /// // "JD"
  /// ```
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
  
  // =========================================================================
  // FILE VALIDATION
  // =========================================================================
  
  /// Validate media file size
  /// 
  /// **Returns**: Error message or null if valid
  static String? validateMediaSize(int sizeInBytes) {
    if (sizeInBytes > ChatConstants.maxMediaSizeBytes) {
      return ChatConstants.mediaTooLargeError;
    }
    return null;
  }
  
  /// Format file size for display
  /// 
  /// **Example:**
  /// ```dart
  /// final size = ChatHelpers.formatFileSize(1024 * 1024 * 2.5);
  /// // "2.5 MB"
  /// ```
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================
//
// 1. FORMAT TIME:
// ```dart
// Text(ChatHelpers.formatMessageTime(message.createdAt))
// ```
//
// 2. VALIDATE:
// ```dart
// final error = ChatHelpers.validateMessage(textController.text);
// if (error != null) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(content: Text(error)),
//   );
//   return;
// }
// ```
//
// 3. GROUP MESSAGES:
// ```dart
// final showAvatar = !ChatHelpers.shouldGroupMessages(
//   previous: messages[index + 1],
//   current: messages[index],
// );
// ```
//
// 4. DATE SEPARATOR:
// ```dart
// if (ChatHelpers.needsDateSeparator(
//   previousDate: previousMessage?.createdAt,
//   currentDate: currentMessage.createdAt,
// )) {
//   return DateSeparatorWidget(
//     text: ChatHelpers.getDateSeparator(currentMessage.createdAt),
//   );
// }
// ```
//
// ============================================================================
