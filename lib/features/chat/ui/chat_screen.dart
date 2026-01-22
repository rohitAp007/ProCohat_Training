/// ============================================================================
/// CHAT SCREEN - PLACEHOLDER
/// ============================================================================
/// 
/// PURPOSE: Placeholder for actual chat screen (Day 23)
/// 
/// NOTE: Full implementation tomorrow!
///
/// ============================================================================

import 'package:flutter/material.dart';

/// ChatScreen - Placeholder for chat UI
/// 
/// **Will implement on Day 23:**
/// - Message list
/// - Input field
/// - Message bubbles
/// - Real-time updates
class ChatScreen extends StatelessWidget {
  final String otherUserId;
  final String otherUserName;
  
  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(otherUserName),
        backgroundColor: const Color(0xFF075E54),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              'Chat with $otherUserName',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming on Day 23!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text(
              'User ID: $otherUserId',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
