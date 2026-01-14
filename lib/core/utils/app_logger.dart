/// ============================================================================
/// APP LOGGER - CENTRALIZED LOGGING UTILITY
/// ============================================================================
/// 
/// PURPOSE: Provide consistent, controllable logging across the app
/// 
/// LEARNING OBJECTIVES:
/// 1. Understand when to log vs when not to
/// 2. Learn logging levels (debug, info, warning, error)
/// 3. Understand production vs development logging
/// 4. Learn how to make logging configurable
///
/// ============================================================================

import 'package:flutter/foundation.dart';

/// AppLogger - Centralized logging utility
/// 
/// **Why centralized logging?**
/// 
/// BEFORE (scattered):
/// ```dart
/// print('User logged in');           // File 1
/// debugPrint('Loading data...');     // File 2
/// print('ERROR: Failed');            // File 3
/// ```
/// 
/// Problems:
/// - Inconsistent format
/// - Hard to disable in production
/// - No log levels
/// - No filtering
/// 
/// AFTER (centralized):
/// ```dart
/// AppLogger.info('User logged in');
/// AppLogger.debug('Loading data...');
/// AppLogger.error('Failed', error, stackTrace);
/// ```
/// 
/// Benefits:
/// - ✅ Consistent format
/// - ✅ Single toggle for production
/// - ✅ Proper log levels
/// - ✅ Easy to filter
/// - ✅ Can send to analytics later
class AppLogger {
  // =========================================================================
  // CONFIGURATION
  // =========================================================================
  
  /// Enable/disable debug logs
  /// Set to false in production builds
  /// 
  /// **In production:**
  /// - Debug logs hidden (too verbose)
  /// - Info logs shown (important events)
  /// - Error logs always shown (critical issues)
  static const bool _debugEnabled = kDebugMode;  // Auto-detects debug mode
  
  /// Enable/disable info logs
  /// Usually kept on even in production
  static const bool _infoEnabled = true;
  
  /// Enable/disable all logging
  /// Emergency kill switch
  static const bool _loggingEnabled = true;
  
  // =========================================================================
  // LOG LEVELS
  // =========================================================================
  
  /// Debug log - Verbose information for development
  /// 
  /// **When to use:**
  /// - Tracing code flow
  /// - Debugging specific issues
  /// - Development only
  /// 
  /// **Examples:**
  /// ```dart
  /// AppLogger.debug('ProfileBloc: Event received $event');
  /// AppLogger.debug('Repository: Calling API with params: $params');
  /// AppLogger.debug('UI: Building widget with state: $state');
  /// ```
  /// 
  /// **NOTE:** Automatically disabled in production (kDebugMode = false)
  static void debug(String message, {String? tag}) {
    if (!_loggingEnabled || !_debugEnabled) return;
    
    final tagPrefix = tag != null ? '[$tag] ' : '';
    final timestamp = _getTimestamp();
    
    if (kDebugMode) {
      // In debug mode, use debugPrint (respects throttling)
      debugPrint('🐛 DEBUG $timestamp $tagPrefix$message');
    }
  }
  
  /// Info log - Important information
  /// 
  /// **When to use:**
  /// - User actions
  /// - State changes
  /// - Important milestones
  /// 
  /// **Examples:**
  /// ```dart
  /// AppLogger.info('User logged in successfully');
  /// AppLogger.info('Profile created');
  /// AppLogger.info('Data synchronized');
  /// ```
  /// 
  /// **NOTE:** Shown in both debug and production
  static void info(String message, {String? tag}) {
    if (!_loggingEnabled || !_infoEnabled) return;
    
    final tagPrefix = tag != null ? '[$tag] ' : '';
    final timestamp = _getTimestamp();
    
    debugPrint('ℹ️ INFO $timestamp $tagPrefix$message');
  }
  
  /// Warning log - Potential issues
  /// 
  /// **When to use:**
  /// - Recoverable errors
  /// - Deprecated features used
  /// - Performance issues
  /// 
  /// **Examples:**
  /// ```dart
  /// AppLogger.warning('Slow network detected');
  /// AppLogger.warning('Using cached data (offline)');
  /// AppLogger.warning('API rate limit approaching');
  /// ```
  static void warning(String message, {String? tag}) {
    if (!_loggingEnabled) return;
    
    final tagPrefix = tag != null ? '[$tag] ' : '';
    final timestamp = _getTimestamp();
    
    debugPrint('⚠️ WARNING $timestamp $tagPrefix$message');
  }
  
  /// Error log - Critical issues
  /// 
  /// **When to use:**
  /// - Exceptions caught
  /// - Failed operations
  /// - Data corruption
  /// 
  /// **Examples:**
  /// ```dart
  /// AppLogger.error('Failed to load profile', error, stackTrace);
  /// AppLogger.error('Database write failed', error);
  /// AppLogger.error('Authentication failed', error);
  /// ```
  /// 
  /// **NOTE:** ALWAYS logged, even in production
  /// These should be sent to crash reporting (Firebase, Sentry, etc.)
  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (!_loggingEnabled) return;
    
    final tagPrefix = tag != null ? '[$tag] ' : '';
    final timestamp = _getTimestamp();
    
    // Always log errors
    debugPrint('🔴 ERROR $timestamp $tagPrefix$message');
    
    if (error != null) {
      debugPrint('  └─ Error: $error');
    }
    
    if (stackTrace != null) {
      debugPrint('  └─ Stack trace:');
      final stackLines = stackTrace.toString().split('\n');
      // Only show first 5 lines to avoid spam
      for (var i = 0; i < stackLines.length && i < 5; i++) {
        debugPrint('     ${stackLines[i]}');
      }
    }
    
    // TODO: Send to crash reporting service
    // if (kReleaseMode) {
    //   FirebaseCrashlytics.instance.recordError(error, stackTrace);
    // }
  }
  
  // =========================================================================
  // HELPERS
  // =========================================================================
  
  /// Get formatted timestamp
  /// Format: HH:mm:ss.SSS
  static String _getTimestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}';
  }
  
  // =========================================================================
  // SPECIALIZED LOGGERS
  // =========================================================================
  
  /// Log BLoC events
  /// 
  /// **Usage:**
  /// ```dart
  /// AppLogger.blocEvent('ProfileBloc', 'ProfileLoadRequested');
  /// ```
  static void blocEvent(String blocName, String eventName) {
    debug('🎯 $blocName: Event → $eventName', tag: 'BLoC');
  }
  
  /// Log BLoC state changes
  /// 
  /// **Usage:**
  /// ```dart
  /// AppLogger.blocState('ProfileBloc', 'ProfileLoading');
  /// ```
  static void blocState(String blocName, String stateName) {
    debug('📦 $blocName: State → $stateName', tag: 'BLoC');
  }
  
  /// Log repository operations
  /// 
  /// **Usage:**
  /// ```dart
  /// AppLogger.repository('ProfileRepository', 'getProfile', params);
  /// ```
  static void repository(String repoName, String method, [dynamic params]) {
    final paramsStr = params != null ? ' with $params' : '';
    debug('📡 $repoName.$method()$paramsStr', tag: 'Repo');
  }
  
  /// Log navigation
  /// 
  /// **Usage:**
  /// ```dart
  /// AppLogger.navigation('HomeScreen', 'ProfileScreen');
  /// ```
  static void navigation(String from, String to) {
    info('🧭 Navigation: $from → $to', tag: 'Nav');
  }
  
  /// Log API calls
  /// 
  /// **Usage:**
  /// ```dart
  /// AppLogger.api('GET', '/profiles/123');
  /// ```
  static void api(String method, String endpoint, [int? statusCode]) {
    final status = statusCode != null ? ' [$statusCode]' : '';
    debug('🌐 API: $method $endpoint$status', tag: 'API');
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================
//
// 1. BASIC LOGGING:
// ```dart
// AppLogger.debug('User tapped login button');
// AppLogger.info('Login successful');
// AppLogger.warning('Slow network connection');
// AppLogger.error('Login failed', error, stackTrace);
// ```
//
// 2. WITH TAGS:
// ```dart
// AppLogger.debug('Data loaded', tag: 'ProfileScreen');
// AppLogger.info('Profile created', tag: 'ProfileBloc');
// ```
//
// 3. BLOC LOGGING:
// ```dart
// AppLogger.blocEvent('ProfileBloc', 'ProfileLoadRequested');
// AppLogger.blocState('ProfileBloc', 'ProfileLoading');
// ```
//
// 4. REPOSITORY LOGGING:
// ```dart
// AppLogger.repository('ProfileRepository', 'getProfile', userId);
// AppLogger.repository('ProfileRepository', 'updateProfile');
// ```
//
// 5. NAVIGATION LOGGING:
// ```dart
// AppLogger.navigation('HomeScreen', 'ProfileEditScreen');
// ```
//
// ============================================================================
// BEST PRACTICES
// ============================================================================
//
// DO:
// ✅ Use debug() for verbose development logs
// ✅ Use info() for important user actions
// ✅ Use warning() for recoverable issues
// ✅ Use error() for exceptions and failures
// ✅ Include context (what, where, why)
// ✅ Use tags to group related logs
//
// DON'T:
// ❌ Log sensitive data (passwords, tokens, PII)
// ❌ Log in tight loops (performance!)
// ❌ Use print() directly (use AppLogger instead)
// ❌ Log everything (signal vs noise)
// ❌ Leave debug logs in production code
//
// PRODUCTION CHECKLIST:
// [ ] Set kDebugMode to false for release builds
// [ ] Implement crash reporting (Firebase/Sentry)
// [ ] Remove temporary debug logs
// [ ] Keep error logs for diagnostics
// [ ] Test logging works in release mode
//
// ============================================================================
