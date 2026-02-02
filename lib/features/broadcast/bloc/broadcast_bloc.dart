/// ============================================================================
/// BROADCAST BLOC - BUSINESS LOGIC FOR BROADCAST FEATURE
/// ============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter_app/core/utils/app_logger.dart';
import '../data/broadcast_repository.dart';
import '../data/broadcast_exceptions.dart';
import 'broadcast_event.dart';
import 'broadcast_state.dart';

/// BroadcastBloc - Handles business logic for broadcast operations
/// 
/// **Architecture:**
/// - User actions → Events
/// - Events → Event Handlers
/// - Event Handlers → Repository calls
/// - Repository results → States
/// - States → UI updates
class BroadcastBloc extends Bloc<BroadcastEvent, BroadcastState> {
  final BroadcastRepository _repository;
  
  BroadcastBloc({
    required BroadcastRepository repository,
  })  : _repository = repository,
        super(const BroadcastInitial()) {
    // Register event handlers
    on<BroadcastListsRequested>(_onBroadcastListsRequested);
    on<BroadcastListCreated>(_onBroadcastListCreated);
    on<BroadcastListUpdated>(_onBroadcastListUpdated);
    on<BroadcastListDeleted>(_onBroadcastListDeleted);
    on<BroadcastListDetailsRequested>(_onBroadcastListDetailsRequested);
    on<BroadcastRecipientsAdded>(_onBroadcastRecipientsAdded);
    on<BroadcastRecipientRemoved>(_onBroadcastRecipientRemoved);
    on<BroadcastRecipientsRequested>(_onBroadcastRecipientsRequested);
    on<BroadcastMessageSent>(_onBroadcastMessageSent);
    on<BroadcastMessagesRequested>(_onBroadcastMessagesRequested);
    on<BroadcastStateReset>(_onBroadcastStateReset);
  }
  
  // ===========================================================================
  // BROADCAST LIST HANDLERS
  // ===========================================================================
  
  /// Handle loading user's broadcast lists
  Future<void> _onBroadcastListsRequested(
    BroadcastListsRequested event,
    Emitter<BroadcastState> emit,
  ) async {
    try {
      emit(const BroadcastListsLoading());
      
      final lists = await _repository.getUserBroadcastLists();
      
      emit(BroadcastListsLoaded(lists));
      AppLogger.info('Loaded ${lists.length} broadcast lists', tag: 'BROADCAST_BLOC');
      
    } on BroadcastException catch (e) {
      AppLogger.error('Failed to load broadcast lists', error: e, tag: 'BROADCAST_BLOC');
      emit(BroadcastError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error loading lists', error: e, tag: 'BROADCAST_BLOC');
      emit(const BroadcastError(message: 'Failed to load broadcast lists'));
    }
  }
  
  /// Handle creating new broadcast list
  Future<void> _onBroadcastListCreated(
    BroadcastListCreated event,
    Emitter<BroadcastState> emit,
  ) async {
    try {
      emit(const BroadcastListsLoading());
      
      final list = await _repository.createBroadcastList(
        name: event.name,
        recipientIds: event.recipientIds,
      );
      
      emit(BroadcastListCreateSuccess(list));
      AppLogger.info('Created broadcast list: ${list.name}', tag: 'BROADCAST_BLOC');
      
      // Reload lists
      add(const BroadcastListsRequested());
      
    } on InvalidBroadcastNameException catch (e) {
      emit(BroadcastError(message: e.message));
    } on EmptyRecipientListException catch (e) {
      emit(BroadcastError(message: e.message));
    } on BroadcastException catch (e) {
      AppLogger.error('Failed to create broadcast list', error: e, tag: 'BROADCAST_BLOC');
      emit(BroadcastError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error creating list', error: e, tag: 'BROADCAST_BLOC');
      emit(const BroadcastError(message: 'Failed to create broadcast list'));
    }
  }
  
  /// Handle updating broadcast list name
  Future<void> _onBroadcastListUpdated(
    BroadcastListUpdated event,
    Emitter<BroadcastState> emit,
  ) async {
    try {
      final list = await _repository.updateBroadcastList(
        listId: event.listId,
        newName: event.newName,
      );
      
      emit(BroadcastListUpdateSuccess(list));
      AppLogger.info('Updated broadcast list name', tag: 'BROADCAST_BLOC');
      
      // Reload lists
      add(const BroadcastListsRequested());
      
    } on InvalidBroadcastNameException catch (e) {
      emit(BroadcastError(message: e.message));
    } on BroadcastListNotFoundException catch (e) {
      emit(BroadcastError(message: e.message));
    } on BroadcastException catch (e) {
      AppLogger.error('Failed to update broadcast list', error: e, tag: 'BROADCAST_BLOC');
      emit(BroadcastError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error updating list', error: e, tag: 'BROADCAST_BLOC');
      emit(const BroadcastError(message: 'Failed to update broadcast list'));
    }
  }
  
  /// Handle deleting broadcast list
  Future<void> _onBroadcastListDeleted(
    BroadcastListDeleted event,
    Emitter<BroadcastState> emit,
  ) async {
    try {
      await _repository.deleteBroadcastList(event.listId);
      
      emit(BroadcastListDeleteSuccess(event.listId));
      AppLogger.info('Deleted broadcast list', tag: 'BROADCAST_BLOC');
      
      // Reload lists
      add(const BroadcastListsRequested());
      
    } on BroadcastListNotFoundException catch (e) {
      emit(BroadcastError(message: e.message));
    } on BroadcastException catch (e) {
      AppLogger.error('Failed to delete broadcast list', error: e, tag: 'BROADCAST_BLOC');
      emit(BroadcastError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error deleting list', error: e, tag: 'BROADCAST_BLOC');
      emit(const BroadcastError(message: 'Failed to delete broadcast list'));
    }
  }
  
  /// Handle loading specific broadcast list details
  Future<void> _onBroadcastListDetailsRequested(
    BroadcastListDetailsRequested event,
    Emitter<BroadcastState> emit,
  ) async {
    try {
      emit(const BroadcastListLoading());
      
      final list = await _repository.getBroadcastList(event.listId);
      final recipients = await _repository.getListRecipients(event.listId);
      
      emit(BroadcastListLoaded(list: list, recipients: recipients));
      AppLogger.info('Loaded broadcast list details', tag: 'BROADCAST_BLOC');
      
    } on BroadcastListNotFoundException catch (e) {
      emit(BroadcastError(message: e.message));
    } on BroadcastException catch (e) {
      AppLogger.error('Failed to load list details', error: e, tag: 'BROADCAST_BLOC');
      emit(BroadcastError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error loading list details', error: e, tag: 'BROADCAST_BLOC');
      emit(const BroadcastError(message: 'Failed to load broadcast list'));
    }
  }
  
  // ===========================================================================
  // RECIPIENT MANAGEMENT HANDLERS
  // ===========================================================================
  
  /// Handle adding recipients to broadcast list
  Future<void> _onBroadcastRecipientsAdded(
    BroadcastRecipientsAdded event,
    Emitter<BroadcastState> emit,
  ) async {
    try {
      await _repository.addRecipients(
        broadcastListId: event.listId,
        recipientIds: event.recipientIds,
      );
      
      emit(BroadcastRecipientsAddSuccess(
        listId: event.listId,
        addedCount: event.recipientIds.length,
      ));
      AppLogger.info('Added ${event.recipientIds.length} recipients', tag: 'BROADCAST_BLOC');
      
      // Reload list details
      add(BroadcastListDetailsRequested(event.listId));
      
    } on DuplicateRecipientException catch (e) {
      emit(BroadcastError(message: e.message));
    } on BroadcastException catch (e) {
      AppLogger.error('Failed to add recipients', error: e, tag: 'BROADCAST_BLOC');
      emit(BroadcastError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error adding recipients', error: e, tag: 'BROADCAST_BLOC');
      emit(const BroadcastError(message: 'Failed to add recipients'));
    }
  }
  
  /// Handle removing recipient from broadcast list
  Future<void> _onBroadcastRecipientRemoved(
    BroadcastRecipientRemoved event,
    Emitter<BroadcastState> emit,
  ) async {
    try {
      await _repository.removeRecipient(
        broadcastListId: event.listId,
        recipientId: event.recipientId,
      );
      
      emit(BroadcastRecipientRemoveSuccess(
        listId: event.listId,
        recipientId: event.recipientId,
      ));
      AppLogger.info('Removed recipient from list', tag: 'BROADCAST_BLOC');
      
      // Reload list details
      add(BroadcastListDetailsRequested(event.listId));
      
    } on BroadcastException catch (e) {
      AppLogger.error('Failed to remove recipient', error: e, tag: 'BROADCAST_BLOC');
      emit(BroadcastError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error removing recipient', error: e, tag: 'BROADCAST_BLOC');
      emit(const BroadcastError(message: 'Failed to remove recipient'));
    }
  }
  
  /// Handle loading recipients for a list
  Future<void> _onBroadcastRecipientsRequested(
    BroadcastRecipientsRequested event,
    Emitter<BroadcastState> emit,
  ) async {
    try {
      emit(const BroadcastRecipientsLoading());
      
      final recipients = await _repository.getListRecipients(event.listId);
      
      emit(BroadcastRecipientsLoaded(recipients));
      AppLogger.info('Loaded ${recipients.length} recipients', tag: 'BROADCAST_BLOC');
      
    } on BroadcastException catch (e) {
      AppLogger.error('Failed to load recipients', error: e, tag: 'BROADCAST_BLOC');
      emit(BroadcastError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error loading recipients', error: e, tag: 'BROADCAST_BLOC');
      emit(const BroadcastError(message: 'Failed to load recipients'));
    }
  }
  
  // ===========================================================================
  // BROADCAST MESSAGE HANDLERS
  // ===========================================================================
  
  /// Handle sending broadcast message
  Future<void> _onBroadcastMessageSent(
    BroadcastMessageSent event,
    Emitter<BroadcastState> emit,
  ) async {
    try {
      // Get recipients count first
      final recipients = await _repository.getListRecipients(event.listId);
      
      emit(BroadcastSending(totalRecipients: recipients.length));
      AppLogger.info('Starting broadcast to ${recipients.length} recipients', tag: 'BROADCAST_BLOC');
      
      // Send broadcast
      final message = await _repository.sendBroadcastMessage(
        broadcastListId: event.listId,
        message: event.message,
        mediaUrl: event.mediaUrl,
      );
      
      emit(BroadcastSent(
        message: message,
        successfulDeliveries: message.deliveredCount,
        totalRecipients: message.totalRecipients,
      ));
      
      AppLogger.info(
        'Broadcast sent: ${message.deliveredCount}/${message.totalRecipients}',
        tag: 'BROADCAST_BLOC',
      );
      
    } on EmptyRecipientListException catch (e) {
      emit(BroadcastError(message: e.message));
    } on BroadcastSendFailedException catch (e) {
      AppLogger.error('Failed to send broadcast', error: e, tag: 'BROADCAST_BLOC');
      emit(BroadcastError(message: e.message));
    } on BroadcastException catch (e) {
      AppLogger.error('Broadcast error', error: e, tag: 'BROADCAST_BLOC');
      emit(BroadcastError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error sending broadcast', error: e, tag: 'BROADCAST_BLOC');
      emit(const BroadcastError(message: 'Failed to send broadcast message'));
    }
  }
  
  /// Handle loading broadcast message history
  Future<void> _onBroadcastMessagesRequested(
    BroadcastMessagesRequested event,
    Emitter<BroadcastState> emit,
  ) async {
    try {
      emit(const BroadcastMessagesLoading());
      
      final messages = await _repository.getBroadcastMessages(event.listId);
      
      emit(BroadcastMessagesLoaded(messages));
      AppLogger.info('Loaded ${messages.length} broadcast messages', tag: 'BROADCAST_BLOC');
      
    } on BroadcastException catch (e) {
      AppLogger.error('Failed to load messages', error: e, tag: 'BROADCAST_BLOC');
      emit(BroadcastError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error loading messages', error: e, tag: 'BROADCAST_BLOC');
      emit(const BroadcastError(message: 'Failed to load broadcast messages'));
    }
  }
  
  // ===========================================================================
  // STATE MANAGEMENT
  // ===========================================================================
  
  /// Handle resetting state
  Future<void> _onBroadcastStateReset(
    BroadcastStateReset event,
    Emitter<BroadcastState> emit,
  ) async {
    emit(const BroadcastInitial());
    AppLogger.debug('Broadcast state reset', tag: 'BROADCAST_BLOC');
  }
}
