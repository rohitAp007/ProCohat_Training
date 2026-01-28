/// ============================================================================
/// PROFILE BLOC - STATE MANAGEMENT FOR PROFILE CRUD OPERATIONS
/// ============================================================================
/// 
/// PURPOSE: Handle all profile-related business logic and state changes
/// 
/// LEARNING OBJECTIVES:
/// 1. Understand BLoC event handling for CRUD
/// 2. Learn state transitions and management
/// 3. Handle async operations properly
/// 4. Implement comprehensive error handling
///
/// KEY CONCEPTS:
/// - Event handlers for each operation
/// - State emissions based on results
/// - Repository integration
/// - Error recovery patterns
///
/// ============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';
import '../data/profile_repository.dart';
import '../data/profile_exceptions.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_exceptions.dart';
import 'package:supabase_flutter_app/core/utils/app_logger.dart';

/// ProfileBloc - Manages profile state and business logic
/// 
/// **Responsibilities:**
/// - Process profile-related events
/// - Call repository for data operations
/// - Emit appropriate states based on results
/// - Handle errors gracefully
/// 
/// **Does NOT:**
/// - Know about UI widgets
/// - Direct ly access Supabase
/// - Handle navigation
/// - Show dialogs/snackbars
/// 
/// **Architecture:**
/// ```
/// UI → Event → ProfileBloc → Repository → Database
/// UI ← State ← ProfileBloc ← Repository ← Database
/// ```
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  // -------------------------------------------------------------------------
  // DEPENDENCIES
  // -------------------------------------------------------------------------
  
  /// Repository for database operations
  /// Injected for testability
  final ProfileRepository _repository;
  
  // -------------------------------------------------------------------------
  // CONSTRUCTOR
  // -------------------------------------------------------------------------
  
  /// Creates ProfileBloc with required dependencies
  /// 
  /// **Dependency Injection:**
  /// - Makes testing easy (inject mock repository)
  /// - Follows single responsibility
  /// - Loose coupling
  /// 
  /// **Initial State:**
  /// - ProfileInitial() = nothing loaded yet
  /// - UI shows placeholder or loading skeleton
  /// 
  /// **Event Registration:**
  /// - on<EventType>(handler) = "When this event comes, call this handler"
  /// - Each event type has its own handler function
  ProfileBloc({required ProfileRepository repository})
      : _repository = repository,
        super(const ProfileInitial()) {
    // DEBUG: Log BLoC initialization
    AppLogger.debug('Constructor called', tag: 'ProfileBloc');
    AppLogger.debug('Initial state: ProfileInitial', tag: 'ProfileBloc');
    AppLogger.debug('Registering event handlers...', tag: 'ProfileBloc');
    
    // Register event handlers
    // When ProfileLoadRequested event comes → call _onLoadRequested
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfilesLoadAllRequested>(_onLoadAllRequested);  // NEW: For chat list
    on<ProfileCreateRequested>(_onCreateRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
    on<ProfileDeleteRequested>(_onDeleteRequested);
    on<ProfileEditToggled>(_onEditToggled);
    
    AppLogger.debug('All event handlers registered', tag: 'ProfileBloc');
  }
  
  // ===========================================================================
  // EVENT HANDLER: LOAD PROFILE
  // ===========================================================================
  
  /// Handles ProfileLoadRequested event
  /// 
  /// **Flow:**
  /// 1. Emit loading state (show spinner)
  /// 2. Call repository to get profile
  /// 3. Check result (found or not found)
  /// 4. Emit appropriate state
  /// 
  /// **States emitted:**
  /// - ProfileLoading → immediately
  /// - ProfileLoaded(profile) → if found
  /// - ProfileEmpty(userId) → if not found
  /// - ProfileError() → if error
  /// 
  /// **Example usage:**
  /// ```dart
  /// context.read<ProfileBloc>().add(
  ///   ProfileLoadRequested(userId: currentUser.id),
  /// );
  /// ```
  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // DEBUG: Print event received
    AppLogger.blocEvent('ProfileBloc', 'ProfileLoadRequested for userId: ${event.userId}');
    
    // STEP 1: Show loading state
    AppLogger.debug('Emitting ProfileLoading state', tag: 'ProfileBloc');
    emit(const ProfileLoading());
    
    try {
      // STEP 2: Call repository to fetch profile
      AppLogger.repository('ProfileRepository', 'getProfile', event.userId);
      final profile = await _repository.getProfile(event.userId);
      
      // STEP 3: Check if profile was found
      if (profile != null) {
        // Profile exists - show it
        AppLogger.debug('Profile found! Emitting ProfileLoaded state', tag: 'ProfileBloc');
        emit(ProfileLoaded(profile: profile, isEditMode: false));
      } else {
        // No profile found - show empty state
        AppLogger.debug('No profile found. Emitting ProfileEmpty state', tag: 'ProfileBloc');
        emit(ProfileEmpty(userId: event.userId));
      }
      
    } on NetworkException catch (e) {
      // HANDLE NETWORK ERRORS
      AppLogger.error('NetworkException caught', error: e, tag: 'ProfileBloc');
      emit(ProfileError(
        message: e.message,
        isRecoverable: true,
      ));
      
    } on ProfileException catch (e) {
      // HANDLE PROFILE-SPECIFIC ERRORS
      AppLogger.error('ProfileException caught', error: e, tag: 'ProfileBloc');
      emit(ProfileError(
        message: e.message,
        isRecoverable: e.isRecoverable,
        technicalDetails: e.technicalDetails,
      ));
      
    } catch (e) {
      // HANDLE UNEXPECTED ERRORS
      AppLogger.error('Unexpected error during profile load', error: e, tag: 'ProfileBloc');
      emit(ProfileError(
        message: 'Failed to load profile',
        isRecoverable: true,
        technicalDetails: e.toString(),
      ));
    }
  }
  
  // ===========================================================================
  // EVENT HANDLER: LOAD ALL PROFILES
  // ===========================================================================
  
  /// Handles ProfilesLoadAllRequested event
  /// 
  /// **Flow:**
  /// 1. Emit loading state
  /// 2. Call repository to get all profiles
  /// 3. Emit ProfilesLoaded with list
  /// 
  /// **Use case:** Chat list screen needs all users
  /// 
  /// **States emitted:**
  /// - ProfileLoading → immediately
  /// - ProfilesLoaded(profiles) → on success
  /// - ProfileError() → on failure
  Future<void> _onLoadAllRequested(
    ProfilesLoadAllRequested event,
    Emitter<ProfileState> emit,
  ) async {
    AppLogger.blocEvent('ProfileBloc', 'ProfilesLoadAllRequested');
    
    try {
      // STEP 1: Emit loading state
      AppLogger.debug('Emitting ProfileLoading state', tag: 'ProfileBloc');
      emit(const ProfileLoading());
      
      // STEP 2: Fetch all profiles from repository
      AppLogger.repository('ProfileRepository', 'getAllProfiles');
      final profiles = await _repository.getAllProfiles();
      
      // STEP 3: Emit loaded state with profiles
      AppLogger.debug('Got ${profiles.length} profiles', tag: 'ProfileBloc');
      AppLogger.debug('Emitting ProfilesLoaded state', tag: 'ProfileBloc');
      emit(ProfilesLoaded(profiles: profiles));
      
    } on NetworkException catch (e) {
      AppLogger.error('NetworkException', error: e, tag: 'ProfileBloc');
      emit(ProfileError(
        message: e.message,
        isRecoverable: true,
      ));
      
    } on ProfileException catch (e) {
      AppLogger.error('ProfileException', error: e, tag: 'ProfileBloc');
      emit(ProfileError(
        message: e.message,
        isRecoverable: e.isRecoverable,
        technicalDetails: e.technicalDetails,
      ));
      
    } catch (e) {
      AppLogger.error('Unexpected error loading users', error: e, tag: 'ProfileBloc');
      emit(ProfileError(
        message: 'Failed to load users',
        isRecoverable: true,
        technicalDetails: e.toString(),
      ));
    }
  }

  
  // ===========================================================================
  // EVENT HANDLER: CREATE PROFILE
  // ===========================================================================
  
  /// Handles ProfileCreateRequested event
  /// 
  /// **Flow:**
  /// 1. Emit loading state
  /// 2. Call repository to create profile
  /// 3. Emit success with created profile
  /// 4. Emit loaded state with new profile
  /// 
  /// **States emitted:**
  /// - ProfileLoading → immediately
  /// - ProfileOperationSuccess() → on success
  /// - ProfileLoaded(profile) → final state
  /// - ProfileError() → on failure
  /// 
  /// **Example usage:**
  /// ```dart
  /// final newProfile = Profile(...);
  /// context.read<ProfileBloc>().add(
  ///   ProfileCreateRequested(profile: newProfile),
  /// );
  /// ```
  Future<void> _onCreateRequested(
    ProfileCreateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // DEBUG: Log create request
    AppLogger.blocEvent('ProfileBloc', 'ProfileCreateRequested');
    AppLogger.debug('Profile data: ${event.profile.toJson()}', tag: 'ProfileBloc');
    
    // STEP 1: Show loading
    AppLogger.debug('Emitting ProfileLoading state', tag: 'ProfileBloc');
    emit(const ProfileLoading());
    
    try {
      // STEP 2: Create profile in database
      AppLogger.repository('ProfileRepository', 'createProfile');
      final createdProfile = await _repository.createProfile(event.profile);
      
      // STEP 3: Emit success message
      AppLogger.info('Profile created successfully', tag: 'ProfileBloc');
      emit(const ProfileOperationSuccess(
        message: 'Profile created successfully!',
      ));
      
      // STEP 4: Emit loaded state with new profile
      AppLogger.debug('Emitting ProfileLoaded state', tag: 'ProfileBloc');
      emit(ProfileLoaded(profile: createdProfile, isEditMode: false));
      
    } on ProfileAlreadyExistsException catch (e) {
      AppLogger.error('ProfileAlreadyExistsException', error: e, tag: 'ProfileBloc');
      emit(ProfileError(
        message: e.message,
        isRecoverable: false,
      ));
      
    } on NetworkException catch (e) {
      AppLogger.error('NetworkException', error: e, tag: 'ProfileBloc');
      emit(ProfileError(
        message: e.message,
        isRecoverable: true,
      ));
      
    } on ProfileCreateFailedException catch (e) {
      AppLogger.error('ProfileCreateFailedException', error: e, tag: 'ProfileBloc');
      emit(ProfileError(
        message: e.message,
        isRecoverable: e.isRecoverable,
        technicalDetails: e.technicalDetails,
      ));
      
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during CREATE', error: e, stackTrace: stackTrace, tag: 'ProfileBloc');
      emit(ProfileError(
        message: 'Failed to create profile',
        isRecoverable: true,
        technicalDetails: e.toString(),
      ));
    }
  }
  
  // ===========================================================================
  // EVENT HANDLER: UPDATE PROFILE
  // ===========================================================================
  
  /// Handles ProfileUpdateRequested event
  /// 
  /// **Flow:**
  /// 1. Emit loading state
  /// 2. Call repository to update profile
  /// 3. Emit success message
  /// 4. Emit loaded state with updated profile
  /// 
  /// **States emitted:**
  /// - ProfileLoading → immediately
  /// - ProfileOperationSuccess() → on success
  /// - ProfileLoaded(updated) → final state
  /// - ProfileError() → on failure
  /// 
  /// **Example usage:**
  /// ```dart
  /// final updated = profile.copyWith(bio: 'New bio');
  /// context.read<ProfileBloc>().add(
  ///   ProfileUpdateRequested(profile: updated),
  /// );
  /// ```
  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    
    try {
      // UPDATE in database
      final updatedProfile = await _repository.updateProfile(event.profile);
      
      // SUCCESS message
      emit(const ProfileOperationSuccess(
        message: 'Profile updated successfully!',
      ));
      
      // BACK TO LOADED state with updates
      // isEditMode = false to show view
      emit(ProfileLoaded(profile: updatedProfile, isEditMode: false));
      
    } on ProfileNotFoundException catch (e) {
      // Profile doesn't exist (was deleted?)
      emit(ProfileError(
        message: e.message,
        isRecoverable: false,
      ));
      
    } on NetworkException catch (e) {
      emit(ProfileError(
        message: e.message,
        isRecoverable: true,
      ));
      
    } on ProfileUpdateFailedException catch (e) {
      emit(ProfileError(
        message: e.message,
        isRecoverable: e.isRecoverable,
        technicalDetails: e.technicalDetails,
      ));
      
    } catch (e) {
      emit(ProfileError(
        message: 'Failed to update profile',
        isRecoverable: true,
        technicalDetails: e.toString(),
      ));
    }
  }
  
  // ===========================================================================
  // EVENT HANDLER: DELETE PROFILE
  // ===========================================================================
  
  /// Handles ProfileDeleteRequested event
  /// 
  /// **⚠️ WARNING: PERMANENT DELETION**
  /// UI should show confirmation dialog first!
  /// 
  /// **Flow:**
  /// 1. Emit loading state
  /// 2. Call repository to delete profile
  /// 3. Emit success message
  /// 4. UI should navigate to login/signup
  /// 
  /// **States emitted:**
  /// - ProfileLoading → immediately
  /// - ProfileOperationSuccess() → on success
  /// - ProfileError() → on failure
  /// 
  /// **Example usage:**
  /// ```dart
  /// final confirmed = await showConfirmationDialog();
  /// if (confirmed) {
  ///   context.read<ProfileBloc>().add(
  ///     ProfileDeleteRequested(profileId: profile.id),
  ///   );
  ///   // Then navigate away
  /// }
  /// ```
  Future<void> _onDeleteRequested(
    ProfileDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    
    try {
      // DELETE from database
      // This is permanent!
      await _repository.deleteProfile(event.profileId);
      
      // SUCCESS message
      // UI should listen and navigate to login
      emit(const ProfileOperationSuccess(
        message: 'Profile deleted successfully',
      ));
      
      // Could emit ProfileInitial() here
      // Or let UI handle navigation after deletion
      
    } on ProfileNotFoundException catch (e) {
      // Profile already deleted?
      emit(ProfileError(
        message: e.message,
        isRecoverable: false,
      ));
      
    } on NetworkException catch (e) {
      emit(ProfileError(
        message: e.message,
        isRecoverable: true,
      ));
      
    } on ProfileDeleteFailedException catch (e) {
      emit(ProfileError(
        message: e.message,
        isRecoverable: e.isRecoverable,
        technicalDetails: e.technicalDetails,
      ));
      
    } catch (e) {
      emit(ProfileError(
        message: 'Failed to delete profile',
        isRecoverable: true,
        technicalDetails: e.toString(),
      ));
    }
  }
  
  // ===========================================================================
  // EVENT HANDLER: TOGGLE EDIT MODE
  // ===========================================================================
  
  /// Handles ProfileEditToggled event
  /// 
  /// **Flow:**
  /// 1. Check current state
  /// 2. If ProfileLoaded, toggle isEditMode flag
  /// 3. Emit updated state
  /// 
  /// **States emitted:**
  /// - ProfileLoaded(isEditMode: !current) → always
  /// 
  /// **Example usage:**
  /// ```dart
  /// // User clicks "Edit" button
  /// context.read<ProfileBloc>().add(ProfileEditToggled());
  /// 
  /// // User clicks "Cancel" button
  /// context.read<ProfileBloc>().add(ProfileEditToggled());
  /// ```
  /// 
  /// **Note:** Only works if currently in ProfileLoaded state
  void _onEditToggled(
    ProfileEditToggled event,
    Emitter<ProfileState> emit,
  ) {
    // Only toggle if we have a loaded profile
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      
      // TOGGLE edit mode
      // true → false or false → true
      emit(ProfileLoaded(
        profile: currentState.profile,
        isEditMode: !currentState.isEditMode,
      ));
    }
    // If not ProfileLoaded, ignore this event
    // UI shouldn't dispatch if not in loaded state
  }
}

// ============================================================================
// SUMMARY OF WHAT WE LEARNED:
// ============================================================================
//
// 1. BLOC STRUCTURE:
//    - Extends Bloc<EventType, StateType>
//    - Takes repository via dependency injection
//    - Starts with initial state
//    - Registers event handlers in constructor
//
// 2. EVENT HANDLERS:
//    - Async functions (Future<void>)
//    - Receive event and emitter
//    - Call repository for data operations
//    - Emit states based on results
//    - Handle all error types
//
// 3. STATE EMISSIONS:
//    - emit(state) = send new state to UI
//    - Multiple emissions allowed (loading → success → loaded)
//    - Latest emission is current state
//    - UI rebuilds on each emission
//
// 4. ERROR HANDLING:
//    - Try-catch for all async operations
//    - Specific catch for each exception type
//    - Generic catch for unexpected errors
//    - Always emit error state (never throw)
//
// 5. CRUD PATTERN:
//    - CREATE: call repository → success state → loaded state
//    - READ: call repository → loaded or empty state
//    - UPDATE: call repository → success state → loaded state
//    - DELETE: call repository → success state → navigate away
//
// 6. STATE TRANSITIONS:
//    - Always emit loading first
//    - Then emit result (success or error)
//    - For create/update, also emit final loaded state
//    - For errors, provide recovery option
//
// 7. BEST PRACTICES:
//    - Inject dependencies (testable)
//    - Handle all error cases
//    - Provide user feedback (success messages)
//    - Keep BLoC pure (no UI logic)
//    - Clear state transitions
//
// ============================================================================
