/// ============================================================================
/// BROADCAST LIST MODEL - DATA REPRESENTATION FOR BROADCAST LISTS
/// ============================================================================

import 'package:equatable/equatable.dart';

/// BroadcastList - Represents a WhatsApp-style broadcast list
/// 
/// **Purpose:**
/// - Group contacts for sending broadcast messages
/// - Track broadcast metadata
/// - Show broadcast history
class BroadcastList extends Equatable {
  /// Unique broadcast list ID (UUID from database)
  final String id;
  
  /// User who owns/created this list
  final String ownerId;
  
  /// Name of the broadcast list (e.g., "Team Updates", "Family")
  final String name;
  
  /// Number of recipients in this list (cached for performance)
  final int recipientCount;
  
  /// When last broadcast message was sent (nullable - new lists)
  final DateTime? lastBroadcastAt;
  
  /// When list was created
  final DateTime createdAt;
  
  /// When list was last updated
  final DateTime updatedAt;
  
  const BroadcastList({
    required this.id,
    required this.ownerId,
    required this.name,
    this.recipientCount = 0,
    this.lastBroadcastAt,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // =========================================================================
  // JSON SERIALIZATION
  // =========================================================================
  
  /// Create BroadcastList from JSON (from Supabase)
  factory BroadcastList.fromJson(Map<String, dynamic> json) {
    return BroadcastList(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      recipientCount: json['recipient_count'] as int? ?? 0,
      lastBroadcastAt: json['last_broadcast_at'] != null
          ? DateTime.parse(json['last_broadcast_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  /// Convert BroadcastList to JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'recipient_count': recipientCount,
      'last_broadcast_at': lastBroadcastAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  // =========================================================================
  // HELPER METHODS
  // =========================================================================
  
  /// Check if user owns this list
  bool isOwnedBy(String userId) => ownerId == userId;
  
  /// Check if list has recipients
  bool get hasRecipients => recipientCount > 0;
  
  /// Check if list has been used (any broadcasts sent)
  bool get hasBeenUsed => lastBroadcastAt != null;
  
  // =========================================================================
  // EQUATABLE
  // =========================================================================
  
  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        recipientCount,
        lastBroadcastAt,
        createdAt,
        updatedAt,
      ];
  
  // =========================================================================
  // COPYWITH
  // =========================================================================
  
  /// Create a copy with updated fields
  BroadcastList copyWith({
    String? id,
    String? ownerId,
    String? name,
    int? recipientCount,
    DateTime? lastBroadcastAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BroadcastList(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      recipientCount: recipientCount ?? this.recipientCount,
      lastBroadcastAt: lastBroadcastAt ?? this.lastBroadcastAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  String toString() {
    return 'BroadcastList(id: $id, name: $name, recipients: $recipientCount)';
  }
}
