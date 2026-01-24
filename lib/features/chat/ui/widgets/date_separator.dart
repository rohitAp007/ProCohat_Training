/// ============================================================================
/// DATE SEPARATOR WIDGET
/// ============================================================================
/// 
/// PURPOSE: Show date labels between message groups
/// 
/// LEARNING: How to display timeline markers in chat
///
/// **Why we need this:**
/// - Helps users track conversation timeline
/// - Groups messages by day
/// - WhatsApp-style UX pattern
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter_app/features/chat/utils/chat_helpers.dart';

/// DateSeparator - Shows date label between messages
/// 
/// **Displays:**
/// - "Today" (if today)
/// - "Yesterday" (if yesterday)
/// - "Jan 24, 2026" (for older dates)
/// 
/// **Usage:**
/// ```dart
/// ListView.builder(
///   itemBuilder: (context, index) {
///     final message = messages[index];
///     final previousMessage = index < messages.length - 1 
///         ? messages[index + 1] 
///         : null;
///     
///     // Show date separator if day changed
///     if (ChatHelpers.needsDateSeparator(
///       previousDate: previousMessage?.createdAt,
///       currentDate: message.createdAt,
///     )) {
///       return DateSeparator(date: message.createdAt);
///     }
///   },
/// )
/// ```
class DateSeparator extends StatelessWidget {
  final DateTime date;
  
  const DateSeparator({
    super.key,
    required this.date,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[700]!.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          ChatHelpers.getDateSeparator(date),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// **Senior Explanation:**
/// 
/// "The DateSeparator widget shows date labels between messages to help users
/// track the conversation timeline. It uses ChatHelpers.getDateSeparator() 
/// to format dates as 'Today', 'Yesterday', or specific dates.
/// 
/// We check if a date separator is needed by comparing the day of consecutive
/// messages. If the day changes, we insert a DateSeparator widget.
/// 
/// This is a common pattern in messaging apps (WhatsApp, Telegram) and 
/// significantly improves UX by providing temporal context."
