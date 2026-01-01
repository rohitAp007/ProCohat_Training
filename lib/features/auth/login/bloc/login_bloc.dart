import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_exceptions.dart';
import 'package:supabase_flutter_app/core/utils/validators.dart';
import 'login_event.dart';
import 'login_state.dart';

/// Login BLoC - Handles login screen business logic
/// 
/// This BLoC is production-ready and reusable:
/// - Uses repository pattern for testability
/// - Handles real-time validation
/// - Provides detailed error messages
/// - Can be copied to any project
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;

  LoginBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const LoginInitial()) {
    // Register event handlers
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginPasswordResetRequested>(_onPasswordResetRequested);
  }

  /// Handle email field changes - validates in real-time
  void _onEmailChanged(
    LoginEmailChanged event,
    Emitter<LoginState> emit,
  ) {
    final isValid = isValidEmail(event.email);
    
    emit(LoginEditing(
      email: event.email,
      password: state.password,
      isEmailValid: isValid,
      isPasswordValid: state.isPasswordValid,
    ));
  }

  /// Handle password field changes - validates in real-time
  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    final isValid = event.password.isNotEmpty && event.password.length >= 6;
    
    emit(LoginEditing(
      email: state.email,
      password: event.password,
      isEmailValid: state.isEmailValid,
      isPasswordValid: isValid,
    ));
  }

  /// Handle login submission - calls repository
  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    // Don't submit if form is invalid
    if (!state.isFormValid) {
      return;
    }

    // Emit loading state
    emit(LoginInProgress(
      email: state.email,
      password: state.password,
      isEmailValid: state.isEmailValid,
      isPasswordValid: state.isPasswordValid,
    ));

    try {
      // Call repository to sign in
      await _authRepository.signInWithEmail(
        email: state.email,
        password: state.password,
      );

      // Emit success state
      emit(LoginSuccess(
        email: state.email,
        password: state.password,
      ));
    } on AppAuthException catch (e) {
      // Handle auth exceptions with user-friendly messages
      emit(LoginFailure(
        email: state.email,
        password: state.password,
        isEmailValid: state.isEmailValid,
        isPasswordValid: state.isPasswordValid,
        errorMessage: e.message,
      ));
    } catch (e) {
      // Handle unexpected errors
      emit(LoginFailure(
        email: state.email,
        password: state.password,
        isEmailValid: state.isEmailValid,
        isPasswordValid: state.isPasswordValid,
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  /// Handle password reset request
  Future<void> _onPasswordResetRequested(
    LoginPasswordResetRequested event,
    Emitter<LoginState> emit,
  ) async {
    try {
      await _authRepository.resetPassword(event.email);
      // Success - you can emit a specific state if needed
    } on AppAuthException catch (e) {
      emit(LoginFailure(
        email: state.email,
        password: state.password,
        isEmailValid: state.isEmailValid,
        isPasswordValid: state.isPasswordValid,
        errorMessage: e.message,
      ));
    }
  }
}

