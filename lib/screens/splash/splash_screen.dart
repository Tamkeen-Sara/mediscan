import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../services/local_cache_service.dart';
import '../../providers/language_provider.dart';
import '../../services/translation_service.dart';
import '../../constants/app_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: AppDimensions.animSlow));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Seed SQLite from bundled medicines.json
    await LocalCacheService.instance.seedIfEmpty();

    // Ensure there is always a Firebase user (anonymous if not signed in).
    // This guarantees scan saving, history, and saved medicines all work
    // even before the user explicitly creates an account.
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (_) {
        // If anonymous sign-in fails (e.g. not enabled), continue anyway.
      }
    }

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final showOnboarding = prefs.getBool('showOnboarding') ?? true;

    if (!mounted) return;

    if (showOnboarding) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.primaryBlue,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: AppDimensions.logoSizeLG,
                height: AppDimensions.logoSizeLG,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusXXL),
                ),
                child: const Icon(
                  Icons.document_scanner,
                  size: AppDimensions.iconXXL,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLG),
              Consumer<LanguageProvider>(
                builder: (_, lang, __) => Column(
                  children: [
                    Text(
                      TranslationService.instance.tr(AppStrings.appName),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.spaceSM),
                    Text(
                      TranslationService.instance.tr(AppStrings.tagline),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.white.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceHuge),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              Text(
                TranslationService.instance.tr(AppStrings.splashLoading),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
