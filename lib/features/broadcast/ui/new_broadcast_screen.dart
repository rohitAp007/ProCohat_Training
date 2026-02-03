// ============================================================================
// NEW BROADCAST SCREEN - CREATE NEW BROADCAST LIST
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_bloc.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_event.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_state.dart';
import 'package:supabase_flutter_app/features/profile/data/profile_model.dart';
import '../bloc/broadcast_bloc.dart';
import '../bloc/broadcast_event.dart';
import '../bloc/broadcast_state.dart';

class NewBroadcastScreen extends StatefulWidget {
  const NewBroadcastScreen({super.key});
  
  @override
  State<NewBroadcastScreen> createState() => _NewBroadcastScreenState();
}

class _NewBroadcastScreenState extends State<NewBroadcastScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedRecipients = {};
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(ProfilesLoadAllRequested());
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
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
        'New Broadcast List',
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
        if (state is BroadcastListCreateSuccess) {
          // Navigate back on success
          Navigator.of(context).pop();
        }
        
        if (state is BroadcastError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Column(
        children: [
          _buildListNameSection(),
          _buildSearchBar(),
          _buildSelectedCounter(),
          Expanded(child: _buildRecipientList()),
          _buildCreateButton(),
        ],
      ),
    );
  }
  
  // ===========================================================================
  // LIST NAME SECTION
  // ===========================================================================
  
  Widget _buildListNameSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'List Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF075E54),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'e.g., Team Updates, Family',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
  
  // ===========================================================================
  // SEARCH BAR
  // ===========================================================================
  
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search contacts...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }
  
  // ===========================================================================
  // SELECTED COUNTER
  // ===========================================================================
  
  Widget _buildSelectedCounter() {
    if (_selectedRecipients.isEmpty) return const SizedBox.shrink();
    
    return Container(
      color: const Color(0xFF25D366).withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: const Color(0xFF25D366),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${_selectedRecipients.length} selected',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF075E54),
            ),
          ),
        ],
      ),
    );
  }
  
  // ===========================================================================
  // RECIPIENT LIST
  // ===========================================================================
  
  Widget _buildRecipientList() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is ProfileError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load contacts',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<ProfileBloc>().add(ProfilesLoadAllRequested());
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (state is ProfilesLoaded) {
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          
          // Filter out current user and apply search
          var users = state.profiles
              .where((profile) => profile.id != currentUserId)
              .where((profile) {
                if (_searchQuery.isEmpty) return true;
                return profile.fullName.toLowerCase().contains(_searchQuery);
              })
              .toList();
          
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? 'No contacts' : 'No results',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }
          
          return Container(
            color: Colors.white,
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return _buildRecipientTile(users[index]);
              },
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }
  
  // ===========================================================================
  // RECIPIENT TILE
  // ===========================================================================
  
  Widget _buildRecipientTile(Profile user) {
    final isSelected = _selectedRecipients.contains(user.id);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF25D366),
        child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  user.avatarUrl!,
                  fit: BoxFit.cover,
                  width: 48,
                  height: 48,
                  errorBuilder: (_, __, ___) => _buildAvatarFallback(user),
                ),
              )
            : _buildAvatarFallback(user),
      ),
      title: Text(
        user.fullName,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: user.bio != null
          ? Text(
              user.bio!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Checkbox(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedRecipients.add(user.id);
            } else {
              _selectedRecipients.remove(user.id);
            }
          });
        },
        activeColor: const Color(0xFF25D366),
      ),
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedRecipients.remove(user.id);
          } else {
            _selectedRecipients.add(user.id);
          }
        });
      },
    );
  }
  
  Widget _buildAvatarFallback(Profile user) {
    final initials = _getInitials(user.fullName);
    return Text(
      initials,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
  
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  
  // ===========================================================================
  // CREATE BUTTON
  // ===========================================================================
  
  Widget _buildCreateButton() {
    final canCreate = _nameController.text.trim().isNotEmpty &&
        _selectedRecipients.isNotEmpty;
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canCreate ? _createBroadcastList : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: BlocBuilder<BroadcastBloc, BroadcastState>(
            builder: (context, state) {
              if (state is BroadcastListsLoading) {
                return const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                );
              }
              
              return Text(
                'Create List (${_selectedRecipients.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  // ===========================================================================
  // ACTIONS
  // ===========================================================================
  
  void _createBroadcastList() {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a list name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_selectedRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one recipient'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    context.read<BroadcastBloc>().add(
      BroadcastListCreated(
        name: name,
        recipientIds: _selectedRecipients.toList(),
      ),
    );
  }
}
