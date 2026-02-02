/// ============================================================================
/// ONBOARDING SCREEN - WELCOME NEW USERS
/// ============================================================================
/// 
/// PURPOSE: Show app features to new users
/// PATTERN: PageView with indicator dots
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/onboarding_page_data.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/onboarding_indicator.dart';
import 'package:supabase_flutter_app/features/auth/unified_login/ui/unified_login_screen_clean.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding content
  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Connect with Friends',
      description: 'Chat with your friends and family anytime, anywhere',
      icon: Icons.chat_bubble_outline,
      color: const Color(0xFF25D366), // WhatsApp green
    ),
    OnboardingPageData(
      title: 'Secure Conversations',
      description: 'Your messages are encrypted and completely private',
      icon: Icons.lock_outline,
      color: const Color(0xFF128C7E), // Dark teal
    ),
    OnboardingPageData(
      title: 'Stay Connected',
      description: 'Real-time messaging keeps you connected 24/7',
      icon: Icons.groups_outlined,
      color: const Color(0xFF075E54), // Darker teal
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const UnifiedLoginScreen(),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Color(0xFF25D366),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(data: _pages[index]);
                },
              ),
            ),
            
            // Indicator dots
            OnboardingIndicator(
              currentPage: _currentPage,
              pageCount: _pages.length,
            ),
            
            const SizedBox(height: 32),
            
            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
