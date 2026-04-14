import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../services/translation_service.dart';
import '../../constants/app_strings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  static const _pages = [
    (AppStrings.onboarding1Title, AppStrings.onboarding1Body,
        Icons.document_scanner_outlined),
    (AppStrings.onboarding2Title, AppStrings.onboarding2Body,
        Icons.menu_book_outlined),
    (AppStrings.onboarding3Title, AppStrings.onboarding3Body,
        Icons.health_and_safety_outlined),
    (AppStrings.onboarding4Title, AppStrings.onboarding4Body,
        Icons.smart_toy_outlined),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: AppDimensions.animNormal),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = TranslationService.instance.tr;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(tr(AppStrings.skip)),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) {
                  final (titleKey, bodyKey, icon) = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.all(AppDimensions.sectionPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: AppDimensions.logoSizeLG,
                          height: AppDimensions.logoSizeLG,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.infoBlueTintDark
                                : AppColors.primaryBlueLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon,
                              size: AppDimensions.iconXXL,
                              color: AppColors.primaryBlue),
                        ),
                        const SizedBox(height: AppDimensions.spaceXL),
                        Text(
                          tr(titleKey),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.spaceMD),
                        Text(
                          tr(bodyKey),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(
                      milliseconds: AppDimensions.animFast),
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceXS),
                  width: _currentPage == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                    color: _currentPage == i
                        ? AppColors.primaryBlue
                        : (isDark
                            ? AppColors.dividerDark
                            : AppColors.dividerLight),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLG),
            // Action button
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sectionPadding),
              child: SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightLG,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(
                      isLast ? tr(AppStrings.getStarted) : tr(AppStrings.next)),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLG),
          ],
        ),
      ),
    );
  }
}
