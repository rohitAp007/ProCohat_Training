import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/auth_repository.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_state.dart';
import '../widgets/login_form.dart';
import 'package:supabase_flutter_app/features/chat/ui/chat_list_screen.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_bloc.dart';
import 'package:supabase_flutter_app/features/profile/data/profile_repository.dart';
import 'package:supabase_flutter_app/core/widgets/custom_snackbar.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(
        authRepository: AuthRepository(),
      ),
      child: Scaffold(
        body: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              // Show success message and navigate
              CustomSnackBar.showSuccess(context, 'Login successful!');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => ProfileBloc(repository: ProfileRepository()),
                    child: const ChatListScreen(),
                  ),
                ),
              );
            }
            if (state is LoginFailure) {
              // Show error with custom snackbar
              CustomSnackBar.showError(
                context,
                state.errorMessage ?? 'Login failed',
              );
            }
          },
          child: const SafeArea(
            child: SingleChildScrollView(
              child: LoginForm(),
            ),
          ),
        ),
      ),
    );
  }
}
