/// ============================================================================
/// BROADCAST STATE - ALL POSSIBLE STATES FOR BROADCAST FEATURE
/// ============================================================================

import 'package:equatable/equatable.dart';
import '../data/broadcast_list_model.dart';
import '../data/broadcast_recipient_model.dart';
import '../data/broadcast_message_model.dart';

/// Base class for all broadcast states
sealed class BroadcastState extends Equatable {
  const BroadcastState();
  
  @override
  List<Object?> get props => [];
}

// =============================================================================
// INITIAL & LOADING STATES
// =============================================================================

/// Initial state - no data loaded yet
class BroadcastInitial extends BroadcastState {
  const BroadcastInitial();
}

/// Loading broadcast lists
class BroadcastListsLoading extends BroadcastState {
  const BroadcastListsLoading();
}

/// Loading specific broadcast list details
class BroadcastListLoading extends BroadcastState {
  const BroadcastListLoading();
}

/// Loading recipients for a list
class BroadcastRecipientsLoading extends BroadcastState {
  const BroadcastRecipientsLoading();
}

/// Loading broadcast message history
class BroadcastMessagesLoading extends BroadcastState {
  const BroadcastMessagesLoading();
}

// =============================================================================
// SUCCESS STATES
// =============================================================================

/// Broadcast lists loaded successfully
class BroadcastListsLoaded extends BroadcastState {
  final List<BroadcastList> lists;
  
  const BroadcastListsLoaded(this.lists);
  
  @override
  List<Object?> get props => [lists];
}

/// Broadcast list details loaded successfully
class BroadcastListLoaded extends BroadcastState {
  final BroadcastList list;
  final List<BroadcastRecipient> recipients;
  
  const BroadcastListLoaded({
    required this.list,
    required this.recipients,
  });
  
  @override
  List<Object?> get props => [list, recipients];
}

/// Broadcast list created successfully
class BroadcastListCreateSuccess extends BroadcastState {
  final BroadcastList list;
  
  const BroadcastListCreateSuccess(this.list);
  
  @override
  List<Object?> get props => [list];
}

/// Broadcast list updated successfully
class BroadcastListUpdateSuccess extends BroadcastState {
  final BroadcastList list;
  
  const BroadcastListUpdateSuccess(this.list);
  
  @override
  List<Object?> get props => [list];
}

/// Broadcast list deleted successfully
class BroadcastListDeleteSuccess extends BroadcastState {
  final String listId;
  
  const BroadcastListDeleteSuccess(this.listId);
  
  @override
  List<Object?> get props => [listId];
}

/// Recipients loaded successfully
class BroadcastRecipientsLoaded extends BroadcastState {
  final List<BroadcastRecipient> recipients;
  
  const BroadcastRecipientsLoaded(this.recipients);
  
  @override
  List<Object?> get props => [recipients];
}

/// Recipients added successfully
class BroadcastRecipientsAddSuccess extends BroadcastState {
  final String listId;
  final int addedCount;
  
  const BroadcastRecipientsAddSuccess({
    required this.listId,
    required this.addedCount,
  });
  
  @override
  List<Object?> get props => [listId, addedCount];
}

/// Recipient removed successfully
class BroadcastRecipientRemoveSuccess extends BroadcastState {
  final String listId;
  final String recipientId;
  
  const BroadcastRecipientRemoveSuccess({
    required this.listId,
    required this.recipientId,
  });
  
  @override
  List<Object?> get props => [listId, recipientId];
}

/// Broadcast message history loaded
class BroadcastMessagesLoaded extends BroadcastState {
  final List<BroadcastMessage> messages;
  
  const BroadcastMessagesLoaded(this.messages);
  
  @override
  List<Object?> get props => [messages];
}

// =============================================================================
// SENDING STATES
// =============================================================================

/// Sending broadcast message (with progress)
class BroadcastSending extends BroadcastState {
  final int totalRecipients;
  final int sentCount;
  
  const BroadcastSending({
    required this.totalRecipients,
    this.sentCount = 0,
  });
  
  /// Get sending progress (0.0 to 1.0)
  double get progress {
    if (totalRecipients == 0) return 0.0;
    return sentCount / totalRecipients;
  }
  
  /// Get progress percentage (0 to 100)
  int get progressPercentage => (progress * 100).round();
  
  @override
  List<Object?> get props => [totalRecipients, sentCount];
}

/// Broadcast message sent successfully
class BroadcastSent extends BroadcastState {
  final BroadcastMessage message;
  final int successfulDeliveries;
  final int totalRecipients;
  
  const BroadcastSent({
    required this.message,
    required this.successfulDeliveries,
    required this.totalRecipients,
  });
  
  /// Check if all recipients received the message
  bool get isFullyDelivered => successfulDeliveries >= totalRecipients;
  
  /// Get success rate text
  String get deliveryStatusText {
    if (isFullyDelivered) {
      return 'Sent to all $totalRecipients recipients';
    }
    return 'Sent to $successfulDeliveries of $totalRecipients recipients';
  }
  
  @override
  List<Object?> get props => [message, successfulDeliveries, totalRecipients];
}

// =============================================================================
// ERROR STATES
// =============================================================================

/// Error occurred during broadcast operation
class BroadcastError extends BroadcastState {
  final String message;
  final String? errorCode;
  
  const BroadcastError({
    required this.message,
    this.errorCode,
  });
  
  @override
  List<Object?> get props => [message, errorCode];
}
