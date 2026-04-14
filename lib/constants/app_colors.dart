import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary brand ────────────────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color primaryBlueDark = Color(0xFF1976D2);
  static const Color primaryBlueLight = Color(0xFFE3F2FD);

  // ── Accent / warning orange ──────────────────────────────────────────────────
  static const Color accentOrange = Color(0xFFF57C00);
  static const Color accentOrangeTint = Color(0xFFFFF3E0);
  static const Color accentOrangeTintDark = Color(0xFF3D1F00);

  // ── Status: high confidence / success ────────────────────────────────────────
  static const Color statusGreen = Color(0xFF2E7D32);
  static const Color statusGreenTint = Color(0xFFE8F5E9);
  static const Color statusGreenTintDark = Color(0xFF0A2D0C);

  // ── Status: low confidence / error ───────────────────────────────────────────
  static const Color statusRed = Color(0xFFC62828);
  static const Color statusRedTint = Color(0xFFFFEBEE);
  static const Color statusRedTintDark = Color(0xFF2D0A0A);

  // ── Status: medium / amber ────────────────────────────────────────────────────
  static const Color statusAmber = Color(0xFFF9A825);
  static const Color statusAmberTint = Color(0xFFFFF8E1);
  static const Color statusAmberTintDark = Color(0xFF2D2000);

  // ── AI / Gemini purple ────────────────────────────────────────────────────────
  static const Color aiPurple = Color(0xFF6A1B9A);
  static const Color aiPurpleTint = Color(0xFFF3E5F5);
  static const Color aiPurpleTintDark = Color(0xFF1C0533);

  // ── Info blue (plain-language summary card) ───────────────────────────────────
  static const Color infoBlueTint = Color(0xFFE3F2FD);
  static const Color infoBlueTintDark = Color(0xFF0D2744);

  // ── Emergency red ─────────────────────────────────────────────────────────────
  static const Color emergencyRed = Color(0xFFB71C1C);
  static const Color emergencyRedTint = Color(0xFFFFCDD2);
  static const Color emergencyRedTintDark = Color(0xFF330505);

  // ── Symptom chips green ───────────────────────────────────────────────────────
  static const Color chipGreen = Color(0xFF388E3C);
  static const Color chipGreenTint = Color(0xFFC8E6C9);
  static const Color chipGreenTintDark = Color(0xFF0D2610);

  // ── Background ────────────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF121212);

  // ── Surface (cards, sheets) ───────────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // ── Surface elevated ──────────────────────────────────────────────────────────
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedDark = Color(0xFF2A2A2A);

  // ── Text ──────────────────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textPrimaryDark = Color(0xFFE8EAED);
  static const Color textSecondaryLight = Color(0xFF5F6368);
  static const Color textSecondaryDark = Color(0xFF9AA0A6);
  static const Color textHintLight = Color(0xFF9E9E9E);
  static const Color textHintDark = Color(0xFF5F6368);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFE8EAED);

  // ── Divider ───────────────────────────────────────────────────────────────────
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF3C3C3C);

  // ── Scanner overlay ───────────────────────────────────────────────────────────
  static const Color scanBracket = Color(0xFFFFA726);
  static const Color scanMask = Color(0x80000000);
  static const Color scanLine = Color(0xFF1565C0);

  // ── Bottom nav ────────────────────────────────────────────────────────────────
  static const Color bottomNavLight = Color(0xFFFFFFFF);
  static const Color bottomNavDark = Color(0xFF1E1E1E);
  static const Color bottomNavSelectedLight = Color(0xFF1565C0);
  static const Color bottomNavSelectedDark = Color(0xFF1976D2);
  static const Color bottomNavUnselectedLight = Color(0xFF9E9E9E);
  static const Color bottomNavUnselectedDark = Color(0xFF5F6368);

  // ── Input / form ──────────────────────────────────────────────────────────────
  static const Color inputBorderLight = Color(0xFFBDBDBD);
  static const Color inputBorderDark = Color(0xFF5F6368);
  static const Color inputFocusedBorderLight = Color(0xFF1565C0);
  static const Color inputFocusedBorderDark = Color(0xFF1976D2);
  static const Color inputFillLight = Color(0xFFF5F5F5);
  static const Color inputFillDark = Color(0xFF2A2A2A);

  // ── Shadow ────────────────────────────────────────────────────────────────────
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);

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
