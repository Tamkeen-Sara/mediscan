import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppTheme {
  AppTheme._();

  // ── Text themes ───────────────────────────────────────────────────────────────
  static TextTheme _textTheme(Color primary, Color secondary) {
    return GoogleFonts.robotoTextTheme(
      TextTheme(
        displayLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w700, color: primary),
        displayMedium: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w700, color: primary),
        displaySmall: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w600, color: primary),
        headlineLarge: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, color: primary),
        headlineMedium: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: primary),
        headlineSmall: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: primary),
        titleLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: primary),
        titleMedium: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500, color: primary),
        titleSmall: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: primary),
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w400, color: primary),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: primary),
        bodySmall: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: primary),
        labelMedium: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
        labelSmall: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500, color: secondary),
      ),
    );
  }

  // ── Light theme ───────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryBlue,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primaryBlueLight,
      onPrimaryContainer: AppColors.primaryBlue,
      secondary: AppColors.accentOrange,
      onSecondary: AppColors.textOnPrimary,
      secondaryContainer: AppColors.accentOrangeTint,
      onSecondaryContainer: AppColors.accentOrange,
      tertiary: AppColors.aiPurple,
      onTertiary: AppColors.textOnPrimary,
      tertiaryContainer: AppColors.aiPurpleTint,
      onTertiaryContainer: AppColors.aiPurple,
      error: AppColors.statusRed,
      onError: AppColors.white,
      errorContainer: AppColors.statusRedTint,
      onErrorContainer: AppColors.statusRed,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.backgroundLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.dividerLight,
      outlineVariant: AppColors.inputBorderLight,
      shadow: AppColors.shadowLight,
      inverseSurface: AppColors.textPrimaryLight,
      onInverseSurface: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: _textTheme(
          AppColors.textPrimaryLight, AppColors.textSecondaryLight),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: AppDimensions.appBarElevation,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: AppDimensions.cardElevation,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusLG),
        ),
        shadowColor: AppColors.shadowLight,
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize:
              const Size(double.infinity, AppDimensions.buttonHeightMD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          elevation: 0,
          textStyle: GoogleFonts.roboto(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          minimumSize:
              const Size(double.infinity, AppDimensions.buttonHeightMD),
          side: const BorderSide(
              color: AppColors.primaryBlue,
              width: AppDimensions.buttonBorderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          textStyle: GoogleFonts.roboto(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: GoogleFonts.roboto(
              fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          ),
        ),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFillLight,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMD,
            vertical: AppDimensions.spaceMD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: const BorderSide(color: AppColors.inputBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: const BorderSide(color: AppColors.inputBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: const BorderSide(
              color: AppColors.inputFocusedBorderLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: const BorderSide(color: AppColors.statusRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide:
              const BorderSide(color: AppColors.statusRed, width: 2),
        ),
        hintStyle: GoogleFonts.roboto(
            fontSize: 14,
            color: AppColors.textHintLight,
            fontWeight: FontWeight.w400),
        labelStyle: GoogleFonts.roboto(
            fontSize: 14,
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w400),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bottomNavLight,
        selectedItemColor: AppColors.bottomNavSelectedLight,
        unselectedItemColor: AppColors.bottomNavUnselectedLight,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundLight,
        selectedColor: AppColors.chipGreenTint,
        checkmarkColor: AppColors.chipGreen,
        labelStyle: GoogleFonts.roboto(
            fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          side: const BorderSide(color: AppColors.dividerLight),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.chipPaddingH,
            vertical: AppDimensions.chipPaddingV),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: AppDimensions.dividerThickness,
        space: 0,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryLight,
        size: AppDimensions.iconMD,
      ),

      // ProgressIndicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryBlue,
        linearTrackColor: AppColors.primaryBlueLight,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.snackBarRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        contentPadding:
            EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding),
        minLeadingWidth: 0,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBlue;
          }
          return AppColors.textHintLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBlueLight;
          }
          return AppColors.dividerLight;
        }),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 4,
      ),
    );
  }

  // ── Dark theme ────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryBlueDark,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.infoBlueTintDark,
      onPrimaryContainer: AppColors.primaryBlueDark,
      secondary: AppColors.accentOrange,
      onSecondary: AppColors.textOnPrimary,
      secondaryContainer: AppColors.accentOrangeTintDark,
      onSecondaryContainer: AppColors.accentOrange,
      tertiary: AppColors.aiPurple,
      onTertiary: AppColors.textOnPrimary,
      tertiaryContainer: AppColors.aiPurpleTintDark,
      onTertiaryContainer: AppColors.aiPurple,
      error: AppColors.statusRed,
      onError: AppColors.white,
      errorContainer: AppColors.statusRedTintDark,
      onErrorContainer: AppColors.statusRed,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.backgroundDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.dividerDark,
      outlineVariant: AppColors.inputBorderDark,
      shadow: AppColors.shadowDark,
      inverseSurface: AppColors.textPrimaryDark,
      onInverseSurface: AppColors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: _textTheme(
          AppColors.textPrimaryDark, AppColors.textSecondaryDark),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: AppDimensions.appBarElevation,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        shadowColor: AppColors.shadowDark,
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlueDark,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize:
              const Size(double.infinity, AppDimensions.buttonHeightMD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          elevation: 0,
          textStyle: GoogleFonts.roboto(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlueDark,
          minimumSize:
              const Size(double.infinity, AppDimensions.buttonHeightMD),
          side: const BorderSide(
              color: AppColors.primaryBlueDark,
              width: AppDimensions.buttonBorderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          textStyle: GoogleFonts.roboto(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlueDark,
          textStyle: GoogleFonts.roboto(
              fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          ),
        ),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFillDark,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMD,
            vertical: AppDimensions.spaceMD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: const BorderSide(color: AppColors.inputBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: const BorderSide(color: AppColors.inputBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: const BorderSide(
              color: AppColors.inputFocusedBorderDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: const BorderSide(color: AppColors.statusRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide:
              const BorderSide(color: AppColors.statusRed, width: 2),
        ),
        hintStyle: GoogleFonts.roboto(
            fontSize: 14,
            color: AppColors.textHintDark,
            fontWeight: FontWeight.w400),
        labelStyle: GoogleFonts.roboto(
            fontSize: 14,
            color: AppColors.textSecondaryDark,
            fontWeight: FontWeight.w400),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bottomNavDark,
        selectedItemColor: AppColors.bottomNavSelectedDark,
        unselectedItemColor: AppColors.bottomNavUnselectedDark,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.chipGreenTintDark,
        checkmarkColor: AppColors.chipGreen,
        labelStyle: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimaryDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          side: const BorderSide(color: AppColors.dividerDark),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.chipPaddingH,
            vertical: AppDimensions.chipPaddingV),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: AppDimensions.dividerThickness,
        space: 0,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryDark,
        size: AppDimensions.iconMD,
      ),

      // ProgressIndicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryBlueDark,
        linearTrackColor: AppColors.infoBlueTintDark,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevatedDark,
        contentTextStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimaryDark),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.snackBarRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        contentPadding:
            EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding),
        minLeadingWidth: 0,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBlueDark;
          }
          return AppColors.textHintDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.infoBlueTintDark;
          }
          return AppColors.dividerDark;
        }),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlueDark,
        foregroundColor: AppColors.white,
        elevation: 4,
      ),
    );
  }
}
