/// ============================================================================
/// STORAGE SERVICE - Upload media to Supabase Storage
/// ============================================================================

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  static const String chatMediaBucket = 'chat-media';
  
  /// Upload image and return public URL
  Future<String> uploadImage(String filePath, String userId) async {
    try {
      final file = File(filePath);
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(filePath)}';
      final storagePath = 'images/$fileName';
      
      await _supabase.storage
          .from(chatMediaBucket)
          .upload(storagePath, file);
      
      final publicUrl = _supabase.storage
          .from(chatMediaBucket)
          .getPublicUrl(storagePath);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
  
  /// Upload video and return public URL
  Future<String> uploadVideo(String filePath, String userId) async {
    try {
      final file = File(filePath);
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(filePath)}';
      final storagePath = 'videos/$fileName';
      
      await _supabase.storage
          .from(chatMediaBucket)
          .upload(storagePath, file);
      
      final publicUrl = _supabase.storage
          .from(chatMediaBucket)
          .getPublicUrl(storagePath);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }
  
  /// Upload file and return public URL
  Future<String> uploadFile(String filePath, String userId) async {
    try {
      final file = File(filePath);
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';
      final storagePath = 'files/$fileName';
      
      await _supabase.storage
          .from(chatMediaBucket)
          .upload(storagePath, file);
      
      final publicUrl = _supabase.storage
          .from(chatMediaBucket)
          .getPublicUrl(storagePath);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }
  
  /// Get file size
  int getFileSize(String filePath) {
    final file = File(filePath);
    return file.lengthSync();
  }
}
