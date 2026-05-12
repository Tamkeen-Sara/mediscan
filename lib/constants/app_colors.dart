import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary brand: Modern teal (health & vitality) ───────────────────────────
  static const Color primaryBlue = Color(0xFF00897B);      // Premium teal
  static const Color primaryBlueDark = Color(0xFF009688);  // Darker teal
  static const Color primaryBlueLight = Color(0xFFE0F2F1); // Light teal

  // ── Accent: Warm coral/rose ──────────────────────────────────────────────────
  static const Color accentOrange = Color(0xFFE8735F);     // Coral rose
  static const Color accentOrangeTint = Color(0xFFFEEAE2);
  static const Color accentOrangeTintDark = Color(0xFF3D1810);

  // ── Status: high confidence / success ────────────────────────────────────────
  static const Color statusGreen = Color(0xFF00796B);      // Deep teal-green
  static const Color statusGreenTint = Color(0xFFE0F2F1);
  static const Color statusGreenTintDark = Color(0xFF0A2D2A);

  // ── Status: low confidence / error ───────────────────────────────────────────
  static const Color statusRed = Color(0xFFD32F2F);        // Modern red
  static const Color statusRedTint = Color(0xFFFFEBEE);
  static const Color statusRedTintDark = Color(0xFF2D0A0A);

  // ── Status: medium / amber ────────────────────────────────────────────────────
  static const Color statusAmber = Color(0xFFF57C00);      // Warm amber
  static const Color statusAmberTint = Color(0xFFFFF3E0);
  static const Color statusAmberTintDark = Color(0xFF2D1600);

  // ── AI / Gemini: Rich purple ────────────────────────────────────────────────
  static const Color aiPurple = Color(0xFF7B1FA2);         // Deep purple
  static const Color aiPurpleTint = Color(0xFFF3E5F5);
  static const Color aiPurpleTintDark = Color(0xFF1C0533);

  // ── Info blue: Modern cyan ────────────────────────────────────────────────────
  static const Color infoBlueTint = Color(0xFFE0F7FA);
  static const Color infoBlueTintDark = Color(0xFF006A6A);

  // ── Emergency red: Deep crimson ───────────────────────────────────────────────
  static const Color emergencyRed = Color(0xFFC62828);
  static const Color emergencyRedTint = Color(0xFFFFCDD2);
  static const Color emergencyRedTintDark = Color(0xFF330505);

  // ── Symptom chips: Vibrant teal ────────────────────────────────────────────────
  static const Color chipGreen = Color(0xFF00796B);
  static const Color chipGreenTint = Color(0xFFB2DFDB);
  static const Color chipGreenTintDark = Color(0xFF0D2A26);

  // ── Background: Subtle light ───────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFFAFCFC);
  static const Color backgroundDark = Color(0xFF0F1419);

  // ── Surface (cards, sheets) ───────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1F2E);

  // ── Surface elevated ──────────────────────────────────────────────────────
  static const Color surfaceElevatedLight = Color(0xFFFAFCFC);
  static const Color surfaceElevatedDark = Color(0xFF252D3D);

  // ── Text: Modern typography ───────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF0F1419);
  static const Color textPrimaryDark = Color(0xFFE8EAED);
  static const Color textSecondaryLight = Color(0xFF546E7A);
  static const Color textSecondaryDark = Color(0xFFB0B8C1);
  static const Color textHintLight = Color(0xFF90A4AE);
  static const Color textHintDark = Color(0xFF607D8B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFE8EAED);

  // ── Divider: Subtle ───────────────────────────────────────────────────────
  static const Color dividerLight = Color(0xFFE0E8EA);
  static const Color dividerDark = Color(0xFF3C4652);

  // ── Scanner overlay ───────────────────────────────────────────────────────
  static const Color scanBracket = Color(0xFF00897B);
  static const Color scanMask = Color(0x90000000);
  static const Color scanLine = Color(0xFF00897B);

  // ── Bottom nav ────────────────────────────────────────────────────────────
  static const Color bottomNavLight = Color(0xFFFFFFFF);
  static const Color bottomNavDark = Color(0xFF1A1F2E);
  static const Color bottomNavSelectedLight = Color(0xFF00897B);
  static const Color bottomNavSelectedDark = Color(0xFF009688);
  static const Color bottomNavUnselectedLight = Color(0xFF90A4AE);
  static const Color bottomNavUnselectedDark = Color(0xFF607D8B);

  // ── Input / form ──────────────────────────────────────────────────────────
  static const Color inputBorderLight = Color(0xFFCFD8DC);
  static const Color inputBorderDark = Color(0xFF546E7A);
  static const Color inputFocusedBorderLight = Color(0xFF00897B);
  static const Color inputFocusedBorderDark = Color(0xFF009688);
  static const Color inputFillLight = Color(0xFFFAFCFC);
  static const Color inputFillDark = Color(0xFF252D3D);

  // ── Shadow: Elegant ───────────────────────────────────────────────────────
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowDark = Color(0x1A000000);

  // ── Skeleton / shimmer ────────────────────────────────────────────────────────
  static const Color shimmerBaseLight = Color(0xFFE0E0E0);
  static const Color shimmerHighlightLight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF2A2A2A);
  static const Color shimmerHighlightDark = Color(0xFF3A3A3A);

  // ── Transparent ───────────────────────────────────────────────────────────────
  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}
