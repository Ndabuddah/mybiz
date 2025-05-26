import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../widgets/custom_button.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {'title': 'Welcome to MyBiz', 'description': 'Your all-in-one platform to manage, grow, and simplify your business operations.', 'image': Icons.business_center, 'color': AppColors.primaryColor},
    {'title': 'Professional Tools', 'description': 'Access financial, marketing, and legal tools designed to help your business succeed.', 'image': Icons.build, 'color': Colors.blue},
    {'title': 'AI-Powered Assistance', 'description': 'Get intelligent suggestions, automated content, and personalized business insights.', 'image': Icons.smart_toy, 'color': Colors.green},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_onboardingData[index]['title'], _onboardingData[index]['description'], _onboardingData[index]['image'], _onboardingData[index]['color'], isDarkMode);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SmoothPageIndicator(controller: _pageController, count: _onboardingData.length, effect: ExpandingDotsEffect(activeDotColor: AppColors.primaryColor, dotColor: isDarkMode ? Colors.white24 : Colors.black12, dotHeight: 8, dotWidth: 8, expansionFactor: 4)),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        CustomButton(
                          text: 'Previous',
                          icon: Icons.arrow_back,
                          onPressed: () {
                            _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          },
                          type: ButtonType.outline,
                        )
                      else
                        const SizedBox(width: 100),
                      CustomButton(
                        text: _currentPage == _onboardingData.length - 1 ? 'Get Started' : 'Next',
                        icon: _currentPage == _onboardingData.length - 1 ? Icons.done : Icons.arrow_forward,
                        onPressed: () {
                          if (_currentPage < _onboardingData.length - 1) {
                            _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          } else {
                            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                          }
                        },
                        type: ButtonType.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: Text('Skip', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(String title, String description, IconData icon, Color color, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 150, height: 150, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 80, color: color)),
          const SizedBox(height: 40),
          Text(title, style: AppStyles.h1(isDarkMode: isDarkMode), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(description, style: AppStyles.bodyLarge(isDarkMode: isDarkMode), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
