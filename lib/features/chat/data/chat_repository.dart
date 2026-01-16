/// ============================================================================
/// CHAT REPOSITORY - DATA ACCESS FOR CHAT METADATA
/// ============================================================================
/// 
/// PURPOSE: Handle chat metadata operations
/// 
/// LEARNING: Working with relationships and metadata
///
/// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/core/error/exceptions.dart';
import 'chat_model.dart';
import 'chat_exceptions.dart';
import 'chat_id_service.dart';

/// ChatRepository - Handles chat metadata operations
/// 
/// **Purpose:**
/// - Manage chat conversations (not individual messages)
/// - Track conversation metadata (last message, participants)
/// - Support chat list screen
/// 
/// **Key Concept:**
/// One Chat per user pair (enforced by database UNIQUE constraint)
class ChatRepository {
  final SupabaseClient _supabase;
  final ChatIdService _chatIdService;
  static const String _tableName = 'chats';
  
  ChatRepository({
    SupabaseClient? supabaseClient,
    ChatIdService? chatIdService,
  })  : _supabase = supabaseClient ?? Supabase.instance.client,
        _chatIdService = chatIdService ?? ChatIdService();
  
  // =========================================================================
  // GET OR CREATE CHAT
  // =========================================================================
  
  /// Get existing chat or create new one
  /// 
  /// **Idempotent:** Safe to call multiple times
  /// 
  /// **Process:**
  /// 1. Generate deterministic chat_id
  /// 2. Try to fetch existing chat
  /// 3. If not found, create new chat
  /// 4. Return chat
  /// 
  /// **Example:**
  /// ```dart
  /// final chat = await repository.getOrCreateChat(
  ///   userId1: currentUser.id,
  ///   userId2: otherUser.id,
  /// );
  /// // Returns existing chat or creates new one
  /// ```
  Future<Chat> getOrCreateChat({
    required String userId1,
    required String userId2,
  }) async {
    try {
      // STEP 1: Generate deterministic chat ID
      final chatId = _chatIdService.generateChatId(userId1, userId2);
      
      // STEP 2: Try to find existing chat
      final existingChat = await getChat(chatId);
      if (existingChat != null) {
        return existingChat;  // Chat exists!
      }
      
      // STEP 3: Create new chat
      final sortedIds = _chatIdService.getSortedUserIds(userId1, userId2);
      final now = DateTime.now();
      
      final chatData = {
        'id': chatId,
        'user1_id': sortedIds[0],  // Alphabetically first
        'user2_id': sortedIds[1],  // Alphabetically second
        'last_message': null,
        'last_message_at': null,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      
      final response = await _supabase
          .from(_tableName)
          .insert(chatData)
          .select()
          .single();
      
      return Chat.fromJson(response);
      
    } on PostgrestException catch (e) {
      // If unique constraint violation, chat was created concurrently
      if (e.code == '23505') {
        // Retry - fetch the chat that was just created
        final chatId = _chatIdService.generateChatId(userId1, userId2);
        final chat = await getChat(chatId);
        if (chat != null) return chat;
      }
      
      throw ChatException(
        'Failed to get or create chat: ${e.message}',
        code: 'CHAT_CREATE_FAILED',
        technicalDetails: e.details,
      );
      
    } catch (e) {
      if (e is ChatException) rethrow;
      
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw const NetworkException();
      }
      
      throw ChatException(
        'Failed to get or create chat',
        code: 'CHAT_CREATE_FAILED',
        technicalDetails: e.toString(),
      );
    }
  }
  
  // =========================================================================
  // GET CHAT BY ID
  // =========================================================================
  
  /// Get chat by ID
  /// 
  /// **Returns:** Chat or null if not found
  /// 
  /// **Example:**
  /// ```dart
  /// final chat = await repository.getChat(chatId);
  /// if (chat != null) {
  ///   print('Chat participants: ${chat.user1Id}, ${chat.user2Id}');
  /// }
  /// ```
  Future<Chat?> getChat(String chatId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', chatId)
          .maybeSingle();
      
      if (response == null) return null;
      
      return Chat.fromJson(response);
      
    } catch (e) {
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw const NetworkException();
      }
      
      throw ChatException(
        'Failed to fetch chat',
        code: 'CHAT_FETCH_FAILED',
        technicalDetails: e.toString(),
      );
    }
  }
  
  // =========================================================================
  // GET USER'S CHATS
  // =========================================================================
  
  /// Get all chats for a user
  /// 
  /// **Purpose:** Chat list screen
  /// 
  /// **Sorting:** Most recent first (by last_message_at)
  /// 
  /// **Example:**
  /// ```dart
  /// final chats = await repository.getUserChats(currentUser.id);
  /// // Returns all chats where user is participant
  /// ```
  Future<List<Chat>> getUserChats(String userId) async {
    try {
      // Query chats where user is either user1_id OR user2_id
      final response = await _supabase
          .from(_tableName)
          .select()
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('last_message_at', ascending: false, nullsFirst: false);
      
      return (response as List)
          .map((json) => Chat.fromJson(json as Map<String, dynamic>))
          .toList();
      
    } on PostgrestException catch (e) {
      throw ChatException(
        'Failed to load chats: ${e.message}',
        code: 'CHATS_FETCH_FAILED',
        technicalDetails: e.details,
      );
      
    } catch (e) {
      if (e is ChatException) rethrow;
      
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw const NetworkException();
      }
      
      throw ChatException(
        'Failed to load chats',
        code: 'CHATS_FETCH_FAILED',
        technicalDetails: e.toString(),
      );
    }
  }
  
  // =========================================================================
  // UPDATE CHAT
  // =========================================================================
  
  /// Update last message info
  /// 
  /// **Called after:** Sending a message
  /// 
  /// **Purpose:** Keep chat preview up to date
  /// 
  /// **Example:**
  /// ```dart
  /// await repository.updateLastMessage(
  ///   chatId: chat.id,
  ///   messageText: 'Hello!',
  ///   messageTime: DateTime.now(),
  /// );
  /// ```
  Future<void> updateLastMessage({
    required String chatId,
    required String messageText,
    required DateTime messageTime,
  }) async {
    try {
      await _supabase.from(_tableName).update({
        'last_message': messageText,
        'last_message_at': messageTime.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', chatId);
      
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const ChatNotFoundException();
      }
      throw ChatException(
        'Failed to update chat: ${e.message}',
        code: 'CHAT_UPDATE_FAILED',
        technicalDetails: e.details,
      );
      
    } catch (e) {
      if (e is ChatException) rethrow;
      
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw const NetworkException();
      }
      
      throw ChatException(
        'Failed to update chat',
        code: 'CHAT_UPDATE_FAILED',
        technicalDetails: e.toString(),
      );
    }
  }
  
  // =========================================================================
  // DELETE CHAT (Optional - for future)
  // =========================================================================
  
  /// Delete a chat (and all its messages via CASCADE)
  /// 
  /// **Warning:** Deletes all messages in chat!
  /// 
  /// **Note:** Consider "archive" instead of delete for UX
  Future<void> deleteChat(String chatId) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', chatId);
      
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const ChatNotFoundException();
      }
      throw ChatException(
        'Failed to delete chat: ${e.message}',
        code: 'CHAT_DELETE_FAILED',
        technicalDetails: e.details,
      );
      
    } catch (e) {
      if (e is ChatException) rethrow;
      
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw const NetworkException();
      }
      
      throw ChatException(
        'Failed to delete chat',
        code: 'CHAT_DELETE_FAILED',
        technicalDetails: e.toString(),
      );
    }
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================
//
// 1. GET OR CREATE CHAT:
// ```dart
// final repository = ChatRepository();
// 
// final chat = await repository.getOrCreateChat(
//   userId1: currentUser.id,
//   userId2: otherUser.id,
// );
// // Safe to call multiple times - returns same chat
// ```
//
// 2. GET USER'S CHATS (for chat list):
// ```dart
// final chats = await repository.getUserChats(currentUser.id);
// 
// for (final chat in chats) {
//   final otherUserId = chat.getOtherUserId(currentUser.id);
//   print('Chat with: $otherUserId');
//   print('Last message: ${chat.lastMessage}');
// }
// ```
//
// 3. UPDATE AFTER SENDING MESSAGE:
// ```dart
// // Send message
// final message = await messageRepository.sendMessage(...);
// 
// // Update chat preview
// await chatRepository.updateLastMessage(
//   chatId: chat.id,
//   messageText: message.message ?? '[Media]',
//   messageTime: message.createdAt,
// );
// ```
//
// 4. COMPLETE SEND MESSAGE FLOW:
// ```dart
// // 1. Get/create chat
// final chat = await chatRepository.getOrCreateChat(
//   userId1: senderId,
//   userId2: receiverId,
// );
// 
// // 2. Send message
// final message = await messageRepository.sendMessage(
//   chatId: chat.id,
//   senderId: senderId,
//   receiverId: receiverId,
//   text: 'Hello!',
// );
// 
// // 3. Update chat preview
// await chatRepository.updateLastMessage(
//   chatId: chat.id,
//   messageText: 'Hello!',
//   messageTime: message.createdAt,
// );
// 
// // This will happen in BLoC (Day 18) - handles all 3 steps!
// ```
//
// ============================================================================
