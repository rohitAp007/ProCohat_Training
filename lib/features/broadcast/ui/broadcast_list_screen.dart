// ============================================================================
// BROADCAST LIST SCREEN - VIEW ALL BROADCAST LISTS
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/broadcast_bloc.dart';
import '../bloc/broadcast_event.dart';
import '../bloc/broadcast_state.dart';
import 'new_broadcast_screen.dart';
import 'broadcast_detail_screen.dart';

class BroadcastListScreen extends StatefulWidget {
  const BroadcastListScreen({super.key});
  
  @override
  State<BroadcastListScreen> createState() => _BroadcastListScreenState();
}

class _BroadcastListScreenState extends State<BroadcastListScreen> {
  @override
  void initState() {
    super.initState();
    _loadBroadcastLists();
  }
  
  void _loadBroadcastLists() {
    context.read<BroadcastBloc>().add(const BroadcastListsRequested());
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
      title: const Text(
        'Broadcast Lists',
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
    return BlocConsumer<BroadcastBloc, BroadcastState>(
      listener: (context, state) {
        if (state is BroadcastError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
        
        if (state is BroadcastListCreateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Broadcast list created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        if (state is BroadcastListDeleteSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Broadcast list deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is BroadcastListsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is BroadcastListsLoaded) {
          if (state.lists.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: () async => _loadBroadcastLists(),
            child: ListView.builder(
              itemCount: state.lists.length,
              itemBuilder: (context, index) {
                return _buildBroadcastListTile(state.lists[index]);
              },
            ),
          );
        }
        
        return _buildEmptyState();
      },
    );
  }
  
  // ===========================================================================
  // BROADCAST LIST TILE
  // ===========================================================================
  
  Widget _buildBroadcastListTile(broadcastList) {
    final lastBroadcast = broadcastList.lastBroadcastAt != null
        ? _formatRelativeTime(broadcastList.lastBroadcastAt!)
        : 'Never';
    
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: Container(
              width: 56,
              height: 56,
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
            title: Text(
              broadcastList.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${broadcastList.recipientCount} recipients',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lastBroadcast,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: () => _openBroadcastDetail(broadcastList),
            onLongPress: () => _showDeleteDialog(broadcastList),
          ),
          Divider(height: 1, color: Colors.grey[200]),
        ],
      ),
    );
  }
  
  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Broadcast Lists',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Create a broadcast list to send messages to multiple contacts at once',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewBroadcast,
            icon: const Icon(Icons.add),
            label: const Text('Create Broadcast List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
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
      onPressed: _createNewBroadcast,
      backgroundColor: const Color(0xFF25D366),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
  
  // ===========================================================================
  // NAVIGATION & ACTIONS
  // ===========================================================================
  
  void _createNewBroadcast() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<BroadcastBloc>(),
          child: const NewBroadcastScreen(),
        ),
      ),
    );
  }
  
  void _openBroadcastDetail(broadcastList) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<BroadcastBloc>(),
          child: BroadcastDetailScreen(broadcastList: broadcastList),
        ),
      ),
    );
  }
  
  void _showDeleteDialog(broadcastList) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Broadcast List'),
        content: Text(
          'Are you sure you want to delete "${broadcastList.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<BroadcastBloc>().add(
                BroadcastListDeleted(broadcastList.id),
              );
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  // ===========================================================================
  // HELPERS
  // ===========================================================================
  
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
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
}
