/// ============================================================================
/// CHAT BLOC - BUSINESS LOGIC FOR MESSAGING
/// ============================================================================
/// 
/// PURPOSE: Handle all messaging business logic
/// 
/// PATTERN: Same as ProfileBloc (you built this!)
///
/// ============================================================================

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter_app/core/error/exceptions.dart';
import 'package:supabase_flutter_app/features/chat/data/message_model.dart';
import 'package:supabase_flutter_app/features/chat/data/message_repository.dart';
import 'package:supabase_flutter_app/features/chat/data/chat_repository.dart';
import 'package:supabase_flutter_app/features/chat/data/chat_exceptions.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// ChatBloc - Manages chat messaging state
/// 
/// **Pattern**: Same as ProfileBloc!
/// 
/// ```
/// UI → Dispatch Event → ChatBloc
///                         ↓
///                   Process Event
///                         ↓
///                    Emit New State
///                         ↓
/// UI ← Listen to State ← ChatBloc
/// ```
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final MessageRepository _messageRepository;
  final ChatRepository _chatRepository;
  final String _currentUserId;
  
  // Realtime subscription (Day 20)
  StreamSubscription? _realtimeSubscription;
  
  ChatBloc({
    required MessageRepository messageRepository,
    required ChatRepository chatRepository,
    required String currentUserId,
  })  : _messageRepository = messageRepository,
        _chatRepository = chatRepository,
        _currentUserId = currentUserId,
        super(const ChatInitial()) {
    // Register event handlers (like ProfileBloc!)
    on<ChatHistoryLoadRequested>(_onHistoryLoad);
    on<ChatMessageSendRequested>(_onMessageSend);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatLoadMoreRequested>(_onLoadMore);
    on<ChatMessageUpdateRequested>(_onMessageUpdate);
    on<ChatMessageDeleteRequested>(_onMessageDelete);
    on<ChatRealtimeSubscriptionRequested>(_onRealtimeSubscribe);
    on<ChatRealtimeSubscriptionCancelled>(_onRealtimeUnsubscribe);
  }
  
  // =========================================================================
  // HANDLER 1: LOAD CHAT HISTORY
  // =========================================================================
  
  /// Load chat history
  /// 
  /// **Flow:**
  /// 1. Emit loading
  /// 2. Fetch from repository
  /// 3. Emit loaded
  Future<void> _onHistoryLoad(
    ChatHistoryLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());
    
    try {
      // Fetch messages
      final messages = await _messageRepository.getChatHistory(
        chatId: event.chatId,
        limit: 50,
      );
      
      // Emit loaded state
      emit(ChatLoaded(
        messages: messages,
        chatId: event.chatId,
        otherUserId: event.otherUserId,
        hasMore: messages.length >= 50,
      ));
      
    } on NetworkException {
      emit(const ChatError(
        message: 'No internet connection',
        isRecoverable: true,
      ));
    } on ChatLoadFailedException catch (e) {
      emit(ChatError(
        message: e.message,
        isRecoverable: e.isRecoverable,
      ));
    } catch (e) {
      emit(const ChatError(
        message: 'Failed to load messages',
        isRecoverable: true,
      ));
    }
  }
  
  // =========================================================================
  // HANDLER 2: SEND MESSAGE (OPTIMISTIC UPDATE)
  // =========================================================================
  
  /// Send message with optimistic update
  /// 
  /// **Flow:**
  /// 1. Show message immediately (optimistic)
  /// 2. Send to server
  /// 3. Replace with server version
  /// 4. Update chat metadata
  Future<void> _onMessageSend(
    ChatMessageSendRequested event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;
    
    // Create optimistic message (temporary ID)
    final optimisticMessage = Message(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      chatId: currentState.chatId,
      senderId: _currentUserId,
      receiverId: event.receiverId,
      message: event.text,
      mediaUrl: event.mediaUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Optimistic update - show immediately!
    emit(ChatMessageSending(
      messages: currentState.messages,
      chatId: currentState.chatId,
      otherUserId: currentState.otherUserId,
      pendingMessage: optimisticMessage,
      hasMore: currentState.hasMore,
    ));
    
    try {
      // Get/create chat
      final chat = await _chatRepository.getOrCreateChat(
        userId1: _currentUserId,
        userId2: event.receiverId,
      );
      
      // Send to server
      final sentMessage = await _messageRepository.sendMessage(
        chatId: chat.id,
        senderId: _currentUserId,
        receiverId: event.receiverId,
        text: event.text,
        mediaUrl: event.mediaUrl,
      );
      
      // Update chat metadata
      await _chatRepository.updateLastMessage(
        chatId: chat.id,
        messageText: event.text ?? '[Media]',
        messageTime: sentMessage.createdAt,
      );
      
      // Replace optimistic with real message
      final updatedMessages = [sentMessage, ...currentState.messages];
      
      emit(ChatLoaded(
        messages: updatedMessages,
        chatId: currentState.chatId,
        otherUserId: currentState.otherUserId,
        hasMore: currentState.hasMore,
      ));
      
    } on NetworkException {
      emit(ChatError(
        message: 'No internet connection',
        isRecoverable: true,
        previousMessages: currentState.messages,
      ));
    } on MessageSendFailedException catch (e) {
      emit(ChatError(
        message: e.message,
        isRecoverable: e.isRecoverable,
        previousMessages: currentState.messages,
      ));
    } catch (e) {
      emit(ChatError(
        message: 'Failed to send message',
        isRecoverable: true,
        previousMessages: currentState.messages,
      ));
    }
  }
  
  // =========================================================================
  // HANDLER 3: RECEIVE MESSAGE (REALTIME)
  // =========================================================================
  
  /// Receive message from realtime
  /// 
  /// **Flow:**
  /// 1. Check for duplicates
  /// 2. Add to messages
  /// 3. Emit updated state
  Future<void> _onMessageReceived(
    ChatMessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;
    
    // Prevent duplicates
    final messageExists = currentState.messages
        .any((m) => m.id == event.message.id);
    
    if (messageExists) return;
    
    // Add to list
    final updatedMessages = [event.message, ...currentState.messages];
    
    emit(ChatLoaded(
      messages: updatedMessages,
      chatId: currentState.chatId,
      otherUserId: currentState.otherUserId,
      hasMore: currentState.hasMore,
    ));
  }
  
  // =========================================================================
  // HANDLER 4: LOAD MORE (PAGINATION)
  // =========================================================================
  
  /// Load more messages (pagination)
  /// 
  /// **Flow:**
  /// 1. Show loading at top
  /// 2. Fetch older messages
  /// 3. Append to list
  Future<void> _onLoadMore(
    ChatLoadMoreRequested event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;
    if (!currentState.hasMore) return;
    
    // Show loading at top
    emit(ChatLoadingMore(
      messages: currentState.messages,
      chatId: currentState.chatId,
      otherUserId: currentState.otherUserId,
    ));
    
    try {
      // Fetch older messages
      final olderMessages = await _messageRepository.getChatHistory(
        chatId: event.chatId,
        before: event.before,
        limit: 50,
      );
      
      // Append to existing
      final allMessages = [...currentState.messages, ...olderMessages];
      
      emit(ChatLoaded(
        messages: allMessages,
        chatId: currentState.chatId,
        otherUserId: currentState.otherUserId,
        hasMore: olderMessages.length >= 50,
      ));
      
    } on NetworkException {
      emit(ChatError(
        message: 'No internet connection',
        isRecoverable: true,
        previousMessages: currentState.messages,
      ));
    } catch (e) {
      emit(ChatError(
        message: 'Failed to load more messages',
        isRecoverable: true,
        previousMessages: currentState.messages,
      ));
    }
  }
  
  // =========================================================================
  // HANDLER 5: UPDATE MESSAGE
  // =========================================================================
  
  /// Update (edit) message
  /// 
  /// **Flow:**
  /// 1. Update in database
  /// 2. Update in local list
  /// 3. Emit updated state
  Future<void> _onMessageUpdate(
    ChatMessageUpdateRequested event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;
    
    try {
      // Update in database
      final updated = await _messageRepository.updateMessage(
        messageId: event.messageId,
        newText: event.newText,
      );
      
      // Update in local list
      final updatedMessages = currentState.messages.map((m) {
        return m.id == event.messageId ? updated : m;
      }).toList();
      
      emit(ChatLoaded(
        messages: updatedMessages,
        chatId: currentState.chatId,
        otherUserId: currentState.otherUserId,
        hasMore: currentState.hasMore,
      ));
      
    } on NetworkException {
      emit(ChatError(
        message: 'No internet connection',
        isRecoverable: true,
        previousMessages: currentState.messages,
      ));
    } catch (e) {
      emit(ChatError(
        message: 'Failed to update message',
        isRecoverable: true,
        previousMessages: currentState.messages,
      ));
    }
  }
  
  // =========================================================================
  // HANDLER 6: DELETE MESSAGE
  // =========================================================================
  
  /// Delete message
  /// 
  /// **Flow:**
  /// 1. Delete from database
  /// 2. Remove from local list
  /// 3. Emit updated state
  Future<void> _onMessageDelete(
    ChatMessageDeleteRequested event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;
    
    try {
      // Delete from database
      await _messageRepository.deleteMessage(event.messageId);
      
      // Remove from local list
      final updatedMessages = currentState.messages
          .where((m) => m.id != event.messageId)
          .toList();
      
      emit(ChatLoaded(
        messages: updatedMessages,
        chatId: currentState.chatId,
        otherUserId: currentState.otherUserId,
        hasMore: currentState.hasMore,
      ));
      
    } on NetworkException {
      emit(ChatError(
        message: 'No internet connection',
        isRecoverable: true,
        previousMessages: currentState.messages,
      ));
    } catch (e) {
      emit(ChatError(
        message: 'Failed to delete message',
        isRecoverable: true,
        previousMessages: currentState.messages,
      ));
    }
  }
  
  // =========================================================================
  // REALTIME HANDLERS (Day 20 full implementation)
  // =========================================================================
  
  /// Subscribe to realtime messages (placeholder)
  Future<void> _onRealtimeSubscribe(
    ChatRealtimeSubscriptionRequested event,
    Emitter<ChatState> emit,
  ) async {
    // TODO: Implement on Day 20
    // Will set up Supabase Realtime subscription
  }
  
  /// Unsubscribe from realtime
  Future<void> _onRealtimeUnsubscribe(
    ChatRealtimeSubscriptionCancelled event,
    Emitter<ChatState> emit,
  ) async {
    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
  }
  
  // =========================================================================
  // CLEANUP
  // =========================================================================
  
  @override
  Future<void> close() {
    _realtimeSubscription?.cancel();
    return super.close();
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================
//
// 1. CREATE BLOC:
// ```dart
// final chatBloc = ChatBloc(
//   messageRepository: MessageRepository(),
//   chatRepository: ChatRepository(),
//   currentUserId: auth.currentUser!.id,
// );
// ```
//
// 2. LOAD CHAT:
// ```dart
// chatBloc.add(ChatHistoryLoadRequested(
//   chatId: chatId,
//   otherUserId: otherUser.id,
// ));
// ```
//
// 3. SEND MESSAGE:
// ```dart
// chatBloc.add(ChatMessageSendRequested(
//   text: 'Hello!',
//   receiverId: otherUser.id,
// ));
// ```
//
// 4. LOAD MORE:
// ```dart
// chatBloc.add(ChatLoadMoreRequested(
//   chatId: chatId,
//   before: earliestMessage.createdAt,
// ));
// ```
//
// ============================================================================
