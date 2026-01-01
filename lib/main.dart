import 'package:flutter/material.dart';
import 'core/network/supabase_client.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseClientService.initialize();
  runApp(const MyApp());
}
