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
        details: e.details,
      );
      
    } catch (e) {
      if (e is ChatException) rethrow;
      
      // Network errors
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw const NetworkException();
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
      
      // Add pagination filter if provided
      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }
      
      // Execute query
      final response = await query;
      
      // Convert to Message objects
      return (response as List)
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();
      
    } on PostgrestException catch (e) {
      throw ChatLoadFailedException(
        'Failed to load messages: ${e.message}',
        details: e.details,
      );
      
    } catch (e) {
      if (e is ChatException) rethrow;
      
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw const NetworkException();
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
        throw const NetworkException();
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
        technicalDetails: e.details,
      );
      
    } catch (e) {
      if (e is ChatException) rethrow;
      
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw const NetworkException();
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
        technicalDetails: e.details,
      );
      
    } catch (e) {
      if (e is ChatException) rethrow;
      
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw const NetworkException();
      }
      
      throw ChatException(
        'Failed to delete message',
        code: 'DELETE_FAILED',
        technicalDetails: e.toString(),
      );
    }
  }
  
  // =========================================================================
  // REALTIME PREP (Day 20 implementation)
  // =========================================================================
  
  /// Subscribe to new messages in chat (placeholder for Day 20)
  /// 
  /// **Will implement:**
  /// - Realtime subscription
  /// - Message stream
  /// - Automatic updates
  /// 
  /// **For now:** Returns null (implement on Day 20)
  Stream<Message>? subscribeToChat(String chatId) {
    // TODO: Implement on Day 20 (Realtime)
    return null;
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
