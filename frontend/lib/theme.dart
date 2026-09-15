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
  // Backgrounds - The Editorial Desk
  static const background = Color(0xFF131210);      // Lampblack (soot charcoal with warm amber undertone)
  static const surface = Color(0xFF1D1B17);         // Bookbinder Board
  static const surfaceElevated = Color(0xFF26231E); // Raised docket card
  static const surfaceHighlight = Color(0xFF302B24);// Hover / subtle active fill

  // Borders & Rules
  static const border = Color(0xFF2E2A24);          // Blind Deboss rule
  static const borderSubtle = Color(0xFF221F1A);    // Subtle hairline
  static const borderHover = Color(0xFF474035);     // Card hover border

  // Brand / Editorial Accent
  static const accent = Color(0xFFC4975A);          // Bookmark Gold / Vellum Ochre
  static const onAccent = Color(0xFF131210);        // Lampblack on gold
  static const accentSubtle = Color(0xFF292318);    // Warm gold wash / badge bg
  static const accentGlow = Color(0x33C4975A);      // Soft focus glow

  // Typography - Warm Editorial Text
  static const textPrimary = Color(0xFFEFECE6);     // Book Linen (unbleached paper white)
  static const textSecondary = Color(0xFF938C82);   // Graphite (pencil draft annotation)
  static const textMuted = Color(0xFF6B655D);       // Faded lead

  // Semantic
  static const working = Color(0xFFC4975A);
  static const needsInput = Color(0xFFE5A96A);
  static const done = Color(0xFF7CB88F);
  static const danger = Color(0xFFD4695D);

  // Blog reader (warm archival paper surface for rendered markdown)
  static const readerBackground = Color(0xFFFAF7F2);
  static const readerText = Color(0xFF22201D);
  static const readerHeading = Color(0xFF131210);
}

// ---------------------------------------------------------------------------
// Shared Markdown Style
// ---------------------------------------------------------------------------

MarkdownStyleSheet buildReaderStyleSheet() {
  return MarkdownStyleSheet(
    p: GoogleFonts.plusJakartaSans(
      color: AppColors.readerText,
      fontSize: 16,
      height: 1.7,
    ),
    h1: GoogleFonts.fraunces(
      color: AppColors.readerHeading,
      fontSize: 30,
      height: 1.25,
      fontWeight: FontWeight.w700,
    ),
    h2: GoogleFonts.fraunces(
      color: AppColors.readerHeading,
      fontSize: 22,
      height: 1.3,
      fontWeight: FontWeight.w600,
    ),
    h3: GoogleFonts.fraunces(
      color: AppColors.readerHeading,
      fontSize: 18,
      height: 1.35,
      fontWeight: FontWeight.w600,
    ),
    blockquote: GoogleFonts.fraunces(
      color: const Color(0xFF5A534B),
      fontSize: 16,
      fontStyle: FontStyle.italic,
      height: 1.6,
    ),
    blockquoteDecoration: const BoxDecoration(
      border: Border(
        left: BorderSide(color: AppColors.accent, width: 3),
      ),
    ),
    blockquotePadding: const EdgeInsets.only(left: Spacing.lg),
    listBullet: GoogleFonts.plusJakartaSans(
      color: AppColors.readerText,
      fontSize: 16,
    ),
    code: GoogleFonts.jetBrainsMono(
      fontSize: 13,
      backgroundColor: const Color(0xFFEDE9E0),
      color: const Color(0xFF22201D),
    ),
  );
}

/// Container decoration used for the "reader pane" that shows rendered markdown.
BoxDecoration readerPaneDecoration() {
  return BoxDecoration(
    color: AppColors.readerBackground,
    borderRadius: BorderRadius.circular(Radii.md),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Theme Builder
// ---------------------------------------------------------------------------

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
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
      displaySmall: GoogleFonts.fraunces(
        fontSize: 38,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        height: 1.15,
        color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.fraunces(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.25,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        color: AppColors.textSecondary,
        height: 1.6,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      labelMedium: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
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
      indicatorColor: AppColors.accent.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
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
