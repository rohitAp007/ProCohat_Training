/// ============================================================================
/// PROFILE REPOSITORY - DATA LAYER FOR PROFILE OPERATIONS
/// ============================================================================
/// 
/// PURPOSE: Handle all profile CRUD operations with Supabase
/// 
/// LEARNING OBJECTIVES:
/// 1. Understand CRUD operations (Create, Read, Update, Delete)
/// 2. Learn repository pattern for data access
/// 3. Handle async database operations
/// 4. Proper error handling and exceptions
///
/// KEY CONCEPTS:
/// - Async/await for database calls
/// - Error handling with try-catch
/// - Custom exceptions
/// - JSON serialization in practice
///
/// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_model.dart';
import 'profile_exceptions.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_exceptions.dart';

/// Profile Repository
/// 
/// **Responsibility**: Manage all profile data operations
/// 
/// **Why Repository Pattern?**
/// - Separates data logic from business logic (BLoC)
/// - Easy to test with mocks
/// - Can swap database easily
/// - Single place for all database queries
/// 
/// **CRUD Operations:**
/// - CREATE: createProfile()
/// - READ: getProfile(), getAllProfiles()
/// - UPDATE: updateProfile()
/// - DELETE: deleteProfile()
class ProfileRepository {
  // -------------------------------------------------------------------------
  // DEPENDENCIES
  // -------------------------------------------------------------------------
  
  /// Supabase client for database operations
  /// Injected via constructor for testability
  final SupabaseClient _supabaseClient;
  
  /// Table name in database
  /// Const for compile-time optimization
  static const String _tableName = 'profiles';
  
  // -------------------------------------------------------------------------
  // CONSTRUCTOR
  // -------------------------------------------------------------------------
  
  /// Creates ProfileRepository
  /// 
  /// **Dependency Injection:**
  /// - Accepts optional SupabaseClient
  /// - Falls back to Supabase.instance.client
  /// - Makes testing easier (inject mock)
  ProfileRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;
  
  // =========================================================================
  // CREATE OPERATION
  // =========================================================================
  
  /// Creates a new profile in the database
  /// 
  /// **When to use:**
  /// After user signs up, create their profile
  /// 
  /// **Process:**
  /// 1. Convert Profile to JSON
  /// 2. INSERT into database
  /// 3. Database returns created row
  /// 4. Convert JSON back to Profile
  /// 5. Return Profile
  /// 
  /// **Example:**
  /// ```dart
  /// final newProfile = Profile(
  ///   id: '', // Database will generate
  ///   userId: currentUser.id,
  ///   fullName: 'John Doe',
  ///   createdAt: DateTime.now(),
  ///   updatedAt: DateTime.now(),
  /// );
  /// 
  /// final created = await repository.createProfile(newProfile);
  /// print('Created profile: ${created.id}');
  /// ```
  /// 
  /// **Throws:**
  /// - [ProfileAlreadyExistsException] if profile exists
  /// - [ProfileCreateFailedException] on failure
  /// - [NetworkException] if no internet
  Future<Profile> createProfile(Profile profile) async {
    try {
      // STEP 1: Convert Profile to JSON
      // Profile object → Map<String, dynamic>
      final profileData = profile.toJson();
      
      // STEP 2: INSERT into database
      // .insert() = SQL INSERT INTO profiles VALUES (...)
      // .select() = SQL SELECT * (return inserted row)
      // .single() = expect exactly one row back
      final response = await _supabaseClient
          .from(_tableName)
          .insert(profileData)
          .select()
          .single();
      
      // STEP 3: Convert response to Profile
      // Map<String, dynamic> → Profile object
      return Profile.fromJson(response);
      
    } on PostgrestException catch (e) {
      // HANDLE DATABASE ERRORS
      // PostgrestException = Supabase-specific error
      
      if (e.code == '23505') {
        // 23505 = unique constraint violation
        // Profile with this user_id already exists
        throw ProfileAlreadyExistsException();
      }
      
      // Other database errors
      throw ProfileCreateFailedException(e.message);
      
    } catch (e) {
      // HANDLE OTHER ERRORS
      // Network issues, unexpected errors, etc.
      
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      
      throw ProfileCreateFailedException(e.toString());
    }
  }
  
  // =========================================================================
  // READ OPERATIONS
  // =========================================================================
  
  /// Gets a profile by user ID
  /// 
  /// **When to use:**
  /// - Load user's profile on app start
  /// - View profile screen
  /// - Check if profile exists
  /// 
  /// **Process:**
  /// 1. Query database for user_id
  /// 2. If found, convert to Profile
  /// 3. If not found, return null
  /// 
  /// **Example:**
  /// ```dart
  /// final profile = await repository.getProfile(currentUser.id);
  /// 
  /// if (profile != null) {
  ///   print('Welcome, ${profile.fullName}!');
  /// } else {
  ///   print('Please create your profile');
  /// }
  /// ```
  /// 
  /// **Returns:** Profile if found, null otherwise
  /// 
  /// **Throws:**
  /// - [NetworkException] if no internet
  /// - [ProfileException] on other errors
  Future<Profile?> getProfile(String userId) async {
    try {
      // DEBUG: Print what we're searching for
      print('🔍 ProfileRepository: Loading profile for user_id: $userId');
      
      // QUERY DATABASE
      // SELECT * FROM profiles WHERE user_id = userId LIMIT 1
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('user_id', userId)  // WHERE user_id = userId
          .maybeSingle();          // Return null if not found
      
      // DEBUG: Print response
      print('📦 ProfileRepository: Response: $response');
      
      // CHECK RESPONSE
      if (response == null) {
        // No profile found
        print('❌ ProfileRepository: No profile found for user_id: $userId');
        return null;
      }
      
      // CONVERT TO PROFILE
      print('✅ ProfileRepository: Profile found, converting to object');
      return Profile.fromJson(response);
      
    } catch (e, stackTrace) {
      // DEBUG: Print full error
      print('🔴 ProfileRepository ERROR:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      
      // HANDLE ERRORS
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      
      throw ProfileException(
        'Failed to load profile',
        code: 'PROFILE_LOAD_FAILED',
        technicalDetails: e.toString(),
      );
    }
  }
  
  /// Gets all profiles (admin feature)
  /// 
  /// **When to use:**
  /// - Admin dashboard
  /// - User directory
  /// - Analytics
  /// 
  /// **Note:** Requires proper RLS policies!
  /// 
  /// **Returns:** List of all profiles
  Future<List<Profile>> getAllProfiles() async {
    try {
      // SELECT * FROM profiles ORDER BY created_at DESC
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);
      
      // CONVERT EACH ROW TO PROFILE
      // List<dynamic> → List<Profile>
      return (response as List)
          .map((json) => Profile.fromJson(json as Map<String, dynamic>))
          .toList();
      
    } catch (e) {
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      
      throw ProfileException(
        'Failed to load profiles',
        code: 'PROFILES_LOAD_FAILED',
        technicalDetails: e.toString(),
      );
    }
  }
  
  // =========================================================================
  // UPDATE OPERATION
  // =========================================================================
  
  /// Updates an existing profile
  /// 
  /// **When to use:**
  /// - User edits their profile
  /// - Update specific fields
  /// - Change profile picture
  /// 
  /// **Process:**
  /// 1. Convert Profile to JSON
  /// 2. UPDATE database row
  /// 3. Return updated Profile
  /// 
  /// **Example:**
  /// ```dart
  /// // Load existing profile
  /// final profile = await repository.getProfile(userId);
  /// 
  /// // Update bio
  /// final updated = profile!.copyWith(
  ///   bio: 'New bio text',
  ///   updatedAt: DateTime.now(),
  /// );
  /// 
  /// // Save to database
  /// await repository.updateProfile(updated);
  /// ```
  /// 
  /// **Throws:**
  /// - [ProfileNotFoundException] if profile doesn't exist
  /// - [ProfileUpdateFailedException] on failure
  /// - [NetworkException] if no internet
  Future<Profile> updateProfile(Profile profile) async {
    try {
      // CONVERT TO JSON (excluding id for safety)
      final profileData = profile.toJson();
      profileData.remove('id'); // Don't update ID
      profileData['updated_at'] = DateTime.now().toIso8601String();
      
      // UPDATE DATABASE
      // UPDATE profiles SET ... WHERE id = profile.id
      final response = await _supabaseClient
          .from(_tableName)
          .update(profileData)
          .eq('id', profile.id)  // WHERE id = profile.id
          .select()
          .single();
      
      // RETURN UPDATED PROFILE
      return Profile.fromJson(response);
      
    } on PostgrestException catch (e) {
      // HANDLE DATABASE ERRORS
      
      if (e.code == 'PGRST116') {
        // No rows affected = profile doesn't exist
        throw ProfileNotFoundException();
      }
      
      throw ProfileUpdateFailedException(e.message);
      
    } catch (e) {
      // HANDLE OTHER ERRORS
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      
      throw ProfileUpdateFailedException(e.toString());
    }
  }
  
  // =========================================================================
  // DELETE OPERATION
  // =========================================================================
  
  /// Deletes a profile from database
  /// 
  /// **When to use:**
  /// - User deletes account
  /// - Admin removes profile
  /// - Testing/cleanup
  /// 
  /// **Warning:** This is permanent!  
  /// Consider soft delete (is_deleted flag) for production
  /// 
  /// **Process:**
  /// 1. DELETE from database
  /// 2. Confirm deletion
  /// 
  /// **Example:**
  /// ```dart
  /// // Confirm with user first!
  /// final confirmed = await showDeleteConfirmation();
  /// 
  /// if (confirmed) {
  ///   await repository.deleteProfile(profileId);
  ///   // Navigate to login/signup
  /// }
  /// ```
  /// 
  /// **Throws:**
  /// - [ProfileNotFoundException] if profile doesn't exist
  /// - [ProfileDeleteFailedException] on failure
  /// - [NetworkException] if no internet
  Future<void> deleteProfile(String profileId) async {
    try {
      // DELETE FROM DATABASE
      // DELETE FROM profiles WHERE id = profileId
      await _supabaseClient
          .from(_tableName)
          .delete()
          .eq('id', profileId);
      
      // Success - no return value needed
      
    } on PostgrestException catch (e) {
      // HANDLE DATABASE ERRORS
      throw ProfileDeleteFailedException(e.message);
      
    } catch (e) {
      // HANDLE OTHER ERRORS
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      
      throw ProfileDeleteFailedException(e.toString());
    }
  }
}

// ============================================================================
// SUMMARY OF WHAT WE LEARNED:
// ============================================================================
//
// 1. CRUD OPERATIONS:
//    - CREATE: insert() new data
//    - READ: select() existing data
//    - UPDATE: update() existing data
//    - DELETE: delete() data
//
// 2. ASYNC/AWAIT:
//    - Database operations are async
//    - Use Future<T> for return types
//    - await keyword waits for completion
//    - try-catch for error handling
//
// 3. SUPABASE QUERY METHODS:
//    - from(table): Specify table
//    - insert(data): Add new row
//    - select(): Fetch data
//    - update(data): Modify row
//    - delete(): Remove row
//    - eq(column, value): WHERE clause
//    - single(): Expect one row
//    - maybeSingle(): Return null if not found
//
// 4. ERROR HANDLING:
//    - PostgrestException: Database errors
//    - Custom exceptions: Type-safe errors
//    - Network detection: Check for connectivity
//    - Specific error codes: Handle different failures
//
// 5. REPOSITORY PATTERN:
//    - Single responsibility: Only data operations
//    - Dependency injection: Testable
//    - Abstraction: Hides Supabase details
//    - Consistent API: Same methods for all features
//
// 6. JSON IN PRACTICE:
//    - toJson(): Before insert/update
//    - fromJson(): After select
//    - Type safety: Compile-time checks
//    - Clear data flow: Dart ↔ Database
//
// ============================================================================
