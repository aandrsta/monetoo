// lib/utils/app_colors.dart
//
// Cara pakai:
//   context.colors.surface
//   context.colors.textPrimary
//   context.colors.cardBg
//   dst.

import 'package:flutter/material.dart';

import 'app_theme.dart';

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).brightness == Brightness.dark
      ? const _DarkColors()
      : const _LightColors();
}

abstract class AppColors {
  const AppColors();

  Color get surface;
  Color get cardBg;
  Color get textPrimary;
  Color get textSecondary;
  Color get divider;
  Color get bgLight;
  Color get accent;
  Color get income;
  Color get incomeLight;
  Color get expense;
  Color get expenseLight;
  Color get navBarBg;
  Color get inputFill;
  Color get modalBg;

  // Shadows — berubah opacity di dark mode
  List<BoxShadow> get cardShadow;

  static Object? get instance => null;
}

// ─── LIGHT ───────────────────────────────────────────────────
class _LightColors extends AppColors {
  const _LightColors();

  @override
  Color get surface => AppTheme.surface;
  @override
  Color get cardBg => AppTheme.cardBg;
  @override
  Color get textPrimary => AppTheme.textPrimary;
  @override
  Color get textSecondary => AppTheme.textSecondary;
  @override
  Color get divider => AppTheme.divider;
  @override
  Color get bgLight => AppTheme.bgLight;
  @override
  Color get accent => AppTheme.accent;
  @override
  Color get income => AppTheme.income;
  @override
  Color get incomeLight => AppTheme.incomeLight;
  @override
  Color get expense => AppTheme.expense;
  @override
  Color get expenseLight => AppTheme.expenseLight;
  @override
  Color get navBarBg => AppTheme.cardBg;
  @override
  Color get inputFill => AppTheme.bgLight;
  @override
  Color get modalBg => AppTheme.cardBg;

  @override
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];
}

// ─── DARK ────────────────────────────────────────────────────
class _DarkColors extends AppColors {
  const _DarkColors();

  @override
  Color get surface => AppTheme.darkSurface;
  @override
  Color get cardBg => AppTheme.darkCardBg;
  @override
  Color get textPrimary => AppTheme.darkTextPrimary;
  @override
  Color get textSecondary => AppTheme.darkTextSecondary;
  @override
  Color get divider => AppTheme.darkDivider;
  @override
  Color get bgLight => AppTheme.darkBgLight;
  @override
  Color get accent => AppTheme.darkAccent;
  @override
  Color get income => AppTheme.darkIncome;
  @override
  Color get incomeLight => AppTheme.darkIncomeLightBg;
  @override
  Color get expense => AppTheme.darkExpense;
  @override
  Color get expenseLight => AppTheme.darkExpenseLightBg;
  @override
  Color get navBarBg => AppTheme.darkCardBg;
  @override
  Color get inputFill => AppTheme.darkBgLight;
  @override
  Color get modalBg => AppTheme.darkCardBg;

  @override
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
