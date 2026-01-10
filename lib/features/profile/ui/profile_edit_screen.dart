/// ============================================================================
/// PROFILE EDIT SCREEN - EDIT USER PROFILE
/// ============================================================================
/// 
/// PURPOSE: Allow user to edit their profile information
/// 
/// LEARNING OBJECTIVES:
/// 1. TextEditingController lifecycle management
/// 2. Form validation patterns
/// 3. Pre-filling forms with existing data
/// 4. Handling form submission with BLoC
/// 5. Preventing memory leaks with dispose()
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../data/profile_model.dart';
import '../widgets/profile_avatar.dart';
import 'package:supabase_flutter_app/core/widgets/loading_overlay.dart';
import 'package:supabase_flutter_app/core/widgets/custom_snackbar.dart';

/// ProfileEditScreen - Edit user profile
/// 
/// **Purpose:**
/// - Edit existing profile
/// - Create new profile (if none exists)
/// - Form validation
/// - Handle save/cancel
/// 
/// **StatefulWidget because:**
/// - Need TextEditingControllers (mutable state)
/// - Need to dispose controllers (memory management)
/// - Form validation state
class ProfileEditScreen extends StatefulWidget {
  /// Existing profile to edit (null if creating new)
  final Profile? profile;
  
  /// User ID (needed for new profiles)
  final String userId;
  
  const ProfileEditScreen({
    super.key,
    this.profile,
    required this.userId,
  });
  
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // -------------------------------------------------------------------------
  // CONTROLLERS
  // -------------------------------------------------------------------------
  
  /// Text field controllers
  /// One controller per text field
  /// MUST be disposed to prevent memory leaks!
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  
  /// Form key for validation
  /// Used to trigger validation on all fields
  final _formKey = GlobalKey<FormState>();
  
  /// Selected date of birth
  /// Separate from controller because DatePicker doesn't use TextEditingController
  DateTime? _selectedDateOfBirth;
  
  /// Track if form has unsaved changes
  /// Used to show "discard changes?" dialog
  bool _hasUnsavedChanges = false;
  
  // -------------------------------------------------------------------------
  // LIFECYCLE METHODS
  // -------------------------------------------------------------------------
  
  @override
  void initState() {
    super.initState();
    
    // STEP 1: Initialize controllers
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _phoneController = TextEditingController();
    
    // STEP 2: Pre-fill with existing data (if editing)
    if (widget.profile != null) {
      _nameController.text = widget.profile!.fullName;
      _bioController.text = widget.profile!.bio ?? '';
      _phoneController.text = widget.profile!.phone ?? '';
      _selectedDateOfBirth = widget.profile!.dateOfBirth;
    }
    
    // STEP 3: Listen for changes to track unsaved changes
    _nameController.addListener(_onFieldChanged);
    _bioController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }
  
  @override
  void dispose() {
    // STEP 4: DISPOSE CONTROLLERS (CRITICAL!)
    // Prevents memory leaks
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  /// Called when any field changes
  /// Marks form as having unsaved changes
  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }
  
  // -------------------------------------------------------------------------
  // BUILD METHOD
  // -------------------------------------------------------------------------
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        // SUCCESS - navigate back
        if (state is ProfileOperationSuccess) {
          CustomSnackBar.showSuccess(
            context: context,
            message: state.message,
          );
          Navigator.pop(context);
        }
        
        // ERROR - show message
        if (state is ProfileError) {
          CustomSnackBar.showError(
            context: context,
            message: state.message,
          );
        }
      },
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final isLoading = state is ProfileLoading;
          
          return LoadingOverlay(
            isLoading: isLoading,
            child: Scaffold(
              appBar: _buildAppBar(context),
              body: _buildForm(context),
            ),
          );
        },
      ),
    );
  }
  
  // ===========================================================================
  // APP BAR
  // ===========================================================================
  
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(widget.profile == null ? 'Create Profile' : 'Edit Profile'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _handleCancel(context),
      ),
      actions: [
        // SAVE BUTTON
        TextButton(
          onPressed: _submitForm,
          child: const Text(
            'Save',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
  
  // ===========================================================================
  // FORM UI
  // ===========================================================================
  
  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AVATAR
            Center(
              child: ProfileAvatar(
                avatarUrl: widget.profile?.avatarUrl,
                fullName: _nameController.text.isNotEmpty
                    ? _nameController.text
                    : 'User',
                size: 100,
                showEditIcon: true,
                onTap: () {
                  // TODO: Implement photo picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Photo upload coming soon!'),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 32),
            
            // FULL NAME FIELD (REQUIRED)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null; // Valid
              },
            ),
            
            const SizedBox(height: 16),
            
            // BIO FIELD (OPTIONAL)
            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself',
                prefixIcon: const Icon(Icons.info_outline),
                border: const OutlineInputBorder(),
                helperText: '${_bioController.text.length}/160 characters',
              ),
              maxLength: 160,
              maxLines: 3,
              validator: (value) {
                if (value != null && value.length > 160) {
                  return 'Bio must be 160 characters or less';
                }
                return null; // Valid
              },
              onChanged: (_) => setState(() {}), // Update character count
            ),
            
            const SizedBox(height: 16),
            
            // PHONE FIELD (OPTIONAL)
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+1 234 567 8900',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                // Optional field, but if provided, validate format
                if (value != null && value.isNotEmpty) {
                  // Basic phone validation (at least 10 digits)
                  final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                  if (digitsOnly.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                }
                return null; // Valid
              },
            ),
            
            const SizedBox(height: 16),
            
            // DATE OF BIRTH FIELD (OPTIONAL)
            InkWell(
              onTap: () => _selectDateOfBirth(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  hintText: 'Select your birthday',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedDateOfBirth != null
                      ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                      : 'Not set',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // SAVE BUTTON (Large)
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Save Changes'),
            ),
            
            const SizedBox(height: 16),
            
            // CANCEL BUTTON
            OutlinedButton(
              onPressed: () => _handleCancel(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
  
  // ===========================================================================
  // FORM ACTIONS
  // ===========================================================================
  
  /// Show date picker for birthday
  Future<void> _selectDateOfBirth(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(), // Can't be in future
      helpText: 'Select your birthday',
    );
    
    if (date != null) {
      setState(() {
        _selectedDateOfBirth = date;
        _hasUnsavedChanges = true;
      });
    }
  }
  
  /// Submit form
  void _submitForm() {
    // STEP 1: Validate all fields
    if (!_formKey.currentState!.validate()) {
      // Validation failed - errors shown automatically
      return;
    }
    
    // STEP 2: Create updated profile
    final now = DateTime.now();
    
    if (widget.profile == null) {
      // CREATING NEW PROFILE
      final newProfile = Profile(
        id: '', // Database will generate
        userId: widget.userId,
        fullName: _nameController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        dateOfBirth: _selectedDateOfBirth,
        createdAt: now,
        updatedAt: now,
      );
      
      // DISPATCH CREATE EVENT
      context.read<ProfileBloc>().add(
            ProfileCreateRequested(profile: newProfile),
          );
    } else {
      // UPDATING EXISTING PROFILE
      final updatedProfile = widget.profile!.copyWith(
        fullName: _nameController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        dateOfBirth: _selectedDateOfBirth,
      );
      
      // DISPATCH UPDATE EVENT
      context.read<ProfileBloc>().add(
            ProfileUpdateRequested(profile: updatedProfile),
          );
    }
  }
  
  /// Handle cancel button
  Future<void> _handleCancel(BuildContext context) async {
    // If no changes, just go back
    if (!_hasUnsavedChanges) {
      Navigator.pop(context);
      return;
    }
    
    // Show discard dialog
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    if (discard == true && context.mounted) {
      Navigator.pop(context);
    }
  }
}

// ============================================================================
// SUMMARY OF WHAT WE LEARNED:
// ============================================================================
//
// 1. TEXTEDITING CONTROLLER LIFECYCLE:
//    - Declare late controllers
//    - Initialize in initState()
//    - Pre-fill with existing data
//    - MUST dispose() to prevent leaks
//
// 2. FORM VALIDATION:
//    - GlobalKey<FormState> for form
//    - validate() triggers all validators
//    - Validators return null (valid) or String (error)
//    - Automatic error display
//
// 3. FORM SUBMISSION:
//    - Validate first
//    - Create/update Profile object
//    - Use copyWith() for updates
//    - Dispatch appropriate event
//
// 4. UNSAVED CHANGES:
//    - Track with _hasUnsavedChanges flag
//    - Listen to controller changes
//    - Show confirmation dialog on cancel
//    - Better UX (prevent accidental data loss)
//
// 5. CONDITIONAL RENDERING:
//    - Different events for create vs update
//    - Different app bar titles
//    - Handle null profile gracefully
//
// 6. DATE PICKER:
//    - showDatePicker() async function
//    - Set min/max dates
//    - Store in separate variable (not controller)
//    - Format for display
//
// 7. FORM BEST PRACTICES:
//    - Clear validation messages
//    - Helper text (character count)
//    - Large touch targets (buttons)
//    - Proper keyboard types
//    - Text capitalization
//
// ============================================================================
