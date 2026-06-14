import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary[500]!,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primary[800]!,
      onPrimaryContainer: AppColors.primary[200]!,
      secondary: AppColors.secondary[400]!,
      onSecondary: AppColors.darkBackground,
      secondaryContainer: AppColors.secondary[800]!,
      onSecondaryContainer: AppColors.secondary[200]!,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: const Color(0xFFE8E6F0),
      surfaceVariant: AppColors.darkSurfaceVariant,
      onSurfaceVariant: const Color(0xFF9D98B8),
    );
    return _buildTheme(colorScheme, Brightness.dark);
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary[600]!,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primary[100]!,
      onPrimaryContainer: AppColors.primary[900]!,
      secondary: AppColors.secondary[500]!,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondary[100]!,
      onSecondaryContainer: AppColors.secondary[900]!,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: const Color(0xFF1E1B2E),
      surfaceVariant: AppColors.lightSurfaceVariant,
      onSurfaceVariant: const Color(0xFF6B6588),
    );
    return _buildTheme(colorScheme, Brightness.light);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.screenTitle,
        titleMedium: AppTextStyles.cardTitle,
        bodyMedium: AppTextStyles.bodyMedium,
        labelSmall: AppTextStyles.serverStatus,
      ),
      appBarTheme: AppBarTheme(elevation: 0, backgroundColor: Colors.transparent, foregroundColor: colorScheme.onSurface),
      cardTheme: CardThemeData(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), color: isDark ? AppColors.darkCard : colorScheme.surfaceVariant),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), backgroundColor: AppColors.primary[600])),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: isDark ? AppColors.darkInput : colorScheme.surfaceVariant, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.primary[500]!, width: 2))),
      navigationBarTheme: NavigationBarThemeData(elevation: 0, height: 70, backgroundColor: isDark ? AppColors.darkNavBar : colorScheme.surface, indicatorColor: AppColors.primary[600]!.withOpacity(0.2)),
      dialogTheme: DialogThemeData(elevation: 24, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), backgroundColor: isDark ? AppColors.darkSurface : colorScheme.surface),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), backgroundColor: AppColors.darkSurfaceVariant),
    );
  }
}