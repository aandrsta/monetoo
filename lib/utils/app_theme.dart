// lib/utils/app_theme.dart

import 'dart:io';
import 'package:flutter/material.dart';

class AppTheme {
  // ═════════════════════════════════════════════════════════════════════
  // LIGHT MODE COLORS
  // ═════════════════════════════════════════════════════════════════════
  static const Color primary = Color(0xFF1A1F36);
  static const Color primaryLight = Color(0xFF2D3561);
  static const Color accent = Color(0xFF7C6FFF);
  static const Color accentGlow = Color(0xFF9D93FF);
  static const Color income = Color(0xFF00D4AA);
  static const Color incomeLight = Color(0xFFE6FBF7);
  static const Color expense = Color(0xFFFF5C7A);
  static const Color expenseLight = Color(0xFFFFEEF1);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF8B8FA8);
  static const Color divider = Color(0xFFEEEFF5);
  static const Color bgLight = Color(0xFFF4F6FF);

  // ═════════════════════════════════════════════════════════════════════
  // DARK MODE COLORS
  // ═════════════════════════════════════════════════════════════════════
  static const Color darkPrimary = Color(0xFF0F1419);
  static const Color darkPrimaryLight = Color(0xFF1A1F2E);
  static const Color darkAccent = Color(0xFF9D93FF);
  static const Color darkAccentGlow = Color(0xFFB5ACFF);
  static const Color darkIncome = Color(0xFF00D4AA);
  static const Color darkIncomeLightBg = Color(0xFF0D3B37);
  static const Color darkExpense = Color(0xFFFF6B82);
  static const Color darkExpenseLightBg = Color(0xFF4A1921);
  static const Color darkSurface = Color(0xFF121518);
  static const Color darkCardBg = Color(0xFF1E2329);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFA8A8A8);
  static const Color darkDivider = Color(0xFF2A2F38);
  static const Color darkBgLight = Color(0xFF252C35);

  static String get _systemFontFamily {
    if (Platform.isIOS || Platform.isMacOS) return '.SF UI Text';
    return 'sans-serif';
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false,
      fontFamily: 'SFProText',
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: income,
        surface: surface,
        error: expense,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: _systemFontFamily,
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.06),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(
          fontFamily: _systemFontFamily,
          color: textSecondary,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          fontFamily: _systemFontFamily,
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: _systemFontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: false,
      fontFamily: 'SFProText',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: darkAccent,
        secondary: darkIncome,
        surface: darkSurface,
        error: darkExpense,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: _systemFontFamily,
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: darkCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkCardBg,
        selectedItemColor: darkAccent,
        unselectedItemColor: darkTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(
          fontFamily: _systemFontFamily,
          color: darkTextSecondary,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          fontFamily: _systemFontFamily,
          color: darkTextSecondary,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: _systemFontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get accentShadow => [
        BoxShadow(
          color: accent.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // Gradients
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primary, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get accentGradient => const LinearGradient(
        colors: [accent, Color(0xFF9D85FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get incomeGradient => const LinearGradient(
        colors: [Color(0xFF00D4AA), Color(0xFF00B899)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get expenseGradient => const LinearGradient(
        colors: [Color(0xFFFF5C7A), Color(0xFFFF3B5C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
