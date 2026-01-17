/// ============================================================================
/// CHAT EVENTS - USER ACTIONS FOR MESSAGING
/// ============================================================================
/// 
/// PURPOSE: Define all possible user actions in chat
/// 
/// PATTERN: Same as ProfileEvent (you built this!)
///
/// ============================================================================

import 'package:equatable/equatable.dart';
import 'package:supabase_flutter_app/features/chat/data/message_model.dart';

/// ChatEvent - Base class for all chat events
/// 
/// **Pattern:** Sealed class (sealed modifier coming in Dart 3)
/// For now: Abstract class
/// 
/// **Why Equatable?**
/// - BLoC can compare events
/// - Prevents duplicate processing
/// - Testability
sealed class ChatEvent extends Equatable {
  const ChatEvent();
  
  @override
  List<Object?> get props => [];
}

// ============================================================================
// LOAD EVENTS
// ============================================================================

/// Load chat history
/// 
/// **When:** User opens chat screen
/// 
/// **What happens:**
/// 1. Emit ChatLoading
/// 2. Fetch chat history from repository
/// 3. Emit ChatLoaded with messages
/// 
/// **Example:**
/// ```dart
/// context.read<ChatBloc>().add(
///   ChatHistoryLoadRequested(
///     chatId: chatId,
///     otherUserId: otherUser.id,
///   ),
/// );
/// ```
class ChatHistoryLoadRequested extends ChatEvent {
  final String chatId;
  final String otherUserId;
  
  const ChatHistoryLoadRequested({
    required this.chatId,
    required this.otherUserId,
  });
  
  @override
  List<Object?> get props => [chatId, otherUserId];
}

/// Load more messages (pagination)
/// 
/// **When:** User scrolls to top of chat
/// 
/// **What happens:**
/// 1. Emit ChatLoadingMore
/// 2. Fetch older messages (before earliest)
/// 3. Emit ChatLoaded with prepended messages
/// 
/// **Example:**
/// ```dart
/// context.read<ChatBloc>().add(
///   ChatLoadMoreRequested(
///     chatId: chatId,
///     before: messages.last.createdAt,
///   ),
/// );
/// ```
class ChatLoadMoreRequested extends ChatEvent {
  final String chatId;
  final DateTime before;  // Load messages before this timestamp
  
  const ChatLoadMoreRequested({
    required this.chatId,
    required this.before,
  });
  
  @override
  List<Object?> get props => [chatId, before];
}

// ============================================================================
// SEND/RECEIVE EVENTS
// ============================================================================

/// Send a message
/// 
/// **When:** User clicks send button
/// 
/// **What happens:**
/// 1. Optimistic update (add to UI immediately)
/// 2. Emit ChatMessageSending
/// 3. Call repository.sendMessage()
/// 4. Emit ChatLoaded with confirmed message
/// 
/// **Example:**
/// ```dart
/// context.read<ChatBloc>().add(
///   ChatMessageSendRequested(
///     text: 'Hello!',
///     receiverId: otherUser.id,
///   ),
/// );
/// ```
class ChatMessageSendRequested extends ChatEvent {
  final String? text;
  final String? mediaUrl;
  final String receiverId;
  
  const ChatMessageSendRequested({
    this.text,
    this.mediaUrl,
    required this.receiverId,
  });
  
  @override
  List<Object?> get props => [text, mediaUrl, receiverId];
}

/// Receive a message (from realtime)
/// 
/// **When:** Other user sends message
/// 
/// **What happens:**
/// 1. Add to message list
/// 2. Check for duplicates
/// 3. Emit ChatLoaded with new message
/// 
/// **Example:**
/// ```dart
/// // From realtime stream (Day 20)
/// bloc.add(ChatMessageReceived(message: message));
/// ```
class ChatMessageReceived extends ChatEvent {
  final Message message;
  
  const ChatMessageReceived({
    required this.message,
  });
  
  @override
  List<Object?> get props => [message];
}

// ============================================================================
// UPDATE/DELETE EVENTS
// ============================================================================

/// Update (edit) a message
/// 
/// **When:** User edits sent message
/// 
/// **What happens:**
/// 1. Call repository.updateMessage()
/// 2. Update in local list
/// 3. Emit ChatLoaded
/// 
/// **Example:**
/// ```dart
/// context.read<ChatBloc>().add(
///   ChatMessageUpdateRequested(
///     messageId: message.id,
///     newText: 'Edited message',
///   ),
/// );
/// ```
class ChatMessageUpdateRequested extends ChatEvent {
  final String messageId;
  final String newText;
  
  const ChatMessageUpdateRequested({
    required this.messageId,
    required this.newText,
  });
  
  @override
  List<Object?> get props => [messageId, newText];
}

/// Delete a message
/// 
/// **When:** User deletes sent message
/// 
/// **What happens:**
/// 1. Call repository.deleteMessage()
/// 2. Remove from local list
/// 3. Emit ChatLoaded
/// 
/// **Example:**
/// ```dart
/// context.read<ChatBloc>().add(
///   ChatMessageDeleteRequested(messageId: message.id),
/// );
/// ```
class ChatMessageDeleteRequested extends ChatEvent {
  final String messageId;
  
  const ChatMessageDeleteRequested({
    required this.messageId,
  });
  
  @override
  List<Object?> get props => [messageId];
}

// ============================================================================
// MEDIA EVENTS (Day 29 implementation)
// ============================================================================

/// Upload media (image/file)
/// 
/// **When:** User picks image/file
/// 
/// **What happens:**
/// 1. Emit uploading state
/// 2. Upload to Supabase Storage
/// 3. Send message with media URL
/// 
/// **Example:**
/// ```dart
/// context.read<ChatBloc>().add(
///   ChatMediaUploadRequested(
///     filePath: pickedFile.path,
///     receiverId: otherUser.id,
///   ),
/// );
/// ```
class ChatMediaUploadRequested extends ChatEvent {
  final String filePath;
  final String receiverId;
  
  const ChatMediaUploadRequested({
    required this.filePath,
    required this.receiverId,
  });
  
  @override
  List<Object?> get props => [filePath, receiverId];
}

// ============================================================================
// REALTIME EVENTS (Day 20 implementation)
// ============================================================================

/// Start realtime subscription
/// 
/// **When:** Chat screen mounted
/// 
/// **What happens:**
/// 1. Subscribe to Supabase Realtime
/// 2. Listen for new messages
/// 3. Dispatch ChatMessageReceived for each
/// 
/// **Example:**
/// ```dart
/// context.read<ChatBloc>().add(
///   ChatRealtimeSubscriptionRequested(chatId: chatId),
/// );
/// ```
class ChatRealtimeSubscriptionRequested extends ChatEvent {
  final String chatId;
  
  const ChatRealtimeSubscriptionRequested({
    required this.chatId,
  });
  
  @override
  List<Object?> get props => [chatId];
}

/// Stop realtime subscription
/// 
/// **When:** Chat screen disposed
/// 
/// **What happens:**
/// 1. Unsubscribe from Realtime
/// 2. Clean up resources
class ChatRealtimeSubscriptionCancelled extends ChatEvent {
  const ChatRealtimeSubscriptionCancelled();
}

// ============================================================================
// USAGE SUMMARY
// ============================================================================
//
// LOAD HISTORY:
// ```dart
// bloc.add(ChatHistoryLoadRequested(chatId: chatId, otherUserId: userId));
// ```
//
// SEND MESSAGE:
// ```dart
// bloc.add(ChatMessageSendRequested(text: 'Hello', receiverId: userId));
// ```
//
// RECEIVE MESSAGE (realtime):
// ```dart
// bloc.add(ChatMessageReceived(message: message));
// ```
//
// LOAD MORE:
// ```dart
// bloc.add(ChatLoadMoreRequested(chatId: chatId, before: timestamp));
// ```
//
// UPDATE:
// ```dart
// bloc.add(ChatMessageUpdateRequested(messageId: id, newText: 'Edited'));
// ```
//
// DELETE:
// ```dart
// bloc.add(ChatMessageDeleteRequested(messageId: id));
// ```
//
// ============================================================================
