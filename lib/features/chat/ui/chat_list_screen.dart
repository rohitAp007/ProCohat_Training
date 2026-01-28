/// ============================================================================
/// WHATSAPP-STYLE CHAT LIST SCREEN
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_bloc.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_state.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_event.dart';
import 'package:supabase_flutter_app/features/profile/data/profile_model.dart';
import 'package:supabase_flutter_app/features/chat/ui/chat_screen.dart';
import 'package:supabase_flutter_app/features/chat/bloc/chat_bloc.dart';
import 'package:supabase_flutter_app/features/chat/data/message_repository.dart';
import 'package:supabase_flutter_app/features/chat/data/chat_repository.dart';
import 'package:supabase_flutter_app/features/profile/ui/profile_view_screen.dart';
import 'package:supabase_flutter_app/features/profile/data/profile_repository.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter_app/features/auth/login/ui/login_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _loadProfiles() {
    context.read<ProfileBloc>().add(ProfilesLoadAllRequested());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp background
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }
  
  // =========================================================================
  // APP BAR - WhatsApp Style
  // =========================================================================
  
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('ProCohat', style: TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFF075E54),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.camera_alt_outlined),
          onPressed: () {
            // TODO: Camera feature
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera coming soon!')),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'profile') {
              _navigateToProfile();
            } else if (value == 'logout') {
              _showLogoutDialog();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 12),
                  Text('Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // SEARCH BAR - WhatsApp Style
  // =========================================================================
  
  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF075E54),
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white.withValues(alpha: 0.7)),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  // =========================================================================
  // BODY - User List
  // =========================================================================
  
  Widget _buildBody() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is ProfileError) {
          return _buildErrorState(state.message);
        }
        
        if (state is ProfilesLoaded) {
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          
          // Filter out current user and apply search
          var users = state.profiles
              .where((profile) => profile.id != currentUserId)
              .where((profile) {
                if (_searchQuery.isEmpty) return true;
                return profile.fullName.toLowerCase().contains(_searchQuery) ||
                      profile.id.toLowerCase().contains(_searchQuery);
              })
              .toList();
          
          if (users.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: () async => _loadProfiles(),
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return _buildChatListTile(users[index]);
              },
            ),
          );
        }
        
        return _buildEmptyState();
      },
    );
  }

  // =========================================================================
  // CHAT LIST TILE - WhatsApp Style
  // =========================================================================
  
  Widget _buildChatListTile(Profile user) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF25D366),
              child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        user.avatarUrl!,
                        fit: BoxFit.cover,
                        width: 56,
                        height: 56,
                        errorBuilder: (_, __, ___) => _buildAvatarFallback(user),
                      ),
                    )
                  : _buildAvatarFallback(user),
            ),
            title: Text(
              user.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                user.bio ?? 'Hey there! I am using ProCohat',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Tap to chat',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: () => _openChat(user),
          ),
          Divider(height: 1, color: Colors.grey[200]),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(Profile user) {
    final initials = _getInitials(user.fullName);
    return Text(
      initials,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
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

  // =========================================================================
  // STATES
  // =========================================================================
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No users yet' : 'No results found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Start chatting by inviting friends!'
                : 'Try a different search term',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
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
            onPressed: _loadProfiles,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // FAB - Floating Action Button
  // =========================================================================
  
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        // Already on chat list, could scroll to top or show new chat dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a user to start chatting!')),
        );
      },
      backgroundColor: const Color(0xFF25D366),
      child: const Icon(Icons.message, color: Colors.white),
    );
  }

  // =========================================================================
  // NAVIGATION
  // =========================================================================
  
  void _openChat(Profile otherUser) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ChatBloc(
            messageRepository: MessageRepository(),
            chatRepository: ChatRepository(),
            currentUserId: currentUserId,
          ),
          child: ChatScreen(
            otherUserId: otherUser.id,
            otherUserName: otherUser.fullName,
          ),
        ),
      ),
    );
  }

  void _navigateToProfile() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ProfileBloc(repository: ProfileRepository())
            ..add(ProfileLoadRequested(userId: currentUserId)),
          child: const ProfileViewScreen(),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await AuthRepository().signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
