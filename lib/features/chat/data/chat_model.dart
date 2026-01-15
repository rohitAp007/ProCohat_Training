/// ============================================================================
/// CHAT MODEL - DATA REPRESENTATION FOR CONVERSATIONS
/// ============================================================================
/// 
/// PURPOSE: Represent a conversation between two users
/// 
/// LEARNING OBJECTIVES:
/// 1. Chat metadata modeling
/// 2. Participant handling
/// 3. Last message preview pattern
///
/// ============================================================================

import 'package:equatable/equatable.dart';

/// Chat - Represents a conversation between two users
/// 
/// **Purpose:**
/// - Fast "chat list" queries
/// - Show last message preview
/// - Track conversation metadata
/// 
/// **Key Concept:**
/// One chat per user pair (enforced by database UNIQUE constraint)
class Chat extends Equatable {
  /// Unique chat ID (deterministic from user IDs)
  /// Generated using: sorted user IDs → hash
  final String id;
  
  /// First participant (alphabetically sorted)
  final String user1Id;
  
  /// Second participant (alphabetically sorted)
  final String user2Id;
  
  /// Last message text (for preview)
  final String? lastMessage;
  
  /// When last message was sent
  final DateTime? lastMessageAt;
  
  /// When chat was created
  final DateTime createdAt;
  
  /// When chat was last updated
  final DateTime updatedAt;
  
  /// Constructor
  const Chat({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // =========================================================================
  // JSON SERIALIZATION
  // =========================================================================
  
  /// Create Chat from JSON (from Supabase)
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  /// Convert Chat to JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  // =========================================================================
  // HELPER METHODS
  // =========================================================================
  
  /// Get the other participant's ID
  /// 
  /// **Example:**
  /// ```dart
  /// final otherUserId = chat.getOtherUserId(currentUserId);
  /// ```
  String getOtherUserId(String currentUserId) {
    return user1Id == currentUserId ? user2Id : user1Id;
  }
  
  /// Check if user is participant
  bool hasParticipant(String userId) {
    return user1Id == userId || user2Id == userId;
  }
  
  /// Check if chat has any messages
  bool get hasMessages => lastMessage != null;
  
  // =========================================================================
  // EQUATABLE
  // =========================================================================
  
  @override
  List<Object?> get props => [
        id,
        user1Id,
        user2Id,
        lastMessage,
        lastMessageAt,
        createdAt,
        updatedAt,
      ];
  
  // =========================================================================
  // COPYWITH
  // =========================================================================
  
  /// Create a copy with updated fields
  /// 
  /// **Used for:**
  /// - Update last message
  /// - Update timestamps
  Chat copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    String? lastMessage,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  String toString() {
    return 'Chat(id: $id, users: [$user1Id, $user2Id], '
        'lastMessage: ${lastMessage?.substring(0, lastMessage!.length > 20 ? 20 : lastMessage!.length) ?? 'none'})';
  }
}
