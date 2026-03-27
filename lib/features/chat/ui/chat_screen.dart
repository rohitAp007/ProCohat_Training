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
import 'package:path/path.dart' as path;
import 'package:supabase_flutter_app/features/chat/bloc/chat_bloc.dart';
import 'package:supabase_flutter_app/features/chat/bloc/chat_event.dart';
import 'package:supabase_flutter_app/features/chat/bloc/chat_state.dart';
import 'package:supabase_flutter_app/features/chat/ui/profile_detail_screen.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_bloc.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_event.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_state.dart';
import 'package:supabase_flutter_app/features/profile/data/profile_repository.dart';
import 'package:supabase_flutter_app/features/chat/data/storage_service.dart';

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
  final String? quickShareImagePath; // Optional quick share photo
  
  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.quickShareImagePath,
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
          
          // Input field with multimedia support
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            onImageSelected: (path) => _sendMediaMessage(path, 'image'),
            onVideoSelected: (path) => _sendMediaMessage(path, 'video'),
            onFileSelected: (path, name) => _sendMediaMessage(path, 'file', fileName: name),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp background
    );
  }
  
  // =========================================================================
  // SEND MEDIA MESSAGE
  // =========================================================================
  
  void _sendMediaMessage(String filePath, String mediaType, {String? fileName}) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploading ${mediaType}...')),
      );
      
      // Upload to storage
      final storageService = StorageService();
      String mediaUrl;
      
      switch (mediaType) {
        case 'image':
          mediaUrl = await storageService.uploadImage(filePath, _currentUserId);
          break;
        case 'video':
          mediaUrl = await storageService.uploadVideo(filePath, _currentUserId);
          break;
        case 'file':
          mediaUrl = await storageService.uploadFile(filePath, _currentUserId);
          break;
        default:
          return;
      }
      
      // Get file size and name
      final fileSize = storageService.getFileSize(filePath);
      final actualFileName = fileName ?? path.basename(filePath);
      
      // Send message with media
      context.read<ChatBloc>().add(ChatMediaMessageSendRequested(
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        fileName: actualFileName,
        fileSize: fileSize,
        receiverId: widget.otherUserId,
      ));
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${mediaType.toUpperCase().substring(0, 1)}${mediaType.substring(1)} sent!')),
      );
      
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  // =========================================================================
  // APP BAR
  // =========================================================================
  
  AppBar _buildAppBar() {
    return AppBar(
      title: GestureDetector(
        onTap: () {
          // Open profile detail screen with new ProfileBloc
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => ProfileBloc(
                  repository: ProfileRepository(),
                )..add(ProfileLoadRequested(userId: widget.otherUserId)),
                child: ProfileDetailScreen(
                  userId: widget.otherUserId,
                  userName: widget.otherUserName,
                ),
              ),
            ),
          );
        },
        child: Text(
          widget.otherUserName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      backgroundColor: const Color(0xFF075E54),
      elevation: 0,
      actions: [
        // Voice call button
        IconButton(
          icon: const Icon(Icons.call),
          onPressed: () => _initiateVoiceCall(),
          tooltip: 'Voice call',
        ),
        // Video call button
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: () => _initiateVideoCall(),
          tooltip: 'Video call',
        ),
        // Three-dot menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            _handleMenuAction(value);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 12),
                  Text('View Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep, size: 20),
                  SizedBox(width: 12),
                  Text('Clear Chat'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete Chat', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, size: 20, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Block User', style: TextStyle(color: Colors.orange)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.report, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Report', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => ProfileBloc(
                repository: ProfileRepository(),
              )..add(ProfileLoadRequested(userId: widget.otherUserId)),
              child: ProfileDetailScreen(
                userId: widget.otherUserId,
                userName: widget.otherUserName,
              ),
            ),
          ),
        );
        break;
      case 'clear':
        _showClearChatDialog();
        break;
      case 'delete':
        _showDeleteChatDialog();
        break;
      case 'block':
        _showBlockDialog();
        break;
      case 'report':
        _showReportDialog();
        break;
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear Chat'),
        content: Text('Delete all messages in this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement clear chat
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chat cleared')),
              );
            },
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteChatDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Chat'),
        content: Text('Delete this chat permanently? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement delete chat
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to chat list
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chat deleted')),
              );
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block User'),
        content: Text('Block ${widget.otherUserName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement block
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('User blocked')),
              );
            },
            child: Text('Block', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Report User'),
        content: Text('Report ${widget.otherUserName} for inappropriate behavior?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement report
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('User reported')),
              );
            },
            child: Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _initiateVoiceCall() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.call, color: Color(0xFF075E54)),
            SizedBox(width: 8),
            Text('Voice Call'),
          ],
        ),
        content: Text('Calling ${widget.otherUserName}...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('End Call', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _initiateVideoCall() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.videocam, color: Color(0xFF075E54)),
            SizedBox(width: 8),
            Text('Video Call'),
          ],
        ),
        content: Text('Video calling ${widget.otherUserName}...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('End Call', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
