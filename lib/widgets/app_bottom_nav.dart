import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/translation_service.dart';
import '../constants/app_strings.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = TranslationService.instance.tr;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor:
          isDark ? AppColors.bottomNavDark : AppColors.bottomNavLight,
      selectedItemColor: isDark
          ? AppColors.bottomNavSelectedDark
          : AppColors.bottomNavSelectedLight,
      unselectedItemColor: isDark
          ? AppColors.bottomNavUnselectedDark
          : AppColors.bottomNavUnselectedLight,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      iconSize: AppDimensions.iconMD,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.document_scanner_outlined),
          activeIcon: const Icon(Icons.document_scanner),
          label: tr(AppStrings.tabScanner),
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          activeIcon: Icon(Icons.description),
          label: 'Prescription',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.health_and_safety_outlined),
          activeIcon: const Icon(Icons.health_and_safety),
          label: tr(AppStrings.whatDoIHave),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history_outlined),
          activeIcon: const Icon(Icons.history),
          label: tr(AppStrings.tabHistory),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.smart_toy_outlined),
          activeIcon: const Icon(Icons.smart_toy),
          label: tr(AppStrings.tabChat),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: tr(AppStrings.tabProfile),
        ),
      ],
    );
  }
}
