import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Spacing System
// ---------------------------------------------------------------------------

abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

// ---------------------------------------------------------------------------
// Border Radius
// ---------------------------------------------------------------------------

abstract final class Radii {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 100;
}

// ---------------------------------------------------------------------------
// Color Palette
// ---------------------------------------------------------------------------

abstract final class AppColors {
  // Backgrounds
  static const background = Color(0xFF0D0F12);
  static const surface = Color(0xFF15181D);
  static const surfaceElevated = Color(0xFF1C2027);

  // Borders
  static const border = Color(0xFF2A3038);
  static const borderSubtle = Color(0xFF1F242C);

  // Brand
  static const accent = Color(0xFF7CC4FF);
  static const onAccent = Color(0xFF082033);

  // Text
  static const textPrimary = Color(0xFFF1F3F5);
  static const textSecondary = Color(0xFFA4ACB8);
  static const textMuted = Color(0xFF6B7280);

  // Semantic
  static const working = Color(0xFF7CC4FF);
  static const needsInput = Color(0xFFFFC56D);
  static const done = Color(0xFF83D6A3);
  static const danger = Color(0xFFFF8C87);

  // Blog reader (light surface for rendered markdown)
  static const readerBackground = Color(0xFFF7F5F0);
  static const readerText = Color(0xFF24272B);
  static const readerHeading = Color(0xFF111315);
}

// ---------------------------------------------------------------------------
// Shared Markdown Style
// ---------------------------------------------------------------------------

MarkdownStyleSheet buildReaderStyleSheet() {
  return MarkdownStyleSheet(
    p: const TextStyle(
        color: AppColors.readerText, fontSize: 16, height: 1.65),
    h1: const TextStyle(
        color: AppColors.readerHeading,
        fontSize: 30,
        height: 1.2,
        fontWeight: FontWeight.w800),
    h2: const TextStyle(
        color: AppColors.readerHeading,
        fontSize: 22,
        height: 1.3,
        fontWeight: FontWeight.w700),
    h3: const TextStyle(
        color: AppColors.readerHeading,
        fontSize: 18,
        fontWeight: FontWeight.w700),
    blockquote: const TextStyle(
        color: Color(0xFF555C66), fontStyle: FontStyle.italic),
    blockquoteDecoration: const BoxDecoration(
        border: Border(
            left: BorderSide(color: AppColors.accent, width: 3))),
    blockquotePadding: const EdgeInsets.only(left: Spacing.lg),
    listBullet: const TextStyle(color: AppColors.readerText, fontSize: 16),
  );
}

/// Container decoration used for the "reader pane" that shows rendered markdown.
BoxDecoration readerPaneDecoration() {
  return BoxDecoration(
    color: AppColors.readerBackground,
    borderRadius: BorderRadius.circular(Radii.md),
    border: Border.all(color: AppColors.border),
  );
}

// ---------------------------------------------------------------------------
// Theme Builder
// ---------------------------------------------------------------------------

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.needsInput,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
    ),
    textTheme: textTheme.copyWith(
      displaySmall: textTheme.displaySmall?.copyWith(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        height: 1.1,
      ),
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        color: AppColors.textSecondary,
        height: 1.6,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      labelMedium: textTheme.labelMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accent.withValues(alpha: .12),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
          size: 22,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.lg),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      errorStyle: const TextStyle(color: AppColors.danger),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        elevation: 0,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(0, 52),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md)),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceElevated,
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
