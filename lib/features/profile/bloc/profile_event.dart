/// ============================================================================
/// PROFILE EVENTS - USER ACTIONS FOR PROFILE OPERATIONS
/// ============================================================================
/// 
/// PURPOSE: Define all possible user actions related to profiles
/// 
/// LEARNING: Events represent "what happened" or "what the user wants to do"
/// 
/// ============================================================================

import 'package:equatable/equatable.dart';
import '../data/profile_model.dart';

/// Base class for all profile events
/// 
/// **Why sealed?**
/// - Exhaustive pattern matching (compiler checks we handle all cases)
/// - Can't create instances directly
/// - Must use subclasses
/// 
/// **Why Equatable?**
/// - Compare events by value
/// - Prevents duplicate event processing
/// - Makes testing easier
sealed class ProfileEvent extends Equatable {
  const ProfileEvent();
  
  @override
  List<Object?> get props => [];
}

// =============================================================================
// READ OPERATION EVENTS
// =============================================================================

/// Event to load a user's profile from database
/// 
/// **When fired:**
/// - User opens profile screen
/// - App starts and auto-loads profile
/// - After successful login
/// 
/// **What happens:**
/// 1. UI dispatches this event with userId
/// 2. BLoC receives event
/// 3. BLoC calls repository.getProfile(userId)
/// 4. BLoC emits ProfileLoaded or ProfileEmpty state
/// 
/// **Example:**
/// ```dart
/// context.read<ProfileBloc>().add(
///   ProfileLoadRequested(userId: currentUser.id),
/// );
/// ```
class ProfileLoadRequested extends ProfileEvent {
  /// ID of the user whose profile to load
  final String userId;
  
  const ProfileLoadRequested({required this.userId});
  
  @override
  List<Object?> get props => [userId];
}

// =============================================================================
// CREATE OPERATION EVENT
// =============================================================================

/// Event to create a new profile in database
/// 
/// **When fired:**
/// - User completes profile setup after signup
/// - User clicks "Create Profile" button
/// 
/// **What happens:**
/// 1. UI creates Profile object from form data
/// 2. UI dispatches this event with the profile
/// 3. BLoC validates (optional)
/// 4. BLoC calls repository.createProfile()
/// 5. BLoC emits success or error state
/// 
/// **Example:**
/// ```dart
/// final newProfile = Profile(
///   id: '',  // Database will generate
///   userId: currentUser.id,
///   fullName: nameController.text,
///   bio: bioController.text,
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
/// 
/// context.read<ProfileBloc>().add(
///   ProfileCreateRequested(profile: newProfile),
/// );
/// ```
class ProfileCreateRequested extends ProfileEvent {
  /// The profile object to create
  /// Contains all profile data from form
  final Profile profile;
  
  const ProfileCreateRequested({required this.profile});
  
  @override
  List<Object?> get props => [profile];
}

// =============================================================================
// UPDATE OPERATION EVENT
// =============================================================================

/// Event to update an existing profile in database
/// 
/// **When fired:**
/// - User edits profile and clicks "Save"
/// - User updates profile picture
/// - User changes any profile field
/// 
/// **What happens:**
/// 1. UI modifies Profile using copyWith()
/// 2. UI dispatches this event with updated profile
/// 3. BLoC validates changes
/// 4. BLoC calls repository.updateProfile()
/// 5. BLoC emits updated profile state
/// 
/// **Example:**
/// ```dart
/// final updated = existingProfile.copyWith(
///   fullName: nameController.text,
///   bio: bioController.text,
///   updatedAt: DateTime.now(),
/// );
/// 
/// context.read<ProfileBloc>().add(
///   ProfileUpdateRequested(profile: updated),
/// );
/// ```
class ProfileUpdateRequested extends ProfileEvent {
  /// The updated profile object
  /// Must have same id as existing profile
  final Profile profile;
  
  const ProfileUpdateRequested({required this.profile});
  
  @override
  List<Object?> get props => [profile];
}

// =============================================================================
// DELETE OPERATION EVENT
// =============================================================================

/// Event to delete a profile from database
/// 
/// **When fired:**
/// - User confirms account deletion
/// - Admin removes a profile
/// 
/// **⚠️ WARNING:** This is permanent! Consider soft delete in production.
/// 
/// **What happens:**
/// 1. UI shows confirmation dialog
/// 2. If confirmed, dispatch this event
/// 3. BLoC calls repository.deleteProfile()
/// 4. BLoC emits success state
/// 5. UI navigates to login/signup
/// 
/// **Example:**
/// ```dart
/// final confirmed = await showDeleteConfirmationDialog();
/// 
/// if (confirmed) {
///   context.read<ProfileBloc>().add(
///     ProfileDeleteRequested(profileId: profile.id),
///   );
///   // Navigate away after deletion
/// }
/// ```
class ProfileDeleteRequested extends ProfileEvent {
  /// ID of the profile to delete
  final String profileId;
  
  const ProfileDeleteRequested({required this.profileId});
  
  @override
  List<Object?> get props => [profileId];
}

// =============================================================================
// UI STATE EVENTS
// =============================================================================

/// Event to toggle between view and edit modes
/// 
/// **When fired:**
/// - User clicks "Edit" button (view → edit)
/// - User clicks "Cancel" button (edit → view)
/// 
/// **What happens:**
/// 1. UI dispatches this event
/// 2. BLoC updates isEditMode flag in state
/// 3. UI rebuilds showing form or display
/// 
/// **Example:**
/// ```dart
/// // Toggle edit mode
/// context.read<ProfileBloc>().add(ProfileEditToggled());
/// ```
/// 
/// **Alternative:** Could pass explicit mode parameter
/// ```dart
/// class ProfileEditToggled extends ProfileEvent {
///   final bool isEditMode;
/// }
/// ```
class ProfileEditToggled extends ProfileEvent {
  const ProfileEditToggled();
}

// =============================================================================
// SUMMARY OF EVENTS:
// =============================================================================
//
// 1. ProfileLoadRequested - Load profile from DB
// 2. ProfileCreateRequested - Create new profile
// 3. ProfileUpdateRequested - Update existing profile
// 4. ProfileDeleteRequested - Delete profile
// 5. ProfileEditToggled - Switch view/edit mode
//
// PATTERN:
// - All extend ProfileEvent
// - Immutable (const constructors)
// - Use Equatable for value equality
// - Contain only necessary data
// - Clear, descriptive names (ends with action: Requested, Toggled)
//
// BENEFITS:
// - Type-safe (compiler checks)
// - Clear intentions
// - Easy to test
// - Good for logging/debugging
// - Traceable user actions
//
// =============================================================================
