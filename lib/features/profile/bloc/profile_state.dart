/// ============================================================================
/// PROFILE STATES - UI CONDITIONS FOR PROFILE FEATURE
/// ============================================================================
/// 
/// PURPOSE: Define all possible states the profile feature can be in
/// 
/// LEARNING: States represent "what condition is the UI in right now"
/// 
/// ============================================================================
library;

import 'package:equatable/equatable.dart';
import '../data/profile_model.dart';

/// Base class for all profile states
/// 
/// **Why sealed?**
/// - Ensures we handle all possible states in UI
/// - Compile-time safety
/// - Pattern matching support
/// 
/// **Why Equatable?**
/// - BlocBuilder only rebuilds when state changes
/// - Compare states by value, not reference
/// - Better performance
sealed class ProfileState extends Equatable {
  const ProfileState();
  
  @override
  List<Object?> get props => [];
}

// =============================================================================
// INITIAL STATE
// =============================================================================

/// Initial state before any profile operation
/// 
/// **When active:**
/// - App just started
/// - BLoC created but no events dispatched yet
/// - Before profile load requested
/// 
/// **UI should show:**
/// - Nothing (blank)
/// - Placeholder
/// - Loading skeleton (optional)
/// 
/// **Transitions to:**
/// - ProfileLoading (after ProfileLoadRequested)
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

// =============================================================================
// LOADING STATE
// =============================================================================

/// Profile operation in progress
/// 
/// **When active:**
/// - Loading profile from database
/// - Creating new profile
/// - Updating existing profile
/// - Deleting profile
/// 
/// **UI should show:**
/// - Loading spinner
/// - Progress indicator
/// - Disabled buttons
/// - Loading skeleton
/// 
/// **Duration:** Usually 100ms - 2 seconds
/// 
/// **Transitions to:**
/// - ProfileLoaded (load success)
/// - ProfileEmpty (no profile found)
/// - ProfileOperationSuccess (create/update/delete success)
/// - ProfileError (any failure)
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

// =============================================================================
// LOADED STATE
// =============================================================================

/// Profile successfully loaded and ready to display
/// 
/// **When active:**
/// - Profile fetched from database
/// - After successful create/update
/// - User viewing their profile
/// 
/// **UI should show:**
/// - Profile information (name, bio, etc.)
/// - Edit button (if own profile)
/// - Profile picture
/// - All profile fields
/// 
/// **Contains:**
/// - Profile data
/// - Edit mode flag (view vs edit)
/// 
/// **Example:**
/// ```dart
/// if (state is ProfileLoaded) {
///   return ProfileView(profile: state.profile);
/// }
/// ```
class ProfileLoaded extends ProfileState {
  /// The loaded profile data
  final Profile profile;
  
  /// Whether currently in edit mode
  /// true = showing edit form
  /// false = showing read-only view
  final bool isEditMode;
  
  const ProfileLoaded({
    required this.profile,
    this.isEditMode = false,
  });
  
  @override
  List<Object?> get props => [profile, isEditMode];
}

/// Multiple profiles loaded (for chat list)
/// 
/// **When active:**
/// - Chat list screen displayed all users
/// - Profile directory loaded
/// 
/// **UI should show:**
/// - List of all users
/// - Profile pictures
/// - Names
/// 
/// **Example:**
/// ```dart
/// if (state is ProfilesLoaded) {
///   return ListView.builder(
///     itemCount: state.profiles.length,
///     itemBuilder: (context, index) {
///       return UserTile(profile: state.profiles[index]);
///     },
///   );
/// }
/// ```
class ProfilesLoaded extends ProfileState {
  /// List of all loaded profiles
  final List<Profile> profiles;
  
  const ProfilesLoaded({required this.profiles});
  
  @override
  List<Object?> get props => [profiles];
}


// =============================================================================
// EMPTY STATE
// =============================================================================

/// No profile exists for this user
/// 
/// **When active:**
/// - New user after signup
/// - Profile was deleted
/// - User hasn't created profile yet
/// 
/// **UI should show:**
/// - "Create your profile" message
/// - "Get started" button
/// - Profile creation form
/// - Friendly illustration
/// 
/// **Example:**
/// ```dart
/// if (state is ProfileEmpty) {
///   return CreateProfilePrompt(userId: state.userId);
/// }
/// ```
class ProfileEmpty extends ProfileState {
  /// User ID for whom no profile exists
  /// Needed to create profile later
  final String userId;
  
  const ProfileEmpty({required this.userId});
  
  @override
  List<Object?> get props => [userId];
}

// =============================================================================
// OPERATION SUCCESS STATE
// =============================================================================

/// Profile operation completed successfully
/// 
/// **When active:**
/// - Profile created successfully
/// - Profile updated successfully
/// - Profile deleted successfully
/// 
/// **UI should show:**
/// - Success message (SnackBar/Toast)
/// - Confirmation animation
/// - Updated data
/// 
/// **Duration:** Brief (shown then transitions)
/// 
/// **Transitions to:**
/// - ProfileLoaded (after create/update)
/// - ProfileInitial or navigate away (after delete)
/// 
/// **Usage pattern:**
/// ```dart
/// BlocListener<ProfileBloc, ProfileState>(
///   listener: (context, state) {
///     if (state is ProfileOperationSuccess) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(state.message)),
///       );
///     }
///   },
/// )
/// ```
class ProfileOperationSuccess extends ProfileState {
  /// Success message to show user
  final String message;
  
  /// Optional: The created/updated profile
  /// Null for delete operations
  final Profile? profile;
  
  const ProfileOperationSuccess({
    required this.message,
    this.profile,
  });
  
  @override
  List<Object?> get props => [message, profile];
}

// =============================================================================
// ERROR STATE
// =============================================================================

/// Something went wrong with profile operation
/// 
/// **When active:**
/// - Network error during load/create/update/delete
/// - Validation failed
/// - Database error
/// - Permission denied
/// 
/// **UI should show:**
/// - Error message
/// - Retry button (if recoverable)
/// - Contact support (if not recoverable)
/// - Error icon
/// 
/// **Types of errors:**
/// - Recoverable: Network issues, timeouts → show retry
/// - Non-recoverable: Invalid data, permissions → show message
/// 
/// **Example:**
/// ```dart
/// if (state is ProfileError) {
///   return ErrorScreen(
///     message: state.message,
///     onRetry: state.isRecoverable ? _retry : null,
///   );
/// }
/// ```
class ProfileError extends ProfileState {
  /// User-friendly error message
  final String message;
  
  /// Can user retry the operation?
  /// true = show retry button
  /// false = operation failed permanently
  final bool isRecoverable;
  
  /// Optional: Technical details for logging
  final String? technicalDetails;
  
  const ProfileError({
    required this.message,
    this.isRecoverable = true,
    this.technicalDetails,
  });
  
  @override
  List<Object?> get props => [message, isRecoverable, technicalDetails];
}

// =============================================================================
// STATE TRANSITION DIAGRAM
// =============================================================================
//
//  ProfileInitial
//       ↓
//  ProfileLoading
//       ↓
//   ┌───┴────┐
//   ↓        ↓
// ProfileLoaded  ProfileEmpty
//   ↓        ↓
//   ↓    ProfileLoading (create)
//   ↓        ↓
//   └────→ ProfileOperationSuccess
//       ↓
//   ProfileLoaded
//
// Any state can → ProfileError → ProfileLoading (retry)
//
// =============================================================================

// =============================================================================
// SUMMARY OF STATES:
// =============================================================================
//
// 1. ProfileInitial - Starting state, nothing happened yet
// 2. ProfileLoading - Operation in progress
// 3. ProfileLoaded - Profile data ready to display
// 4. ProfileEmpty - No profile exists
// 5. ProfileOperationSuccess - Operation completed successfully
// 6. ProfileError - Something went wrong
//
// STATE DESIGN PRINCIPLES:
// - Mutually exclusive (can only be in one state at a time)
// - Contain all data needed by UI
// - Immutable (const constructors)
// - Use Equatable for comparison
// - Clear, descriptive names
//
// UI PATTERN:
// - BlocBuilder: Rebuild on state changes
// - BlocListener: React to state changes (show snackbar, navigate, etc.)
// - Handle all states exhaustively
//
// BENEFITS:
// - Predictable UI
// - Easy to debug (log state changes)
// - Testable (assert on states)
// - Clear data flow
// - Type-safe
//
// =============================================================================
