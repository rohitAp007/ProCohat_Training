/// ============================================================================
/// MESSAGE BUBBLE WIDGET
/// ============================================================================
/// 
/// PURPOSE: Display individual message with sender/receiver styling
/// 
/// LEARNING: Conditional styling based on sender
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter_app/features/chat/data/message_model.dart';
import 'package:supabase_flutter_app/features/chat/utils/chat_constants.dart';
import 'package:supabase_flutter_app/features/chat/utils/chat_helpers.dart';
import 'package:supabase_flutter_app/features/chat/ui/image_viewer_screen.dart';
import 'package:supabase_flutter_app/features/chat/ui/video_player_screen.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// MessageBubble - Individual message display
/// 
/// **Styling based on sender:**
/// - isMe = true → Green bubble, right-aligned
/// - isMe = false → White bubble, left-aligned
/// 
/// **Message Grouping:**
/// - showAvatar = true → Show avatar (first in group)
/// - showAvatar = false → Hide avatar (grouped message)
/// 
/// **Why Grouping?**
/// Consecutive messages from same sender don't need repeated avatars.
/// This reduces visual clutter and looks cleaner (WhatsApp pattern).
/// 
/// **Example:**
/// ```
/// [Avatar] John: Hey!         ← showAvatar = true (first)
///          John: How are you? ← showAvatar = false (grouped)
///          John: What's up?   ← showAvatar = false (grouped)
/// 
/// [Avatar] You: I'm good!     ← showAvatar = true (sender changed)
/// ```
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;  // NEW: Control avatar visibility
  
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,  // Default: show avatar
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for received messages (left side)
          if (!isMe && showAvatar)
            _buildAvatar()
          else if (!isMe && !showAvatar)
            const SizedBox(width: 40), // Spacer to align grouped messages
          
          // Message bubble
          Flexible(
            child: Container(
              margin: EdgeInsets.symmetric( // Removed const
                vertical: 2, 
                horizontal: showAvatar ? 8 : 4,
              ),
              padding: ChatConstants.messagePadding,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? ChatConstants.senderBubbleColor
                    : ChatConstants.receiverBubbleColor,
                borderRadius: BorderRadius.circular(
                  ChatConstants.bubbleBorderRadius,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Media display (images, videos, files)
                  if (message.mediaUrl != null && message.mediaType != null)
                    _buildMediaWidget(),
                  
                  // Message text (if present)
                  if (message.message != null && message.message!.isNotEmpty && message.message != '[IMAGE]' && message.message != '[VIDEO]' && message.message != '[FILE]')
                    Padding(
                      padding: EdgeInsets.only(top: message.mediaUrl != null ? 8.0 : 0),
                      child: Text(
                        message.message!,
                        style: ChatConstants.messageTextStyle,
                      ),
                    ),
                  
                  const SizedBox(height: 4),
                  
                  // Timestamp and status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ChatHelpers.formatMessageTime(message.createdAt),
                        style: ChatConstants.timestampTextStyle,
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Avatar for sent messages (right side) - optional
          // Usually we don't show avatar for own messages in chat apps
        ],
      ),
    );
  }
  
  // =========================================================================
  // STATUS ICON (WhatsApp-style ticks)
  // =========================================================================
  
  Widget _buildStatusIcon() {
    IconData iconData;
    Color iconColor;
    
    switch (message.status) {
      case 'read':
        // Blue double check marks
        iconData = Icons.done_all;
        iconColor = const Color(0xFF53BDEB); // WhatsApp blue
        break;
      case 'delivered':
        // Grey double check marks
        iconData = Icons.done_all;
        iconColor = Colors.grey;
        break;
      case 'sent':
      default:
        // Single grey check mark
        iconData = Icons.done;
        iconColor = Colors.grey;
        break;
    }
    
    return Icon(
      iconData,
      size: 16,
      color: iconColor,
    );
  }
  
  // =========================================================================
  // MEDIA WIDGET (Images, Videos, Files)
  // =========================================================================
  
  Widget _buildMediaWidget() {
    if (message.mediaType == 'image') {
      return _buildImageWidget();
    } else if (message.mediaType == 'video') {
      return _buildVideoWidget();
    } else if (message.mediaType == 'file') {
      return _buildFileWidget();
    }
    return const SizedBox.shrink();
  }
  
  Widget _buildImageWidget() {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _openImageViewer(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: message.mediaUrl!,
          width: 250,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 250,
            height: 200,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 250,
            height: 200,
            color: Colors.grey[300],
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 32),
                SizedBox(height: 8),
                Text('Failed to load image'),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
  
  Widget _buildVideoWidget() {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _openVideoPlayer(context),
      child: Container(
        width: 250,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Colors.white,
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      message.fileName ?? 'Video',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
  
  Widget _buildFileWidget() {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _downloadFile(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withValues(alpha: 0.2) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isMe ? Colors.white.withValues(alpha: 0.3) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF075E54),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.insert_drive_file,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.fileName ?? 'File',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.fileSize != null)
                    Text(
                      _formatFileSize(message.fileSize!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isMe ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.download,
              color: isMe ? Colors.white : const Color(0xFF075E54),
              size: 20,
            ),
          ],
        ),
      ),
    ),
    );
  }
  
  // =========================================================================
  // MEDIA INTERACTION HANDLERS
  // =========================================================================
  
  void _openImageViewer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          imageUrl: message.mediaUrl!,
          fileName: message.fileName,
        ),
      ),
    );
  }
  
  void _openVideoPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoUrl: message.mediaUrl!,
          fileName: message.fileName,
        ),
      ),
    );
  }
  
  void _downloadFile(BuildContext context) async {
    if (message.mediaUrl == null) return;
    
    try {
      // Import url_launcher at top
      final Uri fileUri = Uri.parse(message.mediaUrl!);
      
      // Try to launch the URL (will download or open based on platform)
      final canLaunch = await url_launcher.canLaunchUrl(fileUri);
      
      if (canLaunch) {
        await url_launcher.launchUrl(
          fileUri,
          mode: url_launcher.LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open file'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  // =========================================================================
  // AVATAR WIDGET
  // =========================================================================
  
  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFF128C7E),
      child: Text(
        message.senderId.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
