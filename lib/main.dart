import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/scan_provider.dart';
import 'providers/history_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/symptom_checker_provider.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/scanner/processing_screen.dart';
import 'screens/scanner/scan_failed_screen.dart';
import 'screens/results/scan_results_screen.dart';
import 'screens/results/confidence_screen.dart';
import 'screens/results/manual_edit_screen.dart';
import 'screens/ai_chat/ai_chat_screen.dart';
import 'screens/symptom_checker/symptom_checker_screen.dart';
import 'screens/profile/saved_medicines_screen.dart';
import 'screens/profile/about_screen.dart';
import 'screens/profile/feedback_screen.dart';
import 'screens/profile/privacy_screen.dart';
import 'screens/profile/ai_preferences_screen.dart';
import 'screens/profile/share_app_screen.dart';
import 'screens/auth/sign_in_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();

  final themeProvider = ThemeProvider();
  final languageProvider = LanguageProvider();
  await Future.wait([
    themeProvider.loadFromPrefs(),
    languageProvider.loadFromPrefs(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SymptomCheckerProvider()),
      ],
      child: const MediScanApp(),
    ),
  );
}

class MediScanApp extends StatelessWidget {
  const MediScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (_, theme, lang, __) {
        return MaterialApp(
          title: 'MediScan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: theme.themeMode,
          locale: lang.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ur'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => Directionality(
            textDirection:
                lang.isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
          initialRoute: '/',
          onGenerateRoute: _onGenerateRoute,
          routes: {
            '/': (_) => const SplashScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/home': (_) => const MainScreen(),
            '/signin': (_) => const SignInScreen(),
            '/scan-failed': (_) => const ScanFailedScreen(),
            '/confidence': (_) => const ConfidenceScreen(),
            '/manual-edit': (_) => const ManualEditScreen(),
            '/chat': (_) => const AiChatScreen(),
            '/symptom-checker': (_) => const SymptomCheckerScreen(),
            '/saved-medicines': (_) => const SavedMedicinesScreen(),
            '/about': (_) => const AboutScreen(),
            '/feedback': (_) => const FeedbackScreen(),
            '/privacy': (_) => const PrivacyScreen(),
            '/ai-prefs': (_) => const AiPreferencesScreen(),
            '/share': (_) => const ShareAppScreen(),
          },
        );
      },
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/processing':
        final path = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProcessingScreen(imagePath: path),
          settings: settings,
        );
      case '/results':
        final args = settings.arguments as Map<String, dynamic>?;
        final isInfoMode = args?['isInfoMode'] as bool? ?? false;
        return MaterialPageRoute(
          builder: (_) => ScanResultsScreen(isInfoMode: isInfoMode),
          settings: settings,
        );
    }
    return null;
  }
}
