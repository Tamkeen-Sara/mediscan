import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/local_cache_service.dart';
import '../../services/translation_service.dart';
import '../../widgets/animated_cards.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(tr(AppStrings.profileTitle))),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        children: [
          // User card — reactive to auth state changes
          FadeInCard(
            delay: const Duration(milliseconds: 80),
            child: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                final isGuest = user == null || user.isAnonymous;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: AppDimensions.avatarSM,
                          backgroundColor: isGuest
                              ? (isDark ? AppColors.infoBlueTintDark : AppColors.primaryBlueLight)
                              : (isDark ? AppColors.infoBlueTintDark : AppColors.primaryBlueLight),
                          child: Icon(
                            isGuest ? Icons.person_outline : Icons.person,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user?.displayName ??
                                          user?.email ??
                                          tr(AppStrings.guestUser),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isGuest)
                                    Padding(
                                      padding: const EdgeInsets.only(left: AppDimensions.spaceXS),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppDimensions.spaceXS,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.infoBlueTintDark : AppColors.primaryBlueLight,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Guest',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (user?.email != null)
                                Text(user!.email!,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    SizedBox(
                      width: double.infinity,
                      child: isGuest
                          ? ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/signin'),
                              child: Text(tr(AppStrings.signIn)),
                            )
                          : ElevatedButton(
                              onPressed: () => _signOut(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.statusRed.withValues(alpha: 0.1),
                              ),
                              child: Text(
                                tr(AppStrings.signOut),
                                style: const TextStyle(color: AppColors.statusRed),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLG),

          // Appearance
          _SectionHeader(tr(AppStrings.appearanceSection)),
          FadeInCard(
            delay: const Duration(milliseconds: 140),
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              icon: Icons.palette_outlined,
              title: tr(AppStrings.themeTitle),
              subtitle: _themeLabel(context.watch<ThemeProvider>().themeMode, tr),
              onTap: () => _showThemeSheet(context),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          FadeInCard(
            delay: const Duration(milliseconds: 190),
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              icon: Icons.language,
              title: tr(AppStrings.languageTitle),
              subtitle: context.watch<LanguageProvider>().isRTL
                  ? tr(AppStrings.languageUrdu)
                  : tr(AppStrings.languageEnglish),
              onTap: () => _showLanguageSheet(context),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLG),

          // Data & Privacy
          _SectionHeader(tr(AppStrings.dataSection)),
          FadeInCard(
            delay: const Duration(milliseconds: 240),
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              icon: Icons.bookmark_outline,
              title: tr(AppStrings.savedTitle),
              onTap: () => Navigator.pushNamed(context, '/saved-medicines'),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          FadeInCard(
            delay: const Duration(milliseconds: 290),
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              icon: Icons.smart_toy_outlined,
              title: tr(AppStrings.aiPrefsTitle),
              onTap: () => Navigator.pushNamed(context, '/ai-prefs'),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          FadeInCard(
            delay: const Duration(milliseconds: 340),
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              icon: Icons.lock_outline,
              title: tr(AppStrings.privacyTitle),
              onTap: () => Navigator.pushNamed(context, '/privacy'),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          FadeInCard(
            delay: const Duration(milliseconds: 365),
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              icon: Icons.delete_outline,
              title: tr(AppStrings.clearLocalCache),
              subtitle: tr(AppStrings.clearLocalCacheDesc),
              onTap: () => _clearLocalCache(context),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLG),

          // Support
          _SectionHeader(tr(AppStrings.supportSection)),
          FadeInCard(
            delay: const Duration(milliseconds: 390),
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              icon: Icons.info_outline,
              title: tr(AppStrings.aboutTitle),
              onTap: () => Navigator.pushNamed(context, '/about'),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          FadeInCard(
            delay: const Duration(milliseconds: 440),
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              icon: Icons.feedback_outlined,
              title: tr(AppStrings.feedbackTitle),
              onTap: () => Navigator.pushNamed(context, '/feedback'),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          FadeInCard(
            delay: const Duration(milliseconds: 490),
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              icon: Icons.share_outlined,
              title: tr(AppStrings.shareAppTitle),
              onTap: () => Navigator.pushNamed(context, '/share'),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeSheet(BuildContext ctx) {
    final tr = TranslationService.instance.tr;
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: Text(tr(AppStrings.themeLight)),
              onTap: () {
                ctx.read<ThemeProvider>().setTheme(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text(tr(AppStrings.themeDark)),
              onTap: () {
                ctx.read<ThemeProvider>().setTheme(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_brightness),
              title: Text(tr(AppStrings.themeSystem)),
              onTap: () {
                ctx.read<ThemeProvider>().setTheme(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                ctx.read<LanguageProvider>().setLanguage('en');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('اردو'),
              onTap: () {
                ctx.read<LanguageProvider>().setLanguage('ur');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) {
        final t = TranslationService.instance.tr;
        return AlertDialog(
          title: Text(t(AppStrings.signOut)),
          content: Text(t(AppStrings.signOutConfirm)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: Text(t(AppStrings.cancel))),
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: Text(t(AppStrings.signOut),
                    style: const TextStyle(color: AppColors.statusRed))),
          ],
        );
      },
    );
    if (confirm == true) {
      // Sign out from Google if that was the sign-in method
      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (_) {}
      await FirebaseAuth.instance.signOut();
      // Re-create anonymous session so scan history and saves keep working
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (_) {}
    }
  }

  Future<void> _clearLocalCache(BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) {
        final t = TranslationService.instance.tr;
        return AlertDialog(
          title: Text(t(AppStrings.clearLocalCache)),
          content: Text(t(AppStrings.clearLocalCacheConfirm)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: Text(t(AppStrings.cancel))),
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: Text(t(AppStrings.clear),
                    style: const TextStyle(color: AppColors.statusRed))),
          ],
        );
      },
    );
    if (confirm != true) return;

    final messenger = ScaffoldMessenger.of(ctx);
    try {
      await LocalCacheService.instance.clearLocalCache();
      await LocalCacheService.instance.seedIfEmpty();
      messenger.showSnackBar(
        SnackBar(content: Text(TranslationService.instance.tr(AppStrings.clearLocalCacheDone))),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(TranslationService.instance.tr(AppStrings.unknownError))),
      );
    }
  }

  String _themeLabel(ThemeMode mode, String Function(String) tr) {
    switch (mode) {
      case ThemeMode.light:
        return tr(AppStrings.themeLight);
      case ThemeMode.dark:
        return tr(AppStrings.themeDark);
      default:
        return tr(AppStrings.themeSystem);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          bottom: AppDimensions.spaceSM,
          left: AppDimensions.spaceXS),
      child: Text(title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSM)),
    );
  }
}
