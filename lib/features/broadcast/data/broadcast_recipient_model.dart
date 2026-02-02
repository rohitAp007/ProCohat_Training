/// ============================================================================
/// BROADCAST RECIPIENT MODEL - DATA REPRESENTATION FOR LIST RECIPIENTS
/// ============================================================================

import 'package:equatable/equatable.dart';

/// BroadcastRecipient - Represents a recipient in a broadcast list
/// 
/// **Purpose:**
/// - Link users to broadcast lists (many-to-many)
/// - Cache recipient display info for performance
/// - Track when recipient was added
class BroadcastRecipient extends Equatable {
  /// Unique recipient entry ID (UUID from database)
  final String id;
  
  /// Broadcast list this recipient belongs to
  final String broadcastListId;
  
  /// User ID of the recipient
  final String recipientId;
  
  /// Recipient's display name (cached from profiles table)
  final String? recipientName;
  
  /// Recipient's avatar URL (cached from profiles table)
  final String? recipientAvatar;
  
  /// When recipient was added to the list
  final DateTime addedAt;
  
  const BroadcastRecipient({
    required this.id,
    required this.broadcastListId,
    required this.recipientId,
    this.recipientName,
    this.recipientAvatar,
    required this.addedAt,
  });
  
  // =========================================================================
  // JSON SERIALIZATION
  // =========================================================================
  
  /// Create BroadcastRecipient from JSON (from Supabase)
  factory BroadcastRecipient.fromJson(Map<String, dynamic> json) {
    return BroadcastRecipient(
      id: json['id'] as String,
      broadcastListId: json['broadcast_list_id'] as String,
      recipientId: json['recipient_id'] as String,
      recipientName: json['recipient_name'] as String?,
      recipientAvatar: json['recipient_avatar'] as String?,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }
  
  /// Convert BroadcastRecipient to JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'broadcast_list_id': broadcastListId,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'recipient_avatar': recipientAvatar,
      'added_at': addedAt.toIso8601String(),
    };
  }
  
  // =========================================================================
  // HELPER METHODS
  // =========================================================================
  
  /// Get display name (fallback to ID if name not cached)
  String get displayName => recipientName ?? 'User $recipientId';
  
  /// Check if recipient has avatar
  bool get hasAvatar => recipientAvatar != null && recipientAvatar!.isNotEmpty;
  
  // =========================================================================
  // EQUATABLE
  // =========================================================================
  
  @override
  List<Object?> get props => [
        id,
        broadcastListId,
        recipientId,
        recipientName,
        recipientAvatar,
        addedAt,
      ];
  
  // =========================================================================
  // COPYWITH
  // =========================================================================
  
  /// Create a copy with updated fields
  BroadcastRecipient copyWith({
    String? id,
    String? broadcastListId,
    String? recipientId,
    String? recipientName,
    String? recipientAvatar,
    DateTime? addedAt,
  }) {
    return BroadcastRecipient(
      id: id ?? this.id,
      broadcastListId: broadcastListId ?? this.broadcastListId,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      recipientAvatar: recipientAvatar ?? this.recipientAvatar,
      addedAt: addedAt ?? this.addedAt,
    );
  }
  
  @override
  String toString() {
    return 'BroadcastRecipient(id: $id, name: ${recipientName ?? 'unknown'})';
  }
}
