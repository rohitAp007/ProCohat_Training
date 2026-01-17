/// ============================================================================
/// CHAT ID SERVICE - DETERMINISTIC CHAT ID GENERATION
/// ============================================================================
/// 
/// PURPOSE: Generate unique, consistent chat IDs for user pairs
/// 
/// LEARNING OBJECTIVES:
/// 1. Understand deterministic vs random ID generation
/// 2. Learn hashing (SHA-256) for unique IDs
/// 3. Understand why sorting is critical
/// 4. Learn idempotent operations
///
/// ============================================================================

import 'dart:convert';
import 'package:crypto/crypto.dart';

/// ChatIdService - Generates deterministic chat IDs
/// 
/// **Problem**: Two users need same chat_id
/// 
/// **Bad approach (random):**
/// ```dart
/// chatId = Uuid().v4();  // Different every time!
/// ```
/// Result: User A → User B creates chat ABC
///         User B → User A creates chat XYZ  
///         ❌ TWO separate chats!
/// 
/// **Good approach (deterministic):**
/// ```dart
/// chatId = generateChatId(userA, userB);  // SAME every time!
/// ```
/// Result: Both calls produce same chat_id
///         ✅ ONE chat!
/// 
/// **How it works:**
/// 1. Sort user IDs alphabetically
/// 2. Combine: 'user1_user2'
/// 3. SHA-256 hash → consistent output
/// 4. Convert to hex string (UUID-like)
class ChatIdService {
  /// Generate deterministic chat ID from two user IDs
  /// 
  /// **Algorithm:**
  /// ```
  /// Input: userId1='abc', userId2='xyz'
  /// 
  /// Step 1: Sort
  ///   ['abc', 'xyz'].sort() → ['abc', 'xyz']
  /// 
  /// Step 2: Combine
  ///   'abc_xyz'
  /// 
  /// Step 3: Hash (SHA-256)
  ///   sha256('abc_xyz') → [bytes...]
  /// 
  /// Step 4: Convert to hex
  ///   '4a5b6c7d8e9f...' (64 characters)
  /// ```
  /// 
  /// **Key Property: Deterministic**
  /// - Same inputs → Same output (always!)
  /// - Different order → Same output
  /// 
  /// **Examples:**
  /// ```dart
  /// generateChatId('user1', 'user2')  // → 'abc123...'
  /// generateChatId('user2', 'user1')  // → 'abc123...' (SAME!)
  /// 
  /// generateChatId('user1', 'user3')  // → 'xyz789...' (different!)
  /// ```
  String generateChatId(String userId1, String userId2) {
    // STEP 1: Sort user IDs alphabetically
    // Why? Ensures same order regardless of input order
    final sortedIds = getSortedUserIds(userId1, userId2);
    
    // STEP 2: Combine into single string
    // Format: 'user1_user2'
    final combined = '${sortedIds[0]}_${sortedIds[1]}';
    
    // STEP 3: Hash with SHA-256
    // Why SHA-256?
    // - Deterministic (same input = same output)
    // - One-way (can't reverse engineer user IDs)
    // - Collision-resistant (virtually impossible to get same hash)
    final bytes = utf8.encode(combined);  // Convert string to bytes
    final digest = sha256.convert(bytes);  // Hash the bytes
    
    // STEP 4: Convert to hex string
    // Result: '4a5b6c7d...' (64 hex characters)
    return digest.toString();
  }
  
  /// Get sorted pair of user IDs
  /// 
  /// **Purpose:** For storing in chats table
  /// - chats.user1_id (alphabetically first)
  /// - chats.user2_id (alphabetically second)
  /// 
  /// **Why sort?**
  /// - Ensures consistent ordering
  /// - Makes queries easier
  /// - Supports UNIQUE constraint
  /// 
  /// **Example:**
  /// ```dart
  /// getSortedUserIds('zulu', 'alpha')  // → ['alpha', 'zulu']
  /// getSortedUserIds('alpha', 'zulu')  // → ['alpha', 'zulu'] (same!)
  /// ```
  List<String> getSortedUserIds(String userId1, String userId2) {
    // Create list and sort alphabetically
    final ids = [userId1, userId2]..sort();
    return ids;
  }
  
  /// Check if two user IDs would produce same chat
  /// 
  /// **Used for:**
  /// - Validation
  /// - Testing
  /// 
  /// **Example:**
  /// ```dart
  /// isSameChat('user1', 'user2', 'user2', 'user1')  // → true
  /// isSameChat('user1', 'user2', 'user1', 'user3')  // → false
  /// ```
  bool isSameChat(
    String user1Id1,
    String user1Id2,
    String user2Id1,
    String user2Id2,
  ) {
    final chatId1 = generateChatId(user1Id1, user1Id2);
    final chatId2 = generateChatId(user2Id1, user2Id2);
    return chatId1 == chatId2;
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================
//
// 1. GENERATE CHAT ID:
// ```dart
// final chatIdService = ChatIdService();
// final chatId = chatIdService.generateChatId(
//   currentUserId,
//   otherUserId,
// );
// // Result: '4a5b6c7d8e9f...' (same for both users!)
// ```
//
// 2. GET SORTED USERS (for database):
// ```dart
// final sortedIds = chatIdService.getSortedUserIds(userId1, userId2);
// await supabase.from('chats').insert({
//   'id': chatId,
//   'user1_id': sortedIds[0],  // Alphabetically first
//   'user2_id': sortedIds[1],  // Alphabetically second
// });
// ```
//
// 3. VERIFY CONSISTENCY:
// ```dart
// // User A initiates chat
// final chatIdA = chatIdService.generateChatId('userA', 'userB');
//
// // User B initiates chat (same users, different order)
// final chatIdB = chatIdService.generateChatId('userB', 'userA');
//
// assert(chatIdA == chatIdB);  // ✅ Same chat ID!
// ```
//
// ============================================================================
// WHY THIS APPROACH?
// ============================================================================
//
// ALTERNATIVES CONSIDERED:
//
// 1. Random UUID:
//    ❌ Different every time
//    ❌ Need database lookup to find existing chat
//    ❌ Race condition possible
//
// 2. Concat user IDs:
//    ❌ userA_userB != userB_userA (order matters!)
//    ❌ Not proper UUID format
//
// 3. Min/Max user IDs:
//    ⚠️ Works but fragile (depends on UUID format)
//
// 4. Deterministic hash (CHOSEN):
//    ✅ Always same for same users
//    ✅ Order doesn't matter (we sort!)
//    ✅ No database lookup needed
//    ✅ Idempotent (safe to call multiple times)
//
// BENEFITS:
// - No race conditions (both users create same ID)
// - No database lookup needed
// - Matches database UNIQUE constraint
// - Testable (predictable output)
//
// ============================================================================
