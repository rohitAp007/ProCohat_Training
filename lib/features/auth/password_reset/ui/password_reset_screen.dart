import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter_app/features/auth/password_reset/bloc/password_reset_bloc.dart';
import 'package:supabase_flutter_app/features/auth/password_reset/bloc/password_reset_state.dart';
import 'package:supabase_flutter_app/features/auth/password_reset/widgets/password_reset_form.dart';
import 'package:supabase_flutter_app/features/auth/password_reset/ui/password_reset_success_screen.dart';
import 'package:supabase_flutter_app/core/widgets/custom_snackbar.dart';

/// Password reset screen
class PasswordResetScreen extends StatelessWidget {
  const PasswordResetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PasswordResetBloc(
        authRepository: AuthRepository(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Forgot Password'),
          centerTitle: true,
        ),
        body: BlocListener<PasswordResetBloc, PasswordResetState>(
          listener: (context, state) {
            if (state is PasswordResetSuccess) {
              // Navigate to success screen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => PasswordResetSuccessScreen(
                    email: state.email,
                  ),
                ),
              );
            }
            if (state is PasswordResetFailure) {
              // Show error with custom snackbar
              CustomSnackBar.showError(
                context,
                state.errorMessage ?? 'Failed to send reset email',
              );
            }
          },
          child: const SingleChildScrollView(
            child: PasswordResetForm(),
          ),
        ),
      ),
    );
  }
}
