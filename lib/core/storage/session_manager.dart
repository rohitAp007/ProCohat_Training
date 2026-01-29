import 'package:shared_preferences/shared_preferences.dart';

/// Session Manager - Handles persistent login preferences
/// 
/// Reusable across projects for "Remember Me" functionality
class SessionManager {
  static const String _rememberMeKey = 'remember_me';
  
  final SharedPreferences _prefs;

  SessionManager(this._prefs);

  /// Factory constructor to create SessionManager
  static Future<SessionManager> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SessionManager(prefs);
  }

  /// Save remember me preference
  Future<void> setRememberMe(bool value) async {
    await _prefs.setBool(_rememberMeKey, value);
  }

  /// Check if remember me is enabled
  bool getRememberMe() {
    return _prefs.getBool(_rememberMeKey) ?? false;
  }

  /// Clear remember me preference (on logout)
  Future<void> clearRememberMe() async {
    await _prefs.remove(_rememberMeKey);
  }

  /// Clear all session data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
