import 'package:flutter/material.dart';
import 'package:grid_professionals/core/models/service_kind.dart';

export 'package:grid_professionals/core/models/service_kind.dart';

/// Deep navy for action and identity, white working surfaces, and one tint
/// per service. Colour is used sparingly so the service tints carry meaning.
abstract final class AppColors {
  // Brand.
  static const navy = Color(0xFF13294B);
  static const navyDeep = Color(0xFF0B1C37);
  static const navyPressed = Color(0xFF0E2140);
  static const navySoft = Color(0xFFEBF0F7);

  /// Warm accent, only ever on navy surfaces ("Edit profile", highlights).
  static const amber = Color(0xFFF4C76A);

  // Kept as aliases so older call sites read naturally.
  static const primary = navy;
  static const accent = navy;
  static const primarySoft = navySoft;

  // Neutrals.
  static const canvas = Colors.white;
  static const surface = Colors.white;
  static const surfaceSubtle = Color(0xFFF6F7F9);
  static const chip = Color(0xFFF1F3F6);
  static const ink = Color(0xFF0B1526);
  static const muted = Color(0xFF5A6A82);
  static const faint = Color(0xFF8C99AD);
  static const line = Color(0xFFE6E9EF);
  static const lineStrong = Color(0xFFD5DBE4);
  static const disabledFill = Color(0xFFE9ECF1);

  // Semantic.
  static const success = Color(0xFF0B7A53);
  static const successBg = Color(0xFFE9F7F0);
  static const successLine = Color(0xFFA3DCC3);
  static const warning = Color(0xFFC77700);
  static const warningText = Color(0xFF9A5B00);
  static const warningBg = Color(0xFFFFF5E4);
  static const warningLine = Color(0xFFF2D19A);
  static const danger = Color(0xFFD3343B);
  static const dangerBg = Color(0xFFFDEEEE);
  static const dangerLine = Color(0xFFF1B3B6);
  static const info = navy;
  static const infoBg = navySoft;
  static const neutralBg = chip;
}

class ServicePalette {
  const ServicePalette({
    required this.tint,
    required this.arc,
    required this.ink,
    required this.badge,
  });

  /// Card background.
  final Color tint;

  /// Decorative arcs drawn on the tint.
  final Color arc;

  /// Text and icon colour on the tint.
  final Color ink;

  /// Solid badge fill behind the service icon.
  final Color badge;
}

extension ServiceKindStyle on ServiceKind {
  ServicePalette get palette => switch (this) {
    ServiceKind.cleaning => const ServicePalette(
      tint: Color(0xFFEAF6F0),
      arc: Color(0xFFD4EEE1),
      ink: Color(0xFF16603F),
      badge: Color(0xFF1F7A52),
    ),
    ServiceKind.laundry => const ServicePalette(
      tint: Color(0xFFEAF1FB),
      arc: Color(0xFFD5E3F7),
      ink: Color(0xFF1F4888),
      badge: Color(0xFF2F62B5),
    ),
    ServiceKind.acServicing => const ServicePalette(
      tint: Color(0xFFF0EEFB),
      arc: Color(0xFFDDD8F5),
      ink: Color(0xFF3E3187),
      badge: Color(0xFF5B4BB7),
    ),
    ServiceKind.pestControl => const ServicePalette(
      tint: Color(0xFFF4F6E6),
      arc: Color(0xFFE5EBC6),
      ink: Color(0xFF4F5A12),
      badge: Color(0xFF6B7A1A),
    ),
  };
}

/// Semantic status categories used for application, job and payout feedback.
/// Every status is always paired with an icon or text, never colour alone.
enum StatusKind { neutral, pending, success, actionRequired, danger }

extension StatusKindStyle on StatusKind {
  Color get background => switch (this) {
    StatusKind.neutral => AppColors.chip,
    StatusKind.pending => AppColors.navySoft,
    StatusKind.success => AppColors.successBg,
    StatusKind.actionRequired => AppColors.warningBg,
    StatusKind.danger => AppColors.dangerBg,
  };

  Color get foreground => switch (this) {
    StatusKind.neutral => AppColors.muted,
    StatusKind.pending => AppColors.navy,
    StatusKind.success => AppColors.success,
    StatusKind.actionRequired => AppColors.warningText,
    StatusKind.danger => AppColors.danger,
  };

  Color get border => switch (this) {
    StatusKind.neutral => AppColors.lineStrong,
    StatusKind.pending => const Color(0xFFB9C7DC),
    StatusKind.success => AppColors.successLine,
    StatusKind.actionRequired => AppColors.warningLine,
    StatusKind.danger => AppColors.dangerLine,
  };

  IconData get icon => switch (this) {
    StatusKind.neutral => Icons.info_outline_rounded,
    StatusKind.pending => Icons.schedule_rounded,
    StatusKind.success => Icons.check_circle_outline_rounded,
    StatusKind.actionRequired => Icons.error_outline_rounded,
    StatusKind.danger => Icons.cancel_outlined,
  };
}

/// 4-point spacing scale.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Horizontal page gutter. Every full-width screen uses this.
  static const gutter = 20.0;
}

abstract final class AppRadius {
  /// Buttons and inputs — soft, but still a rectangle.
  static const sm = 14.0;
  static const field = 14.0;

  /// Filled panels and grouped rows.
  static const md = 16.0;

  /// Raised cards.
  static const lg = 22.0;

  /// Hero cards, floating bars and sheets.
  static const xl = 28.0;
  static const pill = 999.0;
}

/// Elevation is a soft, wide shadow rather than an outline: a surface reads
/// as lifted off the page, not boxed in. Two levels only.
abstract final class AppShadow {
  /// Cards that sit in the page: job tiles, profile card, list cards.
  static const card = [
    BoxShadow(
      color: Color(0x140B1526),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -6,
    ),
    BoxShadow(color: Color(0x0F0B1526), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// Things that float over scrolling content: the action bar.
  static const float = [
    BoxShadow(
      color: Color(0x240B1526),
      blurRadius: 32,
      offset: Offset(0, 10),
      spreadRadius: -4,
    ),
    BoxShadow(color: Color(0x140B1526), blurRadius: 4, offset: Offset(0, 1)),
  ];
}

/// Control sizing so fields, buttons and touch targets stay consistent.
abstract final class AppSizes {
  static const controlHeight = 56.0;
  static const touchTarget = 48.0;

  /// Circular back / close chip in page headers.
  static const navChip = 42.0;
  static const iconSm = 20.0;
  static const iconMd = 24.0;
}

/// The type scale, set in Plus Jakarta Sans — a geometric sans with round,
/// open forms that stays legible at heavy weights. Inter covers any glyph it
/// lacks.
abstract final class AppText {
  static const family = 'PlusJakartaSans';
  static const fallback = ['Inter'];

  static const tabular = [FontFeature.tabularFigures()];

  static const display = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.9,
    color: AppColors.ink,
  );

  static const headline = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.16,
    letterSpacing: -0.7,
    color: AppColors.ink,
  );

  static const title = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.22,
    letterSpacing: -0.45,
    color: AppColors.ink,
  );

  /// Header bars and section headings.
  static const heading = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
    color: AppColors.ink,
  );

  static const subtitle = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.1,
    color: AppColors.ink,
  );

  static const body = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.ink,
    letterSpacing: 0.1,
  );

  static const bodyMuted = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.muted,
    letterSpacing: 0.1,
  );

  static const label = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.ink,
    letterSpacing: 0.1,
  );

  static const caption = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: AppColors.muted,
    letterSpacing: 0.1,
  );

  /// Small uppercase marker above a value, e.g. "HOME CLEANING".
  static const overline = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.9,
    color: AppColors.muted,
  );

  static const button = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
  );

  /// Hero amounts — balances, today's earnings, a job's price.
  static const amountXL = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.7,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  /// Amounts in rows and lists.
  static const amount = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: AppColors.ink,
    fontFeatures: tabular,
  );
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      onPrimary: Colors.white,
      secondary: AppColors.navy,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: AppText.family,
      fontFamilyFallback: AppText.fallback,
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme(
        displayLarge: AppText.display,
        displayMedium: AppText.headline,
        headlineLarge: AppText.headline,
        headlineMedium: AppText.title,
        titleLarge: AppText.heading,
        titleMedium: AppText.subtitle,
        titleSmall: AppText.label,
        bodyLarge: AppText.body,
        bodyMedium: TextStyle(fontSize: 14, height: 1.45),
        bodySmall: AppText.caption,
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.heading,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.faint, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: _border(AppColors.lineStrong),
        enabledBorder: _border(AppColors.lineStrong),
        focusedBorder: _border(AppColors.navy, 1.6),
        errorBorder: _border(AppColors.danger),
        focusedErrorBorder: _border(AppColors.danger, 1.6),
        disabledBorder: _border(AppColors.line),
        helperStyle: AppText.caption,
        errorStyle: const TextStyle(fontSize: 12.5, color: AppColors.danger),
      ),
      // Solid navy for the one action; a quiet grey fill for the alternative.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSizes.controlHeight),
          disabledBackgroundColor: AppColors.disabledFill,
          disabledForegroundColor: AppColors.faint,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: AppText.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(AppSizes.controlHeight),
          backgroundColor: AppColors.chip,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: AppText.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size(AppSizes.touchTarget, AppSizes.touchTarget),
          textStyle: const TextStyle(
            fontFamily: AppText.family,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.lineStrong,
        dragHandleSize: Size(44, 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.navy,
        checkmarkColor: Colors.white,
        side: const BorderSide(color: AppColors.lineStrong),
        labelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.success
              : AppColors.lineStrong,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.navy
              : Colors.transparent,
        ),
        side: const BorderSide(color: AppColors.faint, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.navy,
        inactiveTrackColor: AppColors.line,
        thumbColor: AppColors.navy,
        overlayColor: Color(0x1F13294B),
        trackHeight: 4,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.navy,
        linearTrackColor: AppColors.line,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontFamily: AppText.family,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: AppText.subtitle,
        subtitleTextStyle: AppText.caption,
        iconColor: AppColors.muted,
      ),
    );
  }

  static OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide(color: color, width: width),
      );
}
