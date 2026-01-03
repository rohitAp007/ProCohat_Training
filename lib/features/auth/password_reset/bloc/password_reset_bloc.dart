import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_exceptions.dart';
import 'package:supabase_flutter_app/core/utils/validators.dart';
import 'password_reset_event.dart';
import 'password_reset_state.dart';

/// Password Reset BLoC - Handles password reset flow
/// 
/// Reusable across projects for forgot password functionality
class PasswordResetBloc extends Bloc<PasswordResetEvent, PasswordResetState> {
  final AuthRepository _authRepository;

  PasswordResetBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const PasswordResetInitial()) {
    on<PasswordResetEmailChanged>(_onEmailChanged);
    on<PasswordResetSubmitted>(_onSubmitted);
    on<PasswordResetReset>(_onReset);
  }

  /// Handle email field changes
  void _onEmailChanged(
    PasswordResetEmailChanged event,
    Emitter<PasswordResetState> emit,
  ) {
    final isValid = isValidEmail(event.email);

    emit(PasswordResetEditing(
      email: event.email,
      isEmailValid: isValid,
    ));
  }

  /// Handle password reset submission
  Future<void> _onSubmitted(
    PasswordResetSubmitted event,
    Emitter<PasswordResetState> emit,
  ) async {
    // Don't submit if email is invalid
    if (!state.isEmailValid) {
      return;
    }

    // Emit loading state
    emit(PasswordResetInProgress(
      email: state.email,
    ));

    try {
      // Call repository to send reset email
      await _authRepository.resetPassword(state.email);

      // Emit success state
      emit(PasswordResetSuccess(
        email: state.email,
      ));
    } on AppAuthException catch (e) {
      // Handle auth exceptions
      emit(PasswordResetFailure(
        email: state.email,
        isEmailValid: state.isEmailValid,
        errorMessage: e.message,
      ));
    } catch (e) {
      // Handle unexpected errors
      emit(PasswordResetFailure(
        email: state.email,
        isEmailValid: state.isEmailValid,
        errorMessage: 'Failed to send reset email. Please try again.',
      ));
    }
  }

  /// Reset to initial state
  void _onReset(
    PasswordResetReset event,
    Emitter<PasswordResetState> emit,
  ) {
    emit(const PasswordResetInitial());
  }
}
