import 'package:flutter/material.dart';
import 'package:supabase_flutter_app/core/auth/auth_state_manager.dart';
import 'package:supabase_flutter_app/features/auth/widgets/auth_wrapper.dart';
import 'package:supabase_flutter_app/core/theme/app_theme.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthStateManager _authStateManager;

  @override
  void initState() {
    super.initState();
    _authStateManager = AuthStateManager();
  }

  @override
  void dispose() {
    _authStateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProCohat Training',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AuthWrapper(authStateManager: _authStateManager),
    );
  }
}
