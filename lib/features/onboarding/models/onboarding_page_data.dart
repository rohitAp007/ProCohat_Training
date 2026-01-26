import 'package:flutter/material.dart';

/// Onboarding page data model
class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
