/// ============================================================================
/// CHAT STATES - UI REPRESENTATIONS FOR MESSAGING
/// ============================================================================
/// 
/// PURPOSE: Define all possible UI states for chat
/// 
/// PATTERN: Same as ProfileState (you built this!)
///
/// ============================================================================

import 'package:equatable/equatable.dart';
import 'package:supabase_flutter_app/features/chat/data/message_model.dart';

/// ChatState - Base class for all chat states
/// 
/// **Pattern:** Sealed class
/// 
/// **Why Equatable?**
/// - BLoC compares states before emitting
/// - BlocBuilder rebuilds only when state changes
/// - Efficient UI updates
sealed class ChatState extends Equatable {
  const ChatState();
  
  @override
  List<Object?> get props => [];
}

// ============================================================================
// INITIAL STATE
// ============================================================================

/// Initial state - nothing loaded yet
/// 
/// **UI shows:** Empty screen or placeholder
/// 
/// **When:** BLoC just created, no events yet
/// 
/// **Example:**
/// ```dart
/// if (state is ChatInitial) {
///   return EmptyScreen();
/// }
/// ```
class ChatInitial extends ChatState {
  const ChatInitial();
}

// ============================================================================
// LOADING STATES
// ============================================================================

/// Loading chat history
/// 
/// **UI shows:** Full-screen loading spinner
/// 
/// **When:** Fetching chat history for first time
/// 
/// **Example:**
/// ```dart
/// if (state is ChatLoading) {
///   return Center(child: CircularProgressIndicator());
/// }
/// ```
class ChatLoading extends ChatState {
  const ChatLoading();
}

/// Loading more messages (pagination)
/// 
/// **UI shows:** Messages + loading indicator at top
/// 
/// **When:** User scrolled to top, fetching older messages
/// 
/// **Data:**
/// - Current messages (to keep showing)
/// - chatId, otherUserId
/// 
/// **Example:**
/// ```dart
/// if (state is ChatLoadingMore) {
///   return Column([
///     CircularProgressIndicator(),  // At top
///     ...messagesList,
///   ]);
/// }
/// ```
class ChatLoadingMore extends ChatState {
  final List<Message> messages;
  final String chatId;
  final String otherUserId;
  
  const ChatLoadingMore({
    required this.messages,
    required this.chatId,
    required this.otherUserId,
  });
  
  @override
  List<Object?> get props => [messages, chatId, otherUserId];
}

// ============================================================================
// LOADED STATES
// ============================================================================

/// Chat loaded successfully
/// 
/// **UI shows:** Messages list
/// 
/// **When:** Successfully loaded chat history or messages updated
/// 
/// **Data:**
/// - messages: List of messages in chat
/// - chatId: Conversation ID
/// - otherUserId: Who user is chatting with
/// - hasMore: Are there older messages? (for pagination)
/// 
/// **Example:**
/// ```dart
/// if (state is ChatLoaded) {
///   return ListView.builder(
///     itemCount: state.messages.length,
///     itemBuilder: (context, index) {
///       return MessageBubble(message: state.messages[index]);
///     },
///   );
/// }
/// ```
class ChatLoaded extends ChatState {
  final List<Message> messages;
  final String chatId;
  final String otherUserId;
  final bool hasMore;
  
  const ChatLoaded({
    required this.messages,
    required this.chatId,
    required this.otherUserId,
    this.hasMore = true,
  });
  
  @override
  List<Object?> get props => [messages, chatId, otherUserId, hasMore];
  
  /// Helper: Check if message list is empty
  bool get isEmpty => messages.isEmpty;
  
  /// Helper: Get message count
  int get messageCount => messages.length;
  
  /// Helper: Get earliest message (for pagination)
  Message? get earliestMessage => messages.isEmpty ? null : messages.last;
  
  /// Helper: Get latest message
  Message? get latestMessage => messages.isEmpty ? null : messages.first;
}

/// Message sending (optimistic update)
/// 
/// **UI shows:** Messages + pending message with sending indicator
/// 
/// **When:** User sent message, waiting for server confirmation
/// 
/// **Purpose:** 
/// - Instant feedback
/// - App feels fast
/// - Better UX
/// 
/// **Data:**
/// - All ChatLoaded data
/// - pendingMessage: Message being sent
/// 
/// **Example:**
/// ```dart
/// if (state is ChatMessageSending) {
///   return ListView(
///     children: [
///       ...state.messages.map(MessageBubble),
///       MessageBubble(
///         message: state.pendingMessage,
///         isPending: true,  // Show sending indicator
///       ),
///     ],
///   );
/// }
/// ```
class ChatMessageSending extends ChatState {
  final List<Message> messages;
  final String chatId;
  final String otherUserId;
  final Message pendingMessage;
  final bool hasMore;
  
  const ChatMessageSending({
    required this.messages,
    required this.chatId,
    required this.otherUserId,
    required this.pendingMessage,
    this.hasMore = true,
  });
  
  @override
  List<Object?> get props => [
        messages,
        chatId,
        otherUserId,
        pendingMessage,
        hasMore,
      ];
}

// ============================================================================
// ERROR STATE
// ============================================================================

/// Error occurred
/// 
/// **UI shows:** Error message + retry button
/// 
/// **When:** Any operation failed
/// 
/// **Data:**
/// - message: User-friendly error
/// - isRecoverable: Can user retry?
/// - previousMessages: To show (optional)
/// 
/// **Example:**
/// ```dart
/// if (state is ChatError) {
///   return ErrorWidget(
///     message: state.message,
///     onRetry: state.isRecoverable
///         ? () => bloc.add(RetryEvent())
///         : null,
///   );
/// }
/// ```
class ChatError extends ChatState {
  final String message;
  final bool isRecoverable;
  final List<Message>? previousMessages;  // To keep showing if available
  
  const ChatError({
    required this.message,
    this.isRecoverable = true,
    this.previousMessages,
  });
  
  @override
  List<Object?> get props => [message, isRecoverable, previousMessages];
}

// ============================================================================
// MEDIA UPLOAD STATE (Day 29)
// ============================================================================

/// Media uploading
/// 
/// **UI shows:** Upload progress
/// 
/// **When:** User picked image/file, uploading to storage
/// 
/// **Data:**
/// - messages: Current messages
/// - uploadProgress: 0.0 to 1.0
class ChatMediaUploading extends ChatState {
  final List<Message> messages;
  final String chatId;
  final String otherUserId;
  final double uploadProgress;
  
  const ChatMediaUploading({
    required this.messages,
    required this.chatId,
    required this.otherUserId,
    required this.uploadProgress,
  });
  
  @override
  List<Object?> get props => [messages, chatId, otherUserId, uploadProgress];
}

// ============================================================================
// STATE TRANSITION EXAMPLES
// ============================================================================
//
// LOAD CHAT:
// ChatInitial → ChatLoading → ChatLoaded
//
// SEND MESSAGE:
// ChatLoaded → ChatMessageSending → ChatLoaded (with new message)
//
// RECEIVE MESSAGE:
// ChatLoaded → ChatLoaded (messages updated)
//
// LOAD MORE:
// ChatLoaded → ChatLoadingMore → ChatLoaded (more messages prepended)
//
// ERROR:
// ChatLoading → ChatError
// ChatLoaded → ChatError (keeps previousMessages)
//
// UPLOAD MEDIA:
// ChatLoaded → ChatMediaUploading → ChatMessageSending → ChatLoaded
//
// ============================================================================
// USAGE IN UI
// ============================================================================
//
// ```dart
// BlocBuilder<ChatBloc, ChatState>(
//   builder: (context, state) {
//     return switch (state) {
//       ChatInitial() => EmptyScreen(),
//       ChatLoading() => LoadingScreen(),
//       ChatLoaded() => MessagesList(messages: state.messages),
//       ChatMessageSending() => MessagesList(
//         messages: [...state.messages, state.pendingMessage],
//       ),
//       ChatLoadingMore() => MessagesList(
//         messages: state.messages,
//         showTopLoader: true,
//       ),
//       ChatError() => ErrorScreen(
//         message: state.message,
//         messages: state.previousMessages,
//       ),
//       ChatMediaUploading() => MessagesList(
//         messages: state.messages,
//         uploadProgress: state.uploadProgress,
//       ),
//     };
//   },
// )
// ```
//
// ============================================================================
