import 'package:flutter/material.dart';

/// Типографика приложения (без Google Fonts)
class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'Inter';

  static TextStyle get accentLarge => const TextStyle(
    fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -1.5, height: 1.1,
  );

  static TextStyle get accentMedium => const TextStyle(
    fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -1.0, height: 1.2,
  );

  static TextStyle get screenTitle => const TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.3,
  );

  static TextStyle get sectionTitle => const TextStyle(
    fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.4,
  );

  static TextStyle get subtitle => const TextStyle(
    fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15, height: 1.4,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.5,
  );

  static TextStyle get label => const TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.3,
  );

  static TextStyle get button => const TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5, height: 1.2,
  );

  static TextStyle get serverStatus => const TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, height: 1.2,
  );

  static TextStyle get cardTitle => const TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.3,
  );

  static TextStyle get ping => const TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.2, height: 1.2,
  );

  static TextStyle get mono => const TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.5,
    fontFamily: 'JetBrainsMono',
  );
}