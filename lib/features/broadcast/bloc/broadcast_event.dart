/// ============================================================================
/// BROADCAST EVENT - ALL USER ACTIONS FOR BROADCAST FEATURE
/// ============================================================================

import 'package:equatable/equatable.dart';

/// Base class for all broadcast events
sealed class BroadcastEvent extends Equatable {
  const BroadcastEvent();
  
  @override
  List<Object?> get props => [];
}

// =============================================================================
// BROADCAST LIST EVENTS
// =============================================================================

/// Event to load all broadcast lists for current user
class BroadcastListsRequested extends BroadcastEvent {
  const BroadcastListsRequested();
}

/// Event to create a new broadcast list
class BroadcastListCreated extends BroadcastEvent {
  final String name;
  final List<String> recipientIds;
  
  const BroadcastListCreated({
    required this.name,
    required this.recipientIds,
  });
  
  @override
  List<Object?> get props => [name, recipientIds];
}

/// Event to update broadcast list name
class BroadcastListUpdated extends BroadcastEvent {
  final String listId;
  final String newName;
  
  const BroadcastListUpdated({
    required this.listId,
    required this.newName,
  });
  
  @override
  List<Object?> get props => [listId, newName];
}

/// Event to delete a broadcast list
class BroadcastListDeleted extends BroadcastEvent {
  final String listId;
  
  const BroadcastListDeleted(this.listId);
  
  @override
  List<Object?> get props => [listId];
}

/// Event to load specific broadcast list details
class BroadcastListDetailsRequested extends BroadcastEvent {
  final String listId;
  
  const BroadcastListDetailsRequested(this.listId);
  
  @override
  List<Object?> get props => [listId];
}

// =============================================================================
// RECIPIENT MANAGEMENT EVENTS
// =============================================================================

/// Event to add recipients to a broadcast list
class BroadcastRecipientsAdded extends BroadcastEvent {
  final String listId;
  final List<String> recipientIds;
  
  const BroadcastRecipientsAdded({
    required this.listId,
    required this.recipientIds,
  });
  
  @override
  List<Object?> get props => [listId, recipientIds];
}

/// Event to remove a recipient from a broadcast list
class BroadcastRecipientRemoved extends BroadcastEvent {
  final String listId;
  final String recipientId;
  
  const BroadcastRecipientRemoved({
    required this.listId,
    required this.recipientId,
  });
  
  @override
  List<Object?> get props => [listId, recipientId];
}

/// Event to load recipients for a broadcast list
class BroadcastRecipientsRequested extends BroadcastEvent {
  final String listId;
  
  const BroadcastRecipientsRequested(this.listId);
  
  @override
  List<Object?> get props => [listId];
}

// =============================================================================
// BROADCAST MESSAGE EVENTS
// =============================================================================

/// Event to send a broadcast message to a list
class BroadcastMessageSent extends BroadcastEvent {
  final String listId;
  final String? message;
  final String? mediaUrl;
  
  const BroadcastMessageSent({
    required this.listId,
    this.message,
    this.mediaUrl,
  });
  
  @override
  List<Object?> get props => [listId, message, mediaUrl];
}

/// Event to load broadcast message history for a list
class BroadcastMessagesRequested extends BroadcastEvent {
  final String listId;
  
  const BroadcastMessagesRequested(this.listId);
  
  @override
  List<Object?> get props => [listId];
}

/// Event to reset broadcast state (e.g., after navigation)
class BroadcastStateReset extends BroadcastEvent {
  const BroadcastStateReset();
}
