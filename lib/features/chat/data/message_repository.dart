/// ============================================================================
/// MESSAGE REPOSITORY - DATA ACCESS FOR MESSAGES
/// ============================================================================
/// 
/// PURPOSE: Handle all message database operations
/// 
/// LEARNING: Repository pattern (you learned this with ProfileRepository!)
///
/// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/core/error/exceptions.dart';
import 'message_model.dart';
import 'chat_exceptions.dart';

/// MessageRepository - Handles message CRUD operations
/// 
/// **Pattern**: Same as ProfileRepository!
/// 
/// **Responsibilities:**
/// - Send messages (INSERT)
/// - Fetch chat history (SELECT with pagination)
/// - Update messages (for editing)
/// - Delete messages
/// - Error handling
class MessageRepository {
  final SupabaseClient _supabase;
  static const String _tableName = 'messages';
  
  MessageRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;
  
  // =========================================================================
  // CREATE - SEND MESSAGE
  // =========================================================================
  
  /// Send a message
  /// 
  /// **Process:**
  /// 1. Validate input (text OR media required)
  /// 2. Create Message object
  /// 3. Remove empty id (database generates it)
  /// 4. INSERT into database
  /// 5. Return created message with server-generated fields
  /// 
  /// **Example:**
  /// ```dart
  /// final message = await repository.sendMessage(
  ///   chatId: chatId,
  ///   senderId: currentUserId,
  ///   receiverId: otherUserId,
  ///   text: 'Hello!',
  /// );
  /// ```
  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    String? text,
    String? mediaUrl,
  }) async {
    try {
      // STEP 1: Validate (at least one must be present)
      if ((text == null || text.trim().isEmpty) &&
          (mediaUrl == null || mediaUrl.trim().isEmpty)) {
        throw const ChatException(
          'Message must have either text or media',
          code: 'VALIDATION_ERROR',
        );
      }
      
      // STEP 2: Create Message object
      final now = DateTime.now();
      final message = Message(
        id: '',  // Empty - database will generate
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        message: text?.trim(),
        mediaUrl: mediaUrl?.trim(),
        createdAt: now,
        updatedAt: now,
      );
      
      // STEP 3: Convert to JSON and remove empty id
      final messageData = message.toJson();
      messageData.remove('id');  // Database generates id
      
      // STEP 4: INSERT into database
      final response = await _supabase
          .from(_tableName)
          .insert(messageData)
          .select()
          .single();
      
      // STEP 5: Return created message
      return Message.fromJson(response);
      
    } on PostgrestException catch (e) {
      // Database-specific errors
      if (e.code == 'PGRST116') {
        throw const MessageNotFoundException();
      }
      throw MessageSendFailedException(
        'Failed to send message: ${e.message}',
        details: e.details?.toString(),
      );
      
    } catch (e) {
      if (e is ChatException) rethrow;
      
      // Network errors
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      
      throw MessageSendFailedException(e.toString());
    }
  }
  
  // =========================================================================
  // READ - FETCH CHAT HISTORY
  // =========================================================================
  
  /// Get chat history with pagination
  /// 
  /// **Purpose:** Load messages in conversationReturns most recent messages first
  /// 
  /// **Pagination:**
  /// - First load: getChatHistory(chatId)
  /// - Load more: getChatHistory(chatId, before: oldestMessage.createdAt)
  /// 
  /// **Example:**
  /// ```dart
  /// // Load first 50 messages
  /// final messages = await repository.getChatHistory(
  ///   chatId: chatId,
  ///   limit: 50,
  /// );
  /// 
  /// // Load next 50 (older messages)
  /// final moreMessages = await repository.getChatHistory(
  ///   chatId: chatId,
  ///   limit: 50,
  ///   before: messages.last.createdAt,
  /// );
  /// ```
  Future<List<Message>> getChatHistory({
    required String chatId,
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      // Build query
      var query = _supabase
          .from(_tableName)
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      // For older Supabase versions, use limit instead of lt/lte
      query = query
        .order('created_at', ascending: false)
        .limit(before != null ? 50 : 100);
      
      // Execute query
      final response = await query;
      
      // Convert to Message objects
      return (response as List)
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();
      
    } on PostgrestException catch (e) {
      throw ChatLoadFailedException(
        'Failed to load messages: ${e.message}',
        details: e.details?.toString(),
      );
      
    } catch (e) {
      if (e is ChatException) rethrow;
      
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      
      throw ChatLoadFailedException(e.toString());
    }
  }
  
  /// Get single message by ID
  /// 
  /// **Used for:** Finding specific message (e.g., reply feature)
  Future<Message?> getMessage(String messageId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', messageId)
          .maybeSingle();
      
      if (response == null) return null;
      
      return Message.fromJson(response);
      
    } catch (e) {
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      
      throw ChatLoadFailedException(e.toString());
    }
  }
  
  // =========================================================================
  // UPDATE - EDIT MESSAGE
  // =========================================================================
  
  /// Update message text (for edit feature)
  /// 
  /// **RLS Check:** Only sender can update
  /// 
  /// **Example:**
  /// ```dart
  /// final updated = await repository.updateMessage(
  ///   messageId: message.id,
  ///   newText: 'Edited message',
  /// );
  /// ```
  Future<Message> updateMessage({
    required String messageId,
    required String newText,
  }) async {
    try {
      if (newText.trim().isEmpty) {
        throw const ChatException(
          'Message text cannot be empty',
          code: 'VALIDATION_ERROR',
        );
      }
      
      final response = await _supabase
          .from(_tableName)
          .update({
            'message': newText.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .select()
          .single();
      
      return Message.fromJson(response);
      
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const MessageNotFoundException();
      }
      throw ChatException(
        'Failed to update message: ${e.message}',
        code: 'UPDATE_FAILED',
        technicalDetails: e.details?.toString(),
      );
      
    } catch (e) {
      if (e is ChatException) rethrow;
      
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      
      throw ChatException(
        'Failed to update message',
        code: 'UPDATE_FAILED',
        technicalDetails: e.toString(),
      );
    }
  }
  
  // =========================================================================
  // DELETE - REMOVE MESSAGE
  // =========================================================================
  
  /// Delete a message
  /// 
  /// **RLS Check:** Only sender can delete
  /// 
  /// **Example:**
  /// ```dart
  /// await repository.deleteMessage(messageId);
  /// ```
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', messageId);
      
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const MessageNotFoundException();
      }
      throw ChatException(
        'Failed to delete message: ${e.message}',
        code: 'DELETE_FAILED',
        technicalDetails: e.details?.toString(),
      );
      
    } catch (e) {
      if (e is ChatException) rethrow;
      
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      
      throw ChatException(
        'Failed to delete message',
        code: 'DELETE_FAILED',
        technicalDetails: e.toString(),
      );
    }
  }
  
  // =========================================================================
  // REALTIME - MESSAGE STREAMING
  // =========================================================================
  
  /// Stream messages in real-time
  /// 
  /// **Real-time Updates:**
  /// - New messages appear instantly
  /// - No manual refresh needed
  /// - Works with Supabase Realtime
  /// 
  /// **Example:**
  /// ```dart
  /// repository.streamMessages(chatId).listen((messages) {
  ///   // Update UI with new messages
  ///   print('Received ${messages.length} messages');
  /// });
  /// ```
  Stream<List<Message>> streamMessages(String chatId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter for this chat and sort by created_at
          final filtered = data.where((item) => item['chat_id'] == chatId).toList();
          filtered.sort((a, b) {
            final aTime = DateTime.parse(a['created_at'] as String);
            final bTime = DateTime.parse(b['created_at'] as String);
            return aTime.compareTo(bTime);
          });
          return filtered.map((json) => Message.fromJson(json)).toList();
        });
  }

  // =========================================================================
  // TYPING INDICATORS
  // =========================================================================

  /// Update typing status
  /// 
  /// **Send when:**
  /// - User starts typing: setTypingStatus(chatId, true)
  /// - User stops typing: setTypingStatus(chatId, false)
  /// - User sends message: setTypingStatus(chatId, false)
  Future<void> setTypingStatus({
    required String chatId,
    required bool isTyping,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      await _supabase.from('chat_typing').upsert({
        'chat_id': chatId,
        'user_id': currentUser.id,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  /// Stream typing status for other user
  /// 
  /// **Usage:**
  /// ```dart
  /// repository.streamTypingStatus(chatId, otherUserId).listen((isTyping) {
  ///   if (isTyping) {
  ///     // Show "User is typing..."
  ///   } else {
  ///     // Hide typing indicator
  ///   }
  /// });
  /// ```
  Stream<bool> streamTypingStatus(String chatId, String otherUserId) {
    return _supabase
        .from('chat_typing')
        .stream(primaryKey: ['chat_id', 'user_id'])
        .map((data) {
          if (data.isEmpty) return false;
          // Filter for specific chat and user
          final filtered = data.where((item) => 
            item['chat_id'] == chatId && item['user_id'] == otherUserId
          );
          if (filtered.isEmpty) return false;
          final typing = filtered.first['is_typing'];
          return typing == true;
        });
  }

  // =========================================================================
  // READ RECEIPTS
  // =========================================================================

  /// Mark message as delivered
  Future<void> markAsDelivered(String messageId) async {
    try {
      await _supabase.from(_tableName).update({
        'delivered_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);
    } catch (e) {
      print('Error marking as delivered: $e');
    }
  }

  /// Mark message as read
  /// 
  /// **Auto-called when:**
  /// - User views message on screen
  /// - Chat screen is opened
  Future<void> markAsRead(String messageId) async {
    try {
      await _supabase.from(_tableName).update({
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  /// Mark all messages in chat as read
  /// 
  /// **Called when:** User opens chat screen
  Future<void> markAllAsRead(String chatId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      await _supabase
          .from(_tableName)
          .update({
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('chat_id', chatId)
          .eq('receiver_id', currentUser.id)
          .isFilter('read_at', null);
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  /// Get unread message count for a chat
  Future<int> getUnreadCount(String chatId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return 0;

      final response = await _supabase
          .from(_tableName)
          .select('id')
          .eq('chat_id', chatId)
          .eq('receiver_id', currentUser.id)
          .isFilter('read_at', null);

      return (response as List).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================
//
// 1. SEND MESSAGE:
// ```dart
// final repository = MessageRepository();
// 
// final message = await repository.sendMessage(
//   chatId: chatId,
//   senderId: currentUser.id,
//   receiverId: otherUser.id,
//   text: 'Hello, how are you?',
// );
// ```
//
// 2. FETCH HISTORY:
// ```dart
// // First load
// final messages = await repository.getChatHistory(
//   chatId: chatId,
//   limit: 50,
// );
// 
// // Infinite scroll - load more
// final olderMessages = await repository.getChatHistory(
//   chatId: chatId,
//   limit: 50,
//   before: messages.last.createdAt,  // Pagination!
// );
// ```
//
// 3. EDIT MESSAGE:
// ```dart
// final updated = await repository.updateMessage(
//   messageId: message.id,
//   newText: 'Edited message text',
// );
// ```
//
// 4. DELETE MESSAGE:
// ```dart
// await repository.deleteMessage(messageId);
// ```
//
// ============================================================================
