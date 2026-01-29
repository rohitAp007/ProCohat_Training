/// ============================================================================
/// CHAT SCREEN - REAL MESSAGING INTERFACE
/// ============================================================================
/// 
/// PURPOSE: Show messages and allow sending new messages
/// 
/// LEARNING: StatefulWidget with controllers + ChatBloc integration
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/features/chat/bloc/chat_bloc.dart';
import 'package:supabase_flutter_app/features/chat/bloc/chat_event.dart';
import 'package:supabase_flutter_app/features/chat/bloc/chat_state.dart';


import 'package:supabase_flutter_app/features/chat/data/chat_id_service.dart';
import 'package:supabase_flutter_app/features/chat/ui/widgets/message_bubble.dart';
import 'package:supabase_flutter_app/features/chat/ui/widgets/message_input.dart';
import 'package:supabase_flutter_app/features/chat/ui/widgets/date_separator.dart';
import 'package:supabase_flutter_app/features/chat/utils/chat_helpers.dart';

/// ChatScreen - Real-time messaging interface
/// 
/// **Architecture:**
/// ```
/// User types → Send → ChatBloc (optimistic) → Server → UI updates
/// ```
/// 
/// **Learning:**
/// - StatefulWidget for controllers
/// - BlocProvider for ChatBloc
/// - Reverse ListView (newest at bottom)
/// - Auto-scroll on new message
class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  
  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });
  
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Controllers
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  // Current user
  late final String _currentUserId;
  late final String _chatId;
  
  @override
  void initState() {
    super.initState();
    
    // Get current user
    _currentUserId = Supabase.instance.client.auth.currentUser!.id;
    
    // Generate chat ID
    final chatIdService = ChatIdService();
    _chatId = chatIdService.generateChatId(_currentUserId, widget.otherUserId);
    
    // Load chat history
    context.read<ChatBloc>().add(ChatHistoryLoadRequested(
      chatId: _chatId,
      otherUserId: widget.otherUserId,
    ));
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages list (expanded to fill space)
          Expanded(
            child: _buildMessagesArea(),
          ),
          
          // Input field (fixed at bottom)
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp background
    );
  }
  
  // =========================================================================
  // APP BAR
  // =========================================================================
  
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        widget.otherUserName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: const Color(0xFF075E54),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // TODO: Show menu
          },
        ),
      ],
    );
  }
  
  // =========================================================================
  // MESSAGES AREA (BlocBuilder)
  // =========================================================================
  
  Widget _buildMessagesArea() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        // LOADING STATE
        if (state is ChatLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF075E54),
            ),
          );
        }
        
        // ERROR STATE
        if (state is ChatError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                if (state.isRecoverable) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _retryLoad,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF075E54),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        
        // LOADED STATE - Show messages
        if (state is ChatLoaded) {
          return _buildMessagesList(state.messages);
        }
        
        // SENDING STATE - Show pending message too!
        if (state is ChatMessageSending) {
          final allMessages = [state.pendingMessage, ...state.messages];
          return _buildMessagesList(allMessages);
        }
        
        // DEFAULT: Empty state
        return _buildEmptyState();
      },
    );
  }
  
  // =========================================================================
  // MESSAGES LIST (Reverse ListView with Grouping)
  // =========================================================================
  
  Widget _buildMessagesList(List messages) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      reverse: true,  // IMPORTANT: Newest at bottom!
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == _currentUserId;
        
        // Get previous message for grouping logic
        // (In reverse list, previous = next index)
        final previousMessage = index < messages.length - 1 
            ? messages[index + 1] 
            : null;
        
        // Get next message for date separator
        // (In reverse list, next = previous index)  
        final nextMessage = index > 0 
            ? messages[index - 1] 
            : null;
        
        // Determine if we should group with previous message
        final shouldGroup = previousMessage != null &&
            ChatHelpers.shouldGroupMessages(
              previous: previousMessage,
              current: message,
            );
        
        // Determine if date separator needed
        final needsDateSep = ChatHelpers.needsDateSeparator(
          previousDate: nextMessage?.createdAt,
          currentDate: message.createdAt,
        );
        
        return Column(
          children: [
            // Date separator (if needed)
            if (needsDateSep)
              DateSeparator(date: message.createdAt),
            
            // Message bubble
            MessageBubble(
              message: message,
              isMe: isMe,
              showAvatar: !shouldGroup,  // Hide avatar if grouped
            ),
          ],
        );
      },
    );
  }
  
  // =========================================================================
  // EMPTY STATE
  // =========================================================================
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start chatting!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  // =========================================================================
  // SEND MESSAGE
  // =========================================================================
  
  void _sendMessage() {
    final text = _messageController.text.trim();
    
    // Validate
    if (text.isEmpty) return;
    
    // Dispatch event to ChatBloc
    context.read<ChatBloc>().add(ChatMessageSendRequested(
      text: text,
      receiverId: widget.otherUserId,
    ));
    
    // Clear input
    _messageController.clear();
    
    // Scroll to bottom (show new message)
    _scrollToBottom();
  }
  
  // =========================================================================
  // HELPERS
  // =========================================================================
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,  // 0 in reverse list = bottom
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  void _retryLoad() {
    context.read<ChatBloc>().add(ChatHistoryLoadRequested(
      chatId: _chatId,
      otherUserId: widget.otherUserId,
    ));
  }
}

// ============================================================================
// USAGE WITH BLOCPROVIDER
// ============================================================================
//
// WRAP WITH BLOCPROVIDER:
// ```dart
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (_) => BlocProvider(
//       create: (_) => ChatBloc(
//         messageRepository: MessageRepository(),
//         chatRepository: ChatRepository(),
//         currentUserId: Supabase.instance.client.auth.currentUser!.id,
//       ),
//       child: ChatScreen(
//         otherUserId: user.userId,
//         otherUserName: user.fullName,
//       ),
//     ),
//   ),
// );
// ```
//
// ============================================================================
