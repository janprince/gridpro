import 'package:flutter/material.dart';

/// Brand and semantic colours for the GRID Pro "Premium Utility" system.
abstract final class AppColors {
  // Brand
  static const forest = Color(0xFF003D2D);
  static const forestDark = Color(0xFF00271D);
  static const teal = Color(0xFF0D9488);
  static const mint = Color(0xFFDDF4EB);

  // Neutrals
  static const warm = Color(0xFFF7F8F3);
  static const surface = Colors.white;
  static const surfaceSubtle = Color(0xFFF1F5F2);
  static const ink = Color(0xFF18201D);
  static const muted = Color(0xFF66736D);
  static const line = Color(0xFFDDE3DF);
  static const disabledFill = Color(0xFFEDF0EC);

  // Semantic status
  static const success = Color(0xFF15693F);
  static const successBg = mint;
  static const warning = Color(0xFFE39A22);
  static const warningText = Color(0xFF774A00);
  static const warningBg = Color(0xFFFFEBC7);
  static const danger = Color(0xFFB83A3A);
  static const dangerBg = Color(0xFFFFE0DE);
  static const info = Color(0xFF2878A9);
  static const infoBg = Color(0xFFE6EFF9);
  static const neutralBg = Color(0xFFE9EEEC);
}

/// Semantic status categories used for application, job and payout feedback.
/// Every status is always paired with an icon or text, never colour alone.
enum StatusKind { neutral, pending, success, actionRequired, danger }

extension StatusKindStyle on StatusKind {
  Color get background => switch (this) {
    StatusKind.neutral => AppColors.neutralBg,
    StatusKind.pending => AppColors.infoBg,
    StatusKind.success => AppColors.successBg,
    StatusKind.actionRequired => AppColors.warningBg,
    StatusKind.danger => AppColors.dangerBg,
  };

  Color get foreground => switch (this) {
    StatusKind.neutral => AppColors.ink,
    StatusKind.pending => AppColors.info,
    StatusKind.success => AppColors.success,
    StatusKind.actionRequired => AppColors.warningText,
    StatusKind.danger => AppColors.danger,
  };

  IconData get icon => switch (this) {
    StatusKind.neutral => Icons.info_outline,
    StatusKind.pending => Icons.hourglass_top,
    StatusKind.success => Icons.check_circle_outline,
    StatusKind.actionRequired => Icons.error_outline,
    StatusKind.danger => Icons.cancel_outlined,
  };
}

/// 8-point spacing scale.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 14.0;
  static const pill = 999.0;
}

/// Control sizing so fields, buttons and touch targets stay consistent.
abstract final class AppSizes {
  static const controlHeight = 52.0;
  static const touchTarget = 48.0;
  static const iconSm = 20.0;
  static const iconMd = 24.0;
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      primary: AppColors.forest,
      secondary: AppColors.teal,
      surface: AppColors.surface,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.warm,
      fontFamily: 'Public Sans',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.15,
          letterSpacing: -0.5,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w800,
          height: 1.2,
          letterSpacing: -0.3,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45),
        bodySmall: TextStyle(
          fontSize: 12.5,
          height: 1.4,
          color: AppColors.muted,
        ),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.warm,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Public Sans',
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.forest, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        helperStyle: const TextStyle(fontSize: 12.5, color: AppColors.muted),
        errorStyle: const TextStyle(fontSize: 12.5, color: AppColors.danger),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.controlHeight),
          disabledBackgroundColor: AppColors.disabledFill,
          disabledForegroundColor: AppColors.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'Public Sans',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.controlHeight),
          side: const BorderSide(color: AppColors.forest),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'Public Sans',
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSizes.touchTarget, AppSizes.touchTarget),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Public Sans',
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.mint,
        checkmarkColor: AppColors.forest,
        side: const BorderSide(color: AppColors.line),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.forest
              : AppColors.neutralBg,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.forest
              : Colors.transparent,
        ),
        side: const BorderSide(color: AppColors.muted, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.forest,
        linearTrackColor: AppColors.neutralBg,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontFamily: 'Public Sans',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line),
    );
  }
}
