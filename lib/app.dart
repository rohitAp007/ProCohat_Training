import 'package:flutter/material.dart';
import 'features/auth/login/ui/login_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProChat',
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
