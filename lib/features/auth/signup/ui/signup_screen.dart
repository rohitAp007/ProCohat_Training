import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter_app/features/auth/signup/bloc/signup_bloc.dart';
import 'package:supabase_flutter_app/features/auth/signup/bloc/signup_state.dart';
import 'package:supabase_flutter_app/features/auth/signup/widgets/signup_form.dart';
import 'package:supabase_flutter_app/features/chat/ui/chat_list_screen.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_bloc.dart';
import 'package:supabase_flutter_app/features/profile/data/profile_repository.dart';
import 'package:supabase_flutter_app/core/widgets/custom_snackbar.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignupBloc(
        authRepository: AuthRepository(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sign Up'),
          centerTitle: true,
        ),
        body: BlocListener<SignupBloc, SignupState>(
          listener: (context, state) {
            if (state is SignupSuccess) {
              // Show success and navigate
              CustomSnackBar.showSuccess(
                context,
                'Account created successfully!',
              );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => ProfileBloc(repository: ProfileRepository()),
                    child: const ChatListScreen(),
                  ),
                ),
              );
            }
            if (state is SignupFailure) {
              // Show error message
              CustomSnackBar.showError(
                context,
                state.errorMessage ?? 'Signup failed',
              );
            }
          },
          child: const SingleChildScrollView(
            child: SignupForm(),
          ),
        ),
      ),
    );
  }
}
