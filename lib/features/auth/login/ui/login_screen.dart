import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/auth_repository.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_state.dart';
import '../widgets/login_form.dart';
import '../../home/home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(
        authRepository: AuthRepository(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Login'),
          centerTitle: true,
        ),
        body: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              // Navigate to home screen on success
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(),
                ),
              );
            }
            if (state is LoginFailure) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Login failed'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const SingleChildScrollView(
            child: LoginForm(),
          ),
        ),
      ),
    );
  }
}

