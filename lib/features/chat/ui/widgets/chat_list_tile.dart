/// ============================================================================
/// CHAT LIST TILE - SINGLE CHAT ITEM WIDGET
/// ============================================================================
/// 
/// PURPOSE: Display individual chat/user in list
/// 
/// PATTERN: Reusable widget component
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter_app/features/profile/data/profile_model.dart';
import 'package:supabase_flutter_app/features/chat/utils/chat_helpers.dart';

/// ChatListTile - Individual chat item
/// 
/// **Displays:**
/// - User avatar/initials
/// - User name
/// - Last message (placeholder for now)
/// - Timestamp (placeholder for now)
class ChatListTile extends StatelessWidget {
  final Profile user;
  final VoidCallback onTap;
  
  const ChatListTile({
    super.key,
    required this.user,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(),
            
            const SizedBox(width: 12),
            
            // Content (name + last message)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Last message (placeholder)
                  Text(
                    'Tap to start chatting',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Timestamp (placeholder)
            const SizedBox(width: 8),
            
            Text(
              '', // Later: show timestamp
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // =========================================================================
  // AVATAR
  // =========================================================================
  
  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFF128C7E), // WhatsApp teal
      backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
          ? NetworkImage(user.avatarUrl!)
          : null,
      child: user.avatarUrl == null || user.avatarUrl!.isEmpty
          ? Text(
              ChatHelpers.getInitials(user.fullName),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

// ============================================================================
// USAGE
// ============================================================================
//
// ```dart
// ChatListTile(
//   user: profile,
//   onTap: () {
//     // Navigate to chat
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ChatScreen(user: profile),
//       ),
//     );
//   },
// )
// ```
//
// ============================================================================
