/// ============================================================================
/// EMPTY CHAT LIST WIDGET
/// ============================================================================
/// 
/// PURPOSE: Show when no users exist
/// 
/// PATTERN: Empty state widget
///
/// ============================================================================

import 'package:flutter/material.dart';

/// EmptyChatList - Empty state for chat list
class EmptyChatList extends StatelessWidget {
  const EmptyChatList({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No users yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite friends to start chatting!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
