/// ============================================================================
/// CHAT METADATA MODEL - Unread counts and last message info
/// ============================================================================

import 'package:equatable/equatable.dart';

/// ChatMetadata - Stores metadata about a chat conversation
/// 
/// Contains:
/// - Unread message counts for each user
/// - Last message preview and timestamp
/// - Last read timestamps
class ChatMetadata extends Equatable {
  final String chatId;
  final int user1UnreadCount;
  final int user2UnreadCount;
  final DateTime? user1LastRead;
  final DateTime? user2LastRead;
  final String? lastMessageId;
  final String? lastMessagePreview;
  final DateTime? lastMessageTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatMetadata({
    required this.chatId,
    this.user1UnreadCount = 0,
    this.user2UnreadCount = 0,
    this.user1LastRead,
    this.user2LastRead,
    this.lastMessageId,
    this.lastMessagePreview,
    this.lastMessageTime,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get unread count for a specific user
  int getUnreadCount(String userId, String user1Id, String user2Id) {
    if (userId == user1Id) return user1UnreadCount;
    if (userId == user2Id) return user2UnreadCount;
    return 0;
  }

  factory ChatMetadata.fromJson(Map<String, dynamic> json) {
    return ChatMetadata(
      chatId: json['chat_id'] as String,
      user1UnreadCount: (json['user1_unread_count'] as int?) ?? 0,
      user2UnreadCount: (json['user2_unread_count'] as int?) ?? 0,
      user1LastRead: json['user1_last_read'] != null
          ? DateTime.parse(json['user1_last_read'] as String)
          : null,
      user2LastRead: json['user2_last_read'] != null
          ? DateTime.parse(json['user2_last_read'] as String)
          : null,
      lastMessageId: json['last_message_id'] as String?,
      lastMessagePreview: json['last_message_preview'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'user1_unread_count': user1UnreadCount,
      'user2_unread_count': user2UnreadCount,
      'user1_last_read': user1LastRead?.toIso8601String(),
      'user2_last_read': user2LastRead?.toIso8601String(),
      'last_message_id': lastMessageId,
      'last_message_preview': lastMessagePreview,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        chatId,
        user1UnreadCount,
        user2UnreadCount,
        user1LastRead,
        user2LastRead,
        lastMessageId,
        lastMessagePreview,
        lastMessageTime,
      ];
}
