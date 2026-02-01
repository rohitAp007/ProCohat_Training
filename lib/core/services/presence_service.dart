import 'package:supabase_flutter/supabase_flutter.dart';

/// User Presence Model
class UserPresence {
  final String userId;
  final String status; // 'online', 'offline', 'away'
  final DateTime lastSeen;
  final DateTime updatedAt;

  UserPresence({
    required this.userId,
    required this.status,
    required this.lastSeen,
    required this.updatedAt,
  });

  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      userId: json['user_id'] as String,
      status: json['status'] as String,
      lastSeen: DateTime.parse(json['last_seen'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'status': status,
      'last_seen': lastSeen.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isOnline => status == 'online';

  String get lastSeenText {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (isOnline) return 'Online';

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} hours ago';
    } else {
      return 'Last seen ${difference.inDays} days ago';
    }
  }
}

/// Presence Service - Manages User Online/Offline Status
class PresenceService {
  final SupabaseClient _supabaseClient;
  String? _currentUserId;

  PresenceService({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client {
    _currentUserId = _supabaseClient.auth.currentUser?.id;
  }

  /// Initialize presence for current user
  Future<void> initialize() async {
    _currentUserId = _supabaseClient.auth.currentUser?.id;
    if (_currentUserId != null) {
      await setOnline();
    }
  }

  /// Set user status to online
  Future<void> setOnline() async {
    if (_currentUserId == null) return;

    try {
      await _supabaseClient.from('user_presence').upsert({
        'user_id': _currentUserId,
        'status': 'online',
        'last_seen': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error setting online status: $e');
    }
  }

  /// Set user status to offline
  Future<void> setOffline() async {
    if (_currentUserId == null) return;

    try {
      await _supabaseClient.from('user_presence').upsert({
        'user_id': _currentUserId,
        'status': 'offline',
        'last_seen': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error setting offline status: $e');
    }
  }

  /// Update last seen timestamp
  Future<void> updateLastSeen() async {
    if (_currentUserId == null) return;

    try {
      await _supabaseClient.from('user_presence').update({
        'last_seen': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', _currentUserId!);
    } catch (e) {
      print('Error updating last seen: $e');
    }
  }

  /// Get presence for a specific user
  Future<UserPresence?> getUserPresence(String userId) async {
    try {
      final response = await _supabaseClient
          .from('user_presence')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserPresence.fromJson(response);
    } catch (e) {
      print('Error getting user presence: $e');
      return null;
    }
  }

  /// Stream presence updates for a specific user
  Stream<UserPresence?> streamUserPresence(String userId) {
    return _supabaseClient
        .from('user_presence')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((data) {
          if (data.isEmpty) return null;
          return UserPresence.fromJson(data.first);
        });
  }

  /// Stream all online users
  Stream<List<UserPresence>> streamOnlineUsers() {
    return _supabaseClient
        .from('user_presence')
        .stream(primaryKey: ['user_id'])
        .eq('status', 'online')
        .map((data) => data.map((json) => UserPresence.fromJson(json)).toList());
  }

  /// Cleanup - set offline on app close
  Future<void> dispose() async {
    await setOffline();
  }
}
