import 'package:supabase_flutter_app/features/auth/data/auth_exceptions.dart';

/// ============================================================================
/// PROFILE EXCEPTIONS - CUSTOM ERROR TYPES
/// ============================================================================
/// 
/// PURPOSE: Type-safe error handling for profile operations
/// 
/// LEARNING: Custom exceptions make error handling clear and specific
/// 
/// ============================================================================

/// Base exception for profile-related errors
class ProfileException extends AppAuthException {
  ProfileException(
    super.message, {
    super.code,
    super.technicalDetails,
    super.isRecoverable,
    super.suggestedAction,
  });
}

/// Profile not found in database
class ProfileNotFoundException extends ProfileException {
  ProfileNotFoundException()
      : super(
          'Profile not found',
          code: 'PROFILE_NOT_FOUND',
          isRecoverable: true,
          suggestedAction: 'Create a new profile or try again',
        );
}

/// Profile already exists for this user
class ProfileAlreadyExistsException extends ProfileException {
  ProfileAlreadyExistsException()
      : super(
          'Profile already exists for this user',
          code: 'PROFILE_EXISTS',
          isRecoverable: false,
          suggestedAction: 'Update existing profile instead',
        );
}

/// Failed to create profile
class ProfileCreateFailedException extends ProfileException {
  ProfileCreateFailedException([String? details])
      : super(
          'Failed to create profile',
          code: 'PROFILE_CREATE_FAILED',
          technicalDetails: details,
          isRecoverable: true,
          suggestedAction: 'Check your connection and try again',
        );
}

/// Failed to update profile
class ProfileUpdateFailedException extends ProfileException {
  ProfileUpdateFailedException([String? details])
      : super(
          'Failed to update profile',
          code: 'PROFILE_UPDATE_FAILED',
          technicalDetails: details,
          isRecoverable: true,
          suggestedAction: 'Check your connection and try again',
        );
}

/// Failed to delete profile
class ProfileDeleteFailedException extends ProfileException {
  ProfileDeleteFailedException([String? details])
      : super(
          'Failed to delete profile',
          code: 'PROFILE_DELETE_FAILED',
          technicalDetails: details,
          isRecoverable: true,
          suggestedAction: 'Try again or contact support',
        );
}
