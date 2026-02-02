/// ============================================================================
/// BROADCAST REPOSITORY - DATA ACCESS FOR BROADCAST OPERATIONS
/// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/core/utils/app_logger.dart';
import 'package:supabase_flutter_app/features/chat/data/chat_repository.dart';
import 'package:supabase_flutter_app/features/chat/data/message_repository.dart';
import 'broadcast_list_model.dart';
import 'broadcast_recipient_model.dart';
import 'broadcast_message_model.dart';
import 'broadcast_exceptions.dart';

/// BroadcastRepository - Handles broadcast list and message operations
/// 
/// **Architecture:**
/// - Creates individual 1-to-1 messages for each recipient
/// - Leverages existing chat infrastructure
/// - Tracks delivery status per recipient
class BroadcastRepository {
  final SupabaseClient _supabase;
  final ChatRepository _chatRepository;
  final MessageRepository _messageRepository;
  
  static const String _listsTable = 'broadcast_lists';
  static const String _recipientsTable = 'broadcast_recipients';
  static const String _messagesTable = 'broadcast_messages';
  static const String _deliveriesTable = 'broadcast_deliveries';
  
  BroadcastRepository({
    SupabaseClient? supabaseClient,
    ChatRepository? chatRepository,
    MessageRepository? messageRepository,
  })  : _supabase = supabaseClient ?? Supabase.instance.client,
        _chatRepository = chatRepository ?? ChatRepository(),
        _messageRepository = messageRepository ?? MessageRepository();
  
  // =========================================================================
  // CREATE BROADCAST LIST
  // =========================================================================
  
  /// Create a new broadcast list with recipients
  Future<BroadcastList> createBroadcastList({
    required String name,
    required List<String> recipientIds,
  }) async {
    // Validate inputs
    if (name.trim().isEmpty) {
      throw const InvalidBroadcastNameException();
    }
    
    if (recipientIds.isEmpty) {
      throw const EmptyRecipientListException();
    }
    
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw const BroadcastPermissionException('User not authenticated');
      }
      
      final now = DateTime.now();
      
      // Create broadcast list
      final listData = {
        'owner_id': currentUser.id,
        'name': name.trim(),
        'recipient_count': recipientIds.length,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      
      final listResponse = await _supabase
          .from(_listsTable)
          .insert(listData)
          .select()
          .single();
      
      final list = BroadcastList.fromJson(listResponse);
      
      // Add recipients
      await addRecipients(
        broadcastListId: list.id,
        recipientIds: recipientIds,
      );
      
      AppLogger.info('Created broadcast list: ${list.name}', tag: 'BROADCAST');
      return list;
      
    } on PostgrestException catch (e) {
      AppLogger.error('Failed to create broadcast list', error: e, tag: 'BROADCAST');
      throw UnknownBroadcastException(
        'Failed to create broadcast list: ${e.message}',
      );
    } catch (e) {
      if (e is BroadcastException) rethrow;
      
      if (e.toString().toLowerCase().contains('network')) {
        throw const BroadcastNetworkException();
      }
      
      throw UnknownBroadcastException(e.toString());
    }
  }
  
  // =========================================================================
  // GET BROADCAST LISTS
  // =========================================================================
  
  /// Get all broadcast lists for current user
  Future<List<BroadcastList>> getUserBroadcastLists() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw const BroadcastPermissionException('User not authenticated');
      }
      
      final response = await _supabase
          .from(_listsTable)
          .select()
          .eq('owner_id', currentUser.id)
          .order('updated_at', ascending: false);
      
      return (response as List)
          .map((json) => BroadcastList.fromJson(json as Map<String, dynamic>))
          .toList();
          
    } on PostgrestException catch (e) {
      AppLogger.error('Failed to fetch broadcast lists', error: e, tag: 'BROADCAST');
      throw UnknownBroadcastException('Failed to fetch broadcast lists: ${e.message}');
    } catch (e) {
      if (e is BroadcastException) rethrow;
      
      if (e.toString().toLowerCase().contains('network')) {
        throw const BroadcastNetworkException();
      }
      
      throw UnknownBroadcastException(e.toString());
    }
  }
  
  /// Get single broadcast list by ID
  Future<BroadcastList> getBroadcastList(String listId) async {
    try {
      final response = await _supabase
          .from(_listsTable)
          .select()
          .eq('id', listId)
          .maybeSingle();
      
      if (response == null) {
        throw const BroadcastListNotFoundException();
      }
      
      return BroadcastList.fromJson(response);
      
    } on PostgrestException catch (e) {
      AppLogger.error('Failed to fetch broadcast list', error: e, tag: 'BROADCAST');
      throw UnknownBroadcastException('Failed to fetch broadcast list: ${e.message}');
    } catch (e) {
      if (e is BroadcastException) rethrow;
      throw UnknownBroadcastException(e.toString());
    }
  }
  
  // =========================================================================
  // UPDATE BROADCAST LIST
  // =========================================================================
  
  /// Update broadcast list name
  Future<BroadcastList> updateBroadcastList({
    required String listId,
    required String newName,
  }) async {
    if (newName.trim().isEmpty) {
      throw const InvalidBroadcastNameException();
    }
    
    try {
      final updateData = {
        'name': newName.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final response = await _supabase
          .from(_listsTable)
          .update(updateData)
          .eq('id', listId)
          .select()
          .single();
      
      AppLogger.info('Updated broadcast list name', tag: 'BROADCAST');
      return BroadcastList.fromJson(response);
      
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const BroadcastListNotFoundException();
      }
      throw UnknownBroadcastException('Failed to update broadcast list: ${e.message}');
    } catch (e) {
      if (e is BroadcastException) rethrow;
      throw UnknownBroadcastException(e.toString());
    }
  }
  
  // =========================================================================
  // DELETE BROADCAST LIST
  // =========================================================================
  
  /// Delete broadcast list (and all recipients, messages via CASCADE)
  Future<void> deleteBroadcastList(String listId) async {
    try {
      await _supabase
          .from(_listsTable)
          .delete()
          .eq('id', listId);
      
      AppLogger.info('Deleted broadcast list', tag: 'BROADCAST');
      
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const BroadcastListNotFoundException();
      }
      throw UnknownBroadcastException('Failed to delete broadcast list: ${e.message}');
    } catch (e) {
      if (e is BroadcastException) rethrow;
      throw UnknownBroadcastException(e.toString());
    }
  }
  
  // =========================================================================
  // MANAGE RECIPIENTS
  // =========================================================================
  
  /// Add recipients to broadcast list
  Future<void> addRecipients({
    required String broadcastListId,
    required List<String> recipientIds,
  }) async {
    if (recipientIds.isEmpty) return;
    
    try {
      final now = DateTime.now();
      final recipientData = recipientIds.map((recipientId) => {
        'broadcast_list_id': broadcastListId,
        'recipient_id': recipientId,
        'added_at': now.toIso8601String(),
      }).toList();
      
      await _supabase.from(_recipientsTable).insert(recipientData);
      
      // Update recipient count
      await _updateRecipientCount(broadcastListId);
      
      AppLogger.info('Added ${recipientIds.length} recipients', tag: 'BROADCAST');
      
    } on PostgrestException catch (e) {
      if (e.code == '23505') {  // Unique violation
        throw const DuplicateRecipientException();
      }
      throw UnknownBroadcastException('Failed to add recipients: ${e.message}');
    } catch (e) {
      if (e is BroadcastException) rethrow;
      throw UnknownBroadcastException(e.toString());
    }
  }
  
  /// Remove recipient from broadcast list
  Future<void> removeRecipient({
    required String broadcastListId,
    required String recipientId,
  }) async {
    try {
      await _supabase
          .from(_recipientsTable)
          .delete()
          .eq('broadcast_list_id', broadcastListId)
          .eq('recipient_id', recipientId);
      
      // Update recipient count
      await _updateRecipientCount(broadcastListId);
      
      AppLogger.info('Removed recipient from list', tag: 'BROADCAST');
      
    } on PostgrestException catch (e) {
      throw UnknownBroadcastException('Failed to remove recipient: ${e.message}');
    } catch (e) {
      if (e is BroadcastException) rethrow;
      throw UnknownBroadcastException(e.toString());
    }
  }
  
  /// Get all recipients for a broadcast list
  Future<List<BroadcastRecipient>> getListRecipients(String broadcastListId) async {
    try {
      final response = await _supabase
          .from(_recipientsTable)
          .select()
          .eq('broadcast_list_id', broadcastListId)
          .order('added_at', ascending: true);
      
      return (response as List)
          .map((json) => BroadcastRecipient.fromJson(json as Map<String, dynamic>))
          .toList();
          
    } on PostgrestException catch (e) {
      throw UnknownBroadcastException('Failed to fetch recipients: ${e.message}');
    } catch (e) {
      if (e is BroadcastException) rethrow;
      throw UnknownBroadcastException(e.toString());
    }
  }
  
  /// Update recipient count cache
  Future<void> _updateRecipientCount(String broadcastListId) async {
    final recipients = await getListRecipients(broadcastListId);
    
    await _supabase
        .from(_listsTable)
        .update({
          'recipient_count': recipients.length,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', broadcastListId);
  }
  
  // =========================================================================
  // SEND BROADCAST MESSAGE
  // =========================================================================
  
  /// Send broadcast message to all recipients in list
  /// 
  /// **Process:**
  /// 1. Validate list exists and has recipients
  /// 2. Create broadcast message record
  /// 3. For each recipient:
  ///    - Get or create 1-to-1 chat
  ///    - Send individual message
  ///    - Track delivery
  /// 4. Update list's last_broadcast_at
  Future<BroadcastMessage> sendBroadcastMessage({
    required String broadcastListId,
    String? message,
    String? mediaUrl,
  }) async {
    // Validate message
    if ((message == null || message.trim().isEmpty) && 
        (mediaUrl == null || mediaUrl.trim().isEmpty)) {
      throw const BroadcastSendFailedException('Message cannot be empty');
    }
    
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw const BroadcastPermissionException('User not authenticated');
      }
      
      // Get recipients
      final recipients = await getListRecipients(broadcastListId);
      if (recipients.isEmpty) {
        throw const EmptyRecipientListException();
      }
      
      final now = DateTime.now();
      
      // Create broadcast message record
      final broadcastMessageData = {
        'broadcast_list_id': broadcastListId,
        'sender_id': currentUser.id,
        'message': message?.trim(),
        'media_url': mediaUrl?.trim(),
        'total_recipients': recipients.length,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      
      final broadcastMessageResponse = await _supabase
          .from(_messagesTable)
          .insert(broadcastMessageData)
          .select()
          .single();
      
      final broadcastMessage = BroadcastMessage.fromJson(broadcastMessageResponse);
      
      AppLogger.info(
        'Sending broadcast to ${recipients.length} recipients',
        tag: 'BROADCAST',
      );
      
      // Send individual messages to each recipient
      int successCount = 0;
      for (final recipient in recipients) {
        try {
          // Get or create 1-to-1 chat
          final chat = await _chatRepository.getOrCreateChat(
            userId1: currentUser.id,
            userId2: recipient.recipientId,
          );
          
          // Send individual message
          final individualMessage = await _messageRepository.sendMessage(
            chatId: chat.id,
            senderId: currentUser.id,
            receiverId: recipient.recipientId,
            text: message,
            mediaUrl: mediaUrl,
          );
          
          // Track delivery
          await _trackDelivery(
            broadcastMessageId: broadcastMessage.id,
            recipientId: recipient.recipientId,
            chatId: chat.id,
            messageId: individualMessage.id,
          );
          
          successCount++;
          
        } catch (e) {
          AppLogger.error(
            'Failed to send to recipient ${recipient.recipientId}',
            error: e,
            tag: 'BROADCAST',
          );
          // Continue sending to other recipients
        }
      }
      
      if (successCount == 0) {
        throw const BroadcastSendFailedException('Failed to send to any recipients');
      }
      
      // Update list's last broadcast time
      await _supabase
          .from(_listsTable)
          .update({
            'last_broadcast_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', broadcastListId);
      
      AppLogger.info(
        'Broadcast sent successfully to $successCount/${recipients.length} recipients',
        tag: 'BROADCAST',
      );
      
      return broadcastMessage.copyWith(deliveredCount: successCount);
      
    } on PostgrestException catch (e) {
      AppLogger.error('Failed to send broadcast', error: e, tag: 'BROADCAST');
      throw BroadcastSendFailedException(e.message);
    } catch (e) {
      if (e is BroadcastException) rethrow;
      
      if (e.toString().toLowerCase().contains('network')) {
        throw const BroadcastNetworkException();
      }
      
      throw UnknownBroadcastException(e.toString());
    }
  }
  
  /// Track message delivery for recipient
  Future<void> _trackDelivery({
    required String broadcastMessageId,
    required String recipientId,
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _supabase.from(_deliveriesTable).insert({
        'broadcast_message_id': broadcastMessageId,
        'recipient_id': recipientId,
        'chat_id': chatId,
        'message_id': messageId,
        'delivered_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.warning('Failed to track delivery', tag: 'BROADCAST');
      // Don't throw - delivery tracking is not critical
    }
  }
  
  // =========================================================================
  // GET BROADCAST MESSAGES
  // =========================================================================
  
  /// Get broadcast message history for a list
  Future<List<BroadcastMessage>> getBroadcastMessages(String broadcastListId) async {
    try {
      final response = await _supabase
          .from(_messagesTable)
          .select()
          .eq('broadcast_list_id', broadcastListId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => BroadcastMessage.fromJson(json as Map<String, dynamic>))
          .toList();
          
    } on PostgrestException catch (e) {
      throw UnknownBroadcastException('Failed to fetch broadcast messages: ${e.message}');
    } catch (e) {
      if (e is BroadcastException) rethrow;
      throw UnknownBroadcastException(e.toString());
    }
  }
}
