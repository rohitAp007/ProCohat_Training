// ============================================================================
// BROADCAST DETAIL SCREEN - VIEW AND MANAGE BROADCAST LIST 
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/broadcast_bloc.dart';
import '../bloc/broadcast_event.dart';
import '../bloc/broadcast_state.dart';
import '../data/broadcast_list_model.dart';
import '../data/broadcast_recipient_model.dart';
import 'broadcast_message_screen.dart';

class BroadcastDetailScreen extends StatefulWidget {
  final BroadcastList broadcastList;
  
  const BroadcastDetailScreen({
    super.key,
    required this.broadcastList,
  });
  
  @override
  State<BroadcastDetailScreen> createState() => _BroadcastDetailScreenState();
}

class _BroadcastDetailScreenState extends State<BroadcastDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadDetails();
  }
  
  void _loadDetails() {
    context.read<BroadcastBloc>().add(
      BroadcastListDetailsRequested(widget.broadcastList.id),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }
  
  // ===========================================================================
  // APP BAR
  // ===========================================================================
  
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        widget.broadcastList.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: const Color(0xFF075E54),
      elevation: 0,
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _editListName();
            } else if (value == 'delete') {
              _deleteList();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Edit Name'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete List', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // ===========================================================================
  // BODY
  // ===========================================================================
  
  Widget _buildBody() {
    return BlocBuilder<BroadcastBloc, BroadcastState>(
      builder: (context, state) {
        if (state is BroadcastListLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is BroadcastListLoaded) {
          return RefreshIndicator(
            onRefresh: () async => _loadDetails(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(state.list),
                  const SizedBox(height: 8),
                  _buildRecipientsSection(state.recipients),
                  const SizedBox(height: 8),
                  _buildBroadcastHistorySection(),
                ],
              ),
            ),
          );
        }
        
        if (state is BroadcastError) {
          return _buildErrorState(state.message);
        }
        
        return _buildErrorState('Failed to load broadcast list');
      },
    );
  }
  
  // ===========================================================================
  // INFO SECTION
  // ===========================================================================
  
  Widget _buildInfoSection(BroadcastList list) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created ${_formatDate(list.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (list.lastBroadcastAt != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.send, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Last broadcast: ${_formatRelativeTime(list.lastBroadcastAt!)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  // ===========================================================================
  // RECIPIENTS SECTION
  // ===========================================================================
  
  Widget _buildRecipientsSection(List<BroadcastRecipient> recipients) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recipients (${recipients.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF075E54),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Add recipients
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Add recipients coming soon!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366),
                  ),
                ),
              ],
            ),
          ),
          if (recipients.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No recipients',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...recipients.map((recipient) => _buildRecipientTile(recipient)),
        ],
      ),
    );
  }
  
  Widget _buildRecipientTile(BroadcastRecipient recipient) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF25D366),
            child: recipient.hasAvatar
                ? ClipOval(
                    child: Image.network(
                      recipient.recipientAvatar!,
                      fit: BoxFit.cover,
                      width: 44,
                      height: 44,
                      errorBuilder: (_, __, ___) => _buildRecipientInitials(recipient),
                    ),
                  )
                : _buildRecipientInitials(recipient),
          ),
          title: Text(
            recipient.displayName,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            'Added ${_formatRelativeTime(recipient.addedAt)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: Colors.grey[600],
            onPressed: () => _removeRecipient(recipient),
          ),
        ),
        Divider(height: 1, color: Colors.grey[200], indent: 72),
      ],
    );
  }
  
  Widget _buildRecipientInitials(BroadcastRecipient recipient) {
    final initials = _getInitials(recipient.displayName);
    return Text(
      initials,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
  
  // ===========================================================================
  // BROADCAST HISTORY SECTION
  // ===========================================================================
  
  Widget _buildBroadcastHistorySection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Broadcast History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF075E54),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Broadcast history coming soon!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ===========================================================================
  // ERROR STATE
  // ===========================================================================
  
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDetails,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  // ===========================================================================
  // FAB
  // ===========================================================================
  
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _sendBroadcast,
      backgroundColor: const Color(0xFF25D366),
      child: const Icon(Icons.send, color: Colors.white),
    );
  }
  
  // ===========================================================================
  // ACTIONS
  // ===========================================================================
  
  void _sendBroadcast() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<BroadcastBloc>(),
          child: BroadcastMessageScreen(broadcastList: widget.broadcastList),
        ),
      ),
    );
  }
  
  void _editListName() {
    final controller = TextEditingController(text: widget.broadcastList.name);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit List Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                context.read<BroadcastBloc>().add(
                  BroadcastListUpdated(
                    listId: widget.broadcastList.id,
                    newName: newName,
                  ),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _deleteList() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Broadcast List'),
        content: Text(
          'Are you sure you want to delete "${widget.broadcastList.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<BroadcastBloc>().add(
                BroadcastListDeleted(widget.broadcastList.id),
              );
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _removeRecipient(BroadcastRecipient recipient) {
    context.read<BroadcastBloc>().add(
      BroadcastRecipientRemoved(
        listId: widget.broadcastList.id,
        recipientId: recipient.recipientId,
      ),
    );
  }
  
  // ===========================================================================
  // HELPERS
  // ===========================================================================
  
  String _formatDate(DateTime dateTime) {
    return DateFormat('MMM d, y').format(dateTime);
  }
  
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
  
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
