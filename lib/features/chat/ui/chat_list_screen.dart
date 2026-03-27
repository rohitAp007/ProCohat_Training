/// ============================================================================
/// WHATSAPP-STYLE CHAT LIST SCREEN
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
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
import 'package:supabase_flutter_app/features/auth/unified_login/ui/unified_login_screen_clean.dart';
import 'package:supabase_flutter_app/features/broadcast/bloc/broadcast_bloc.dart';
import 'package:supabase_flutter_app/features/broadcast/data/broadcast_repository.dart';
import 'package:supabase_flutter_app/features/broadcast/ui/broadcast_list_screen.dart';

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
        // Camera feature - disabled until Profile model updated with lastSeen
        // IconButton(
        //   icon: const Icon(Icons.camera_alt_outlined),
        //   onPressed: () => _openCameraForQuickShare(),
        // ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'broadcast') {
              _navigateToBroadcasts();
            } else if (value == 'profile') {
              _navigateToProfile();
            } else if (value == 'logout') {
              _showLogoutDialog();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'broadcast',
              child: Row(
                children: [
                  Icon(Icons.campaign, size: 20, color: Color(0xFF25D366)),
                  SizedBox(width: 12),
                  Text('Broadcast Lists'),
                ],
              ),
            ),
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
            leading: Stack(
              children: [
                CircleAvatar(
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
                // Online status indicator
                // Online status indicator (always show if user has been online recently)
                if (user.lastSeen != null && DateTime.now().difference(user.lastSeen!).inMinutes < 5)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366), // WhatsApp green
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
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
  
  /// ====================================================================
  /// NEW CHAT FAB
  /// ====================================================================
  
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => _showNewChatBottomSheet(),
      backgroundColor: const Color(0xFF25D366),
      child: const Icon(Icons.message, color: Colors.white),
    );
  }
  
  /// Show bottom sheet to select user for new chat
  void _showNewChatBottomSheet() {
    // Capture the ProfileBloc BEFORE creating the bottom sheet
    final profileBloc = context.read<ProfileBloc>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: profileBloc,
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Title
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Select contact to chat',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                Divider(height: 1, color: Colors.grey[200]),
                
                // User list
                Expanded(
                  child: BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, state) {
                      if (state is ProfileLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (state is ProfileError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, 
                                size: 64, 
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.message,
                                style: TextStyle(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      
                      if (state is ProfilesLoaded) {
                        final currentUserId = 
                            Supabase.instance.client.auth.currentUser?.id;
                        
                        final users = state.profiles
                            .where((profile) => profile.id != currentUserId)
                            .toList();
                        
                        if (users.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, 
                                  size: 64, 
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No users available',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Invite friends to start chatting!',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          controller: controller,
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF25D366),
                                child: user.avatarUrl != null && 
                                       user.avatarUrl!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          user.avatarUrl!,
                                          fit: BoxFit.cover,
                                          width: 48,
                                          height: 48,
                                          errorBuilder: (_, __, ___) => 
                                              _buildAvatarFallback(user),
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
                              ),
                              subtitle: Text(
                                user.bio ?? 'Hey there! I am using ProCohat',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Chat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _openChat(user);
                              },
                            );
                          },
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  void _navigateToBroadcasts() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => BroadcastBloc(
            repository: BroadcastRepository(),
          ),
          child: const BroadcastListScreen(),
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
                    MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
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
  
  // =========================================================================
  // CAMERA QUICK SHARE - DISABLED (Profile model needs lastSeen field)
  // =========================================================================
  
  /* 
  Future<void> _openCameraForQuickShare() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (photo == null) return;
      
      // Show chat selector dialog
      if (!mounted) return;
      
      final selectedUser = await showDialog<Profile>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Send to...'),
          content: SizedBox(
            width: double.maxFinite,
            child: BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                if (state is! ProfilesLoaded) return const CircularProgressIndicator();
                
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.profiles.length,
                  itemBuilder: (context, index) {
                    final user = state.profiles[index];
                    // Skip current user
                    if (user.id == Supabase.instance.client.auth.currentUser!.id) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF25D366),
                        child: Text(
                          user.fullName.isNotEmpty 
                              ? user.fullName[0].toUpperCase() 
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(user.fullName),
                      onTap: () => Navigator.pop(context, user),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      if (selectedUser == null || !mounted) return;
      
      // Navigate to chat with the selected user and the photo
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => ChatBloc(
              chatRepository: ChatRepository(),
              messageRepository: MessageRepository(),
              currentUserId: Supabase.instance.client.auth.currentUser!.id,
            )..add(ChatLoadRequested(otherUserId: selectedUser.id)),
            child: ChatScreen(
              otherUserId: selectedUser.id,
              otherUserName: selectedUser.fullName,
              quickShareImagePath: photo.path, // Pass the photo path
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open camera: $e')),
        );
      }
    }
  }
  */
}
