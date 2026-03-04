import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }





  // Called when user claims they are done or we auto-detect
  Future<void> _completeOnboarding() async {
    await ref.read(databaseServiceProvider).completeOnboarding();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // We can use a LifecycleObserver to auto-check permission on resume if we want to be fancy
    // For now, simple manual check button on last slide is fine.

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildSlide(
                    icon: Icons.account_balance_wallet, 
                    title: "Welcome to Spent",
                    body: "Your private expense tracker. Easily record transactions and see where your money goes.",
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),
            
            // Indicator and Navigation
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators (Hidden if only 1 page, or just show 1)
                  // Actually if there is only 1 page, we don't really need indicators or next button logic as much, but let's keep it simple.
                  Row(
                    children: List.generate(1, (index) => _buildIndicator(index == _currentPage)),
                  ),
                  
                  // Next/Finish Button
                  // Since we only have 1 page (index 0), _currentPage < 0 is false.
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      "Get Started",
                      style: GoogleFonts.nunito(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.black87 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildSlide({required IconData icon, required String title, required String body, required Color color}) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: color),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }


}
