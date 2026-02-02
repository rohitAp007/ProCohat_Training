// ============================================================================
// BROADCAST MESSAGE SCREEN - COMPOSE AND SEND BROADCAST MESSAGE
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/broadcast_bloc.dart';
import '../bloc/broadcast_event.dart';
import '../bloc/broadcast_state.dart';
import '../data/broadcast_list_model.dart';

class BroadcastMessageScreen extends StatefulWidget {
  final BroadcastList broadcastList;
  
  const BroadcastMessageScreen({
    super.key,
    required this.broadcastList,
  });
  
  @override
  State<BroadcastMessageScreen> createState() => _BroadcastMessageScreenState();
}

class _BroadcastMessageScreenState extends State<BroadcastMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }
  
  // ===========================================================================
  // APP BAR
  // ===========================================================================
  
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Send Broadcast',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: const Color(0xFF075E54),
      elevation: 0,
    );
  }
  
  // ===========================================================================
  // BODY
  // ===========================================================================
  
  Widget _buildBody() {
    return BlocListener<BroadcastBloc, BroadcastState>(
      listener: (context, state) {
        if (state is BroadcastSending) {
          setState(() => _isSending = true);
        }
        
        if (state is BroadcastSent) {
          setState(() => _isSending = false);
          
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text('Broadcast Sent!'),
                ],
              ),
              content: Text(
                state.deliveryStatusText,
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // Close dialog
                    Navigator.pop(context); // Close message screen
                    Navigator.pop(context); // Close detail screen
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
        
        if (state is BroadcastError) {
          setState(() => _isSending = false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Column(
        children: [
          _buildInfoSection(),
          Expanded(child: _buildMessageInput()),
          _buildSendButton(),
        ],
      ),
    );
  }
  
  // ===========================================================================
  // INFO SECTION
  // ===========================================================================
  
  Widget _buildInfoSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.campaign,
              color: Color(0xFF075E54),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.broadcastList.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.broadcastList.recipientCount} recipients',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // ===========================================================================
  // MESSAGE INPUT
  // ===========================================================================
  
  Widget _buildMessageInput() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Message',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF075E54),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Type your broadcast message...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Media attachment coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.attach_file),
                color: const Color(0xFF075E54),
                tooltip: 'Attach media',
              ),
              const SizedBox(width: 8),
              Text(
                '${_messageController.text.length}/5000',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // ===========================================================================
  // SEND BUTTON
  // ===========================================================================
  
  Widget _buildSendButton() {
    final canSend = _messageController.text.trim().isNotEmpty && !_isSending;
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: canSend ? _sendBroadcast : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            disabledBackgroundColor: Colors.grey[300],
          ),
          icon: _isSending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.send),
          label: Text(
            _isSending
                ? 'Sending...'
                : 'Send to ${widget.broadcastList.recipientCount}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
  
  // ===========================================================================
  // ACTIONS
  // ===========================================================================
  
  void _sendBroadcast() {
    final message = _messageController.text.trim();
    
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (message.length > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message is too long (max 5000 characters)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Broadcast?'),
        content: Text(
          'Send this message to ${widget.broadcastList.recipientCount} recipients?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              
              // Send broadcast
              context.read<BroadcastBloc>().add(
                BroadcastMessageSent(
                  listId: widget.broadcastList.id,
                  message: message,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF25D366),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
