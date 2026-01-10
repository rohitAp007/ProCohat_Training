/// ============================================================================
/// PROFILE AVATAR - REUSABLE AVATAR WITH FALLBACK
/// ============================================================================
/// 
/// PURPOSE: Display user's profile picture or initials as fallback
/// 
/// LEARNING: Reusable widgets reduce code duplication
/// 
/// ============================================================================

import 'package:flutter/material.dart';

/// ProfileAvatar Widget
/// 
/// **Purpose:**
/// - Display profile picture if available
/// - Show initials as fallback if no picture
/// - Customizable size
/// - Consistent styling
/// 
/// **Why Reusable Widget?**
/// - Use in multiple screens (view, edit, list)
/// - Consistent appearance everywhere
/// - Easy to update design in one place
/// - Reduces code duplication
/// 
/// **Example Usage:**
/// ```dart
/// // Large avatar for profile screen
/// ProfileAvatar(
///   avatarUrl: profile.avatarUrl,
///   fullName: profile.fullName,
///   size: 120,
/// )
/// 
/// // Small avatar for list
/// ProfileAvatar(
///   avatarUrl: user.avatarUrl,
///   fullName: user.fullName,
///   size: 40,
/// )
/// ```
class ProfileAvatar extends StatelessWidget {
  /// URL to profile picture (can be null)
  /// If null, shows initials instead
  final String? avatarUrl;
  
  /// Full name for generating initials
  /// Example: "John Doe" → "JD"
  final String fullName;
  
  /// Size of avatar (diameter of circle)
  /// Default: 80 pixels
  final double size;
  
  /// Background color for initials fallback
  /// If null, uses theme primary color
  final Color? backgroundColor;
  
  /// Whether to show edit icon overlay
  /// Useful for edit screens
  final bool showEditIcon;
  
  /// Callback when avatar is tapped
  /// Useful for changing profile picture
  final VoidCallback? onTap;
  
  const ProfileAvatar({
    super.key,
    this.avatarUrl,
    required this.fullName,
    this.size = 80,
    this.backgroundColor,
    this.showEditIcon = false,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    // Wrap in GestureDetector if tappable
    Widget avatar = _buildAvatar(context);
    
    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }
    
    // Add edit icon overlay if requested
    if (showEditIcon) {
      return Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.camera_alt,
                size: size * 0.2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
    
    return avatar;
  }
  
  /// Builds the actual avatar widget
  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      // If avatarUrl exists, use NetworkImage
      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
          ? NetworkImage(avatarUrl!)
          : null,
      // If no image, show initials
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Text(
              _getInitials(fullName),
              style: TextStyle(
                fontSize: size / 2.5,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
  
  /// Extracts initials from full name
  /// 
  /// **Examples:**
  /// - "John Doe" → "JD"
  /// - "Alice" → "A"
  /// - "Bob Smith Johnson" → "BJ" (first + last)
  /// - "   Mary   " → "M" (handles extra spaces)
  /// 
  /// **Logic:**
  /// 1. Trim whitespace
  /// 2. Split by spaces
  /// 3. Take first letter of first word
  /// 4. Take first letter of last word (if exists)
  /// 5. Uppercase both
  String _getInitials(String name) {
    // Remove extra whitespace and split
    final parts = name.trim().split(RegExp(r'\s+'));
    
    if (parts.isEmpty) {
      return '?'; // Fallback for empty name
    }
    
    if (parts.length == 1) {
      // Single word name - just first letter
      return parts.first[0].toUpperCase();
    }
    
    // Multiple words - first letter of first and last word
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ============================================================================
// SUMMARY:
// ============================================================================
//
// FEATURES:
// - Network image with fallback to initials
// - Customizable size
// - Optional edit icon overlay
// - Optional tap callback
// - Smart initials generation
//
// BENEFITS:
// - Reusable across app
// - Consistent design
// - Handles edge cases (null, empty)
// - Professional appearance
//
// ============================================================================
