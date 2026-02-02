/// ============================================================================
/// BROADCAST MESSAGE MODEL - DATA REPRESENTATION FOR BROADCAST MESSAGES
/// ============================================================================

import 'package:equatable/equatable.dart';

/// BroadcastMessage - Represents a message sent to a broadcast list
/// 
/// **Purpose:**
/// - Track broadcast message metadata
/// - Monitor delivery statistics
/// - Show broadcast history
class BroadcastMessage extends Equatable {
  /// Unique broadcast message ID (UUID from database)
  final String id;
  
  /// Broadcast list this message was sent to
  final String broadcastListId;
  
  /// User who sent the broadcast
  final String senderId;
  
  /// Text content of the message (nullable - could be media-only)
  final String? message;
  
  /// URL to media in Supabase Storage (nullable - could be text-only)
  final String? mediaUrl;
  
  /// Total number of recipients when message was sent
  final int totalRecipients;
  
  /// How many recipients have received the message
  final int deliveredCount;
  
  /// How many recipients have read the message
  final int readCount;
  
  /// When message was created/sent
  final DateTime createdAt;
  
  /// When message was last updated
  final DateTime updatedAt;
  
  const BroadcastMessage({
    required this.id,
    required this.broadcastListId,
    required this.senderId,
    this.message,
    this.mediaUrl,
    required this.totalRecipients,
    this.deliveredCount = 0,
    this.readCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // =========================================================================
  // JSON SERIALIZATION
  // =========================================================================
  
  /// Create BroadcastMessage from JSON (from Supabase)
  factory BroadcastMessage.fromJson(Map<String, dynamic> json) {
    return BroadcastMessage(
      id: json['id'] as String,
      broadcastListId: json['broadcast_list_id'] as String,
      senderId: json['sender_id'] as String,
      message: json['message'] as String?,
      mediaUrl: json['media_url'] as String?,
      totalRecipients: json['total_recipients'] as int,
      deliveredCount: json['delivered_count'] as int? ?? 0,
      readCount: json['read_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  /// Convert BroadcastMessage to JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'broadcast_list_id': broadcastListId,
      'sender_id': senderId,
      'message': message,
      'media_url': mediaUrl,
      'total_recipients': totalRecipients,
      'delivered_count': deliveredCount,
      'read_count': readCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  // =========================================================================
  // HELPER METHODS
  // =========================================================================
  
  /// Check if this is a text message
  bool get isTextMessage => message != null && message!.isNotEmpty;
  
  /// Check if this is a media message
  bool get isMediaMessage => mediaUrl != null && mediaUrl!.isNotEmpty;
  
  /// Calculate delivery percentage
  double get deliveryPercentage {
    if (totalRecipients == 0) return 0.0;
    return (deliveredCount / totalRecipients) * 100;
  }
  
  /// Calculate read percentage
  double get readPercentage {
    if (totalRecipients == 0) return 0.0;
    return (readCount / totalRecipients) * 100;
  }
  
  /// Check if all recipients have received
  bool get isFullyDelivered => deliveredCount >= totalRecipients;
  
  /// Check if all recipients have read
  bool get isFullyRead => readCount >= totalRecipients;
  
  /// Get delivery status summary
  String get deliveryStatus {
    if (isFullyRead) return 'Read by all';
    if (isFullyDelivered) return 'Delivered to all';
    return 'Sending...';
  }
  
  /// Get delivery stats text (e.g., "Read by 8 of 12")
  String get deliveryStatsText {
    if (readCount > 0) {
      return 'Read by $readCount of $totalRecipients';
    }
    if (deliveredCount > 0) {
      return 'Delivered to $deliveredCount of $totalRecipients';
    }
    return 'Sending to $totalRecipients';
  }
  
  // =========================================================================
  // EQUATABLE
  // =========================================================================
  
  @override
  List<Object?> get props => [
        id,
        broadcastListId,
        senderId,
        message,
        mediaUrl,
        totalRecipients,
        deliveredCount,
        readCount,
        createdAt,
        updatedAt,
      ];
  
  // =========================================================================
  // COPYWITH
  // =========================================================================
  
  /// Create a copy with updated fields
  BroadcastMessage copyWith({
    String? id,
    String? broadcastListId,
    String? senderId,
    String? message,
    String? mediaUrl,
    int? totalRecipients,
    int? deliveredCount,
    int? readCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BroadcastMessage(
      id: id ?? this.id,
      broadcastListId: broadcastListId ?? this.broadcastListId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      readCount: readCount ?? this.readCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  String toString() {
    return 'BroadcastMessage(id: $id, to: $totalRecipients recipients, '
        'delivered: $deliveredCount, read: $readCount)';
  }
}
