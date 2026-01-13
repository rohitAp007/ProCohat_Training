/// ============================================================================
/// PROFILE VIEW SCREEN - DISPLAY USER PROFILE
/// ============================================================================
/// 
/// PURPOSE: Show user's profile information in read-only format
/// 
/// LEARNING OBJECTIVES:
/// 1. BlocBuilder for state-based rendering
/// 2. BlocListener for side effects
/// 3. Navigation to edit screen
/// 4. Formatting dates and data for display
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../data/profile_model.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_info_card.dart';
import 'profile_edit_screen.dart';
import 'package:supabase_flutter_app/core/widgets/custom_snackbar.dart';

/// ProfileViewScreen - Display user's profile
/// 
/// **Purpose:**
/// - Show profile information (read-only)
/// - Allow navigation to edit screen
/// - Handle loading/error/empty states
/// - Logout functionality
/// 
/// **BLoC Integration:**
/// - BlocBuilder: Rebuild on state changes
/// - BlocListener: React to operation results
/// - Dispatch events: Load profile, logout
class ProfileViewScreen extends StatefulWidget {
  /// User ID whose profile to display
  /// Could be current user or another user
  final String? userId;
  
  const ProfileViewScreen({
    super.key,
    this.userId,
  });
  
  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch load event after frame is rendered
    // This ensures BLoC is ready to receive events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.userId != null && widget.userId!.isNotEmpty) {
        print('📤 ProfileViewScreen: Dispatching ProfileLoadRequested');
        context.read<ProfileBloc>().add(
          ProfileLoadRequested(userId: widget.userId!),
        );
      } else {
        print('⚠️ ProfileViewScreen: No userId provided');
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BlocListener for side effects (snackbars, navigation)
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          // HANDLE OPERATION SUCCESS
          if (state is ProfileOperationSuccess) {
            CustomSnackBar.showSuccess(
              context,
              state.message,
            );
          }
          
          // HANDLE ERRORS
          if (state is ProfileError) {
            CustomSnackBar.showError(
              context,
              state.message,
            );
          }
        },
        
        // BlocBuilder for UI rendering
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            // LOADING STATE
            if (state is ProfileLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            // ERROR STATE
            if (state is ProfileError) {
              return _buildErrorState(context, state);
            }
            
            // EMPTY STATE (no profile)
            if (state is ProfileEmpty) {
              return _buildEmptyState(context, state);
            }
            
            // LOADED STATE (profile exists)
            if (state is ProfileLoaded) {
              return _buildProfileView(context, state.profile);
            }
            
            // INITIAL STATE (shouldn't see this)
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
  
  // ===========================================================================
  // ERROR STATE UI
  // ===========================================================================
  
  Widget _buildErrorState(BuildContext context, ProfileError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Profile',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (state.isRecoverable) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Retry loading profile
                  context.read<ProfileBloc>().add(
                        ProfileLoadRequested(
                          userId: widget.userId ?? '',
                        ),
                      );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // ===========================================================================
  // EMPTY STATE UI (No profile exists)
  // ===========================================================================
  
  Widget _buildEmptyState(BuildContext context, ProfileEmpty state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 120,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: 24),
            Text(
              'No Profile Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your profile to get started',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to create profile
                // For now, same as edit (will create on save)
                _navigateToEdit(context, null);
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Profile'),
            ),
          ],
        ),
      ),
    );
  }
  
  // ===========================================================================
  // PROFILE VIEW UI (Main content)
  // ===========================================================================
  
  Widget _buildProfileView(BuildContext context, Profile profile) {
    return CustomScrollView(
      slivers: [
        // APP BAR
        _buildAppBar(context, profile),
        
        // CONTENT
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 24),
              
              // AVATAR
              ProfileAvatar(
                avatarUrl: profile.avatarUrl,
                fullName: profile.fullName,
                size: 120,
              ),
              
              const SizedBox(height: 16),
              
              // NAME
              Text(
                profile.fullName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              
              const SizedBox(height: 32),
              
              // BIO SECTION
              if (profile.bio != null && profile.bio!.isNotEmpty)
                ProfileSection(
                  title: 'About',
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          profile.bio!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 24),
              
              // CONTACT INFORMATION
              ProfileSection(
                title: 'Contact Information',
                children: [
                  if (profile.phone != null && profile.phone!.isNotEmpty)
                    ProfileInfoCard(
                      title: 'Phone',
                      value: profile.phone!,
                      icon: Icons.phone,
                    ),
                  if (profile.dateOfBirth != null)
                    ProfileInfoCard(
                      title: 'Birthday',
                      value: _formatDate(profile.dateOfBirth!),
                      icon: Icons.cake,
                    ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // ACCOUNT INFO
              ProfileSection(
                title: 'Account',
                children: [
                  ProfileInfoCard(
                    title: 'Member Since',
                    value: _formatDate(profile.createdAt),
                    icon: Icons.calendar_today,
                  ),
                  if (profile.updatedAt != profile.createdAt)
                    ProfileInfoCard(
                      title: 'Last Updated',
                      value: _formatDate(profile.updatedAt),
                      icon: Icons.update,
                    ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // LOGOUT BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
  
  // ===========================================================================
  // APP BAR
  // ===========================================================================
  
  Widget _buildAppBar(BuildContext context, Profile profile) {
    return SliverAppBar(
      title: const Text('Profile'),
      floating: true,
      actions: [
        // EDIT BUTTON
        IconButton(
          onPressed: () => _navigateToEdit(context, profile),
          icon: const Icon(Icons.edit),
          tooltip: 'Edit Profile',
        ),
      ],
    );
  }
  
  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================
  
  /// Format date for display
  /// Example: "January 15, 1990"
  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }
  
  /// Navigate to edit screen
  void _navigateToEdit(BuildContext context, Profile? profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProfileBloc>(),
          child: ProfileEditScreen(
            profile: profile,
            userId: profile?.userId ?? widget.userId ?? '',  // Use widget.userId for create
          ),
        ),
      ),
    );
  }
  
  /// Handle logout
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      // TODO: Implement logout via AuthBloc
      // For now, just show message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout functionality coming soon!'),
        ),
      );
    }
  }
}

// ============================================================================
// SUMMARY OF WHAT WE LEARNED:
// ============================================================================
//
// 1. BLOCBUILDER PATTERN:
//    - Rebuilds on state changes
//    - Handle all possible states
//    - Return appropriate UI for each state
//
// 2. BLOCLISTENER PATTERN:
//    - React to state changes (side effects)
//    - Show snackbars
//    - Navigate
//    - Don't rebuild UI
//
// 3. STATE-BASED RENDERING:
//    - ProfileLoading → show spinner
//    - ProfileLoaded → show profile
//    - ProfileEmpty → show create prompt
//    - ProfileError → show error and retry
//
// 4. UI COMPOSITION:
//    - Use reusable widgets (ProfileAvatar, ProfileInfoCard)
//    - Organize with ProfileSection
//    - CustomScrollView for scrollable content
//    - SliverAppBar for collapsible header
//
// 5. DATA FORMATTING:
//    - DateFormat for user-friendly dates
//    - Conditional rendering (only show if data exists)
//    - Handle nullable fields gracefully
//
// 6. USER FEEDBACK:
//    - Loading states
//    - Error messages with retry
//    - Success confirmations
//    - Confirmation dialogs for destructive actions
//
// ============================================================================
