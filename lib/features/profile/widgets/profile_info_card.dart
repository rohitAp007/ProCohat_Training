/// ============================================================================
/// PROFILE INFO CARD - REUSABLE INFO DISPLAY CARD
/// ============================================================================
/// 
/// PURPOSE: Display profile information in consistent card format
/// 
/// LEARNING: Composition - building complex UI from simple widgets
/// 
/// ============================================================================

import 'package:flutter/material.dart';

/// ProfileInfoCard Widget
/// 
/// **Purpose:**
/// - Display label-value pairs in card format
/// - Consistent styling across profile
/// - Optional icon for visual clarity
/// - Material Design 3 card styling
/// 
/// **Example Usage:**
/// ```dart
/// ProfileInfoCard(
///   title: 'Phone',
///   value: '+1 234 567 8900',
///   icon: Icons.phone,
/// )
/// 
/// ProfileInfoCard(
///   title: 'Birthday',
///   value: 'January 15, 1990',
///   icon: Icons.cake,
/// )
/// ```
class ProfileInfoCard extends StatelessWidget {
  /// Title/label for the information
  /// Example: "Phone", "Email", "Birthday"
  final String title;
  
  /// The actual value to display
  /// Example: "+1234567890", "john@example.com"
  final String value;
  
  /// Optional icon to show
  /// Provides visual context
  final IconData? icon;
  
  /// Optional tap callback
  /// Useful for actions like call, email
  final VoidCallback? onTap;
  
  const ProfileInfoCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon (if provided)
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              
              // Title and Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (label)
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    // Value (data)
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              
              // Arrow icon if tappable
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).hintColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ProfileSection Widget - Groups related info cards
/// 
/// **Purpose:**
/// - Group related information together
/// - Add section headers
/// - Consistent spacing
/// 
/// **Example:**
/// ```dart
/// ProfileSection(
///   title: 'Contact Information',
///   children: [
///     ProfileInfoCard(
///       title: 'Phone',
///       value: phone,
///       icon: Icons.phone,
///     ),
///     ProfileInfoCard(
///       title: 'Email',
///       value: email,
///       icon: Icons.email,
///     ),
///   ],
/// )
/// ```
class ProfileSection extends StatelessWidget {
  /// Section title/header
  final String title;
  
  /// List of widgets to display in section
  /// Usually ProfileInfoCard widgets
  final List<Widget> children;
  
  const ProfileSection({
    super.key,
    required this.title,
    required this.children,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        
        // Section Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SUMMARY:
// ============================================================================
//
// PROFILEINFOCARD:
// - Card-based info display
// - Icon + Title + Value layout
// - Optional tap action
// - Material Design 3 styling
//
// PROFILESECTION:
// - Groups related cards
// - Section headers
// - Consistent spacing
//
// BENEFITS:
// - Reusable components
// - Consistent design
// - Easy to modify
// - Professional appearance
//
// ============================================================================
