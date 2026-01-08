import 'package:flutter/material.dart';
import 'package:supabase_flutter_app/features/splash/splash_screen.dart';
import 'package:supabase_flutter_app/core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProCohat Training',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
