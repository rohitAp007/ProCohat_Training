import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/auth_repository.dart';
import '../bloc/signup_bloc.dart';
import '../bloc/signup_state.dart';
import '../widgets/signup_form.dart';
import '../../home/home_screen.dart';

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
              // Navigate to home screen on success
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(),
                ),
              );
            }
            if (state is SignupFailure) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Signup failed'),
                  backgroundColor: Colors.red,
                ),
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
