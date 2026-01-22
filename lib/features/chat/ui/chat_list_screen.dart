/// ============================================================================
/// CHAT LIST SCREEN - MAIN CHAT LIST UI
/// ============================================================================
/// 
/// PURPOSE: Display list of users to chat with
/// 
/// LEARNING: Connecting BLoC backend to UI frontend
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_bloc.dart';
import 'package:supabase_flutter_app/features/profile/data/profile_model.dart';
import 'package:supabase_flutter_app/features/chat/ui/widgets/chat_list_tile.dart';
import 'package:supabase_flutter_app/features/chat/ui/widgets/empty_chat_list.dart';
import 'package:supabase_flutter_app/features/chat/ui/chat_screen.dart';

/// ChatListScreen - Shows all users you can chat with
/// 
/// **Architecture:**
/// ```
/// ChatListScreen
///     ↓ (dispatch event)
/// ProfileBloc
///     ↓ (load all profiles)
/// ProfileRepository
///     ↓ (SELECT * FROM profiles)
/// Supabase
///     ↓ (return users)
/// UI renders list
/// ```
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Load all profiles on screen init
    _loadProfiles();
  }
  
  void _loadProfiles() {
    context.read<ProfileBloc>().add(const ProfilesLoadAllRequested());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }
  
  // =========================================================================
  // APP BAR
  // =========================================================================
  
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'ProCohat',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      backgroundColor: const Color(0xFF075E54), // WhatsApp green
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // TODO: Implement search (future)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Search coming soon!')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // TODO: Show menu (future)
          },
        ),
      ],
    );
  }
  
  // =========================================================================
  // BODY
  // =========================================================================
  
  Widget _buildBody() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        // LOADING STATE
        if (state is ProfileLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF075E54),
            ),
          );
        }
        
        // ERROR STATE
        if (state is ProfileError) {
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
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadProfiles,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF075E54),
                  ),
                ),
              ],
            ),
          );
        }
        
        // LOADED STATE - Show users
        if (state is ProfilesLoaded) {
          final profiles = state.profiles;
          
          // Filter out current user (get from Supabase auth)
          final currentUserId = _getCurrentUserId();
          final otherUsers = currentUserId != null
              ? profiles.where((p) => p.userId != currentUserId).toList()
              : profiles;
          
          // Empty state
          if (otherUsers.isEmpty) {
            return const EmptyChatList();
          }
          
          // User list
          return _buildUserList(otherUsers);
        }
        
        // DEFAULT: Empty state
        return const EmptyChatList();
      },
    );
  }
  
  // =========================================================================
  // HELPER: Get Current User ID
  // =========================================================================
  
  String? _getCurrentUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (e) {
      return null;
    }
  }
  
  // =========================================================================
  // USER LIST
  // =========================================================================
  
  Widget _buildUserList(List<Profile> users) {
    return Container(
      color: const Color(0xFFECE5DD), // WhatsApp background
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          
          return ChatListTile(
            user: user,
            onTap: () => _openChat(user),
          );
        },
      ),
    );
  }
  
  // =========================================================================
  // NAVIGATION
  // =========================================================================
  
  void _openChat(Profile user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: user.userId,
          otherUserName: user.fullName,
        ),
      ),
    );
  }
}

// ============================================================================
// USAGE
// ============================================================================
//
// NAVIGATION:
// ```dart
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (_) => const ChatListScreen(),
//   ),
// );
// ```
//
// OR IN APP ROUTER:
// ```dart
// routes: [
//   GoRoute(
//     path: '/chats',
//     builder: (context, state) => const ChatListScreen(),
//   ),
// ]
// ```
//
// ============================================================================

        
        // LOADED STATE - Show users
        if (state is ProfilesLoaded) {
          final profiles = state.profiles;
          
          // Filter out current user (get from Supabase auth)
          final currentUserId = _getCurrentUserId();
          final otherUsers = currentUserId != null
              ? profiles.where((p) => p.userId != currentUserId).toList()
              : profiles;
          
          // Empty state
          if (otherUsers.isEmpty) {
            return const EmptyChatList();
          }
          
          // User list
          return _buildUserList(otherUsers);
        }
        
        // DEFAULT: Empty state
        return const EmptyChatList();
      },
    );
  }
  
  // =========================================================================
  // HELPER: Get Current User ID
  // =========================================================================
  
  String? _getCurrentUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (e) {
      return null;
    }
  }
  
  // =========================================================================
  // USER LIST
  // =========================================================================
  
  Widget _buildUserList(List<Profile> users) {
    return Container(
      color: const Color(0xFFECE5DD), // WhatsApp background
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          
          return ChatListTile(
            user: user,
            onTap: () => _openChat(user),
          );
        },
      ),
    );
  }
  
  // =========================================================================
  // NAVIGATION
  // =========================================================================
  
  void _openChat(Profile user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: user.userId,
          otherUserName: user.fullName,
        ),
      ),
    );
  }
}

// ============================================================================
// HELPER EXTENSION
// ============================================================================

/// Extension to get current user ID from ProfileBloc state
extension ProfileStateExtension on ProfileState {
  String? getUserId() {
    if (this is ProfileLoaded) {
      return (this as ProfileLoaded).profile.userId;
    }
    if (this is ProfilesLoaded) {
      // Try to get from somewhere else
      // For now, return null
      return null;
    }
    return null;
  }
}

// ============================================================================
// USAGE
// ============================================================================
//
// NAVIGATION:
// ```dart
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (_) => const ChatListScreen(),
//   ),
// );
// ```
//
// OR IN APP ROUTER:
// ```dart
// routes: [
//   GoRoute(
//     path: '/chats',
//     builder: (context, state) => const ChatListScreen(),
//   ),
// ]
// ```
//
// ============================================================================
