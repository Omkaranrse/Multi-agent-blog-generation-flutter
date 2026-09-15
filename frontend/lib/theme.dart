import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Spacing & Layout System
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

abstract final class Radii {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 100;
}

// ---------------------------------------------------------------------------
// Theme Controller (Persistence & Mode Switching)
// ---------------------------------------------------------------------------

class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._();
  ThemeController._();

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  static const _prefKey = 'app_theme_mode';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved == 'light') {
      _themeMode = ThemeMode.light;
    } else if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      await prefs.setString(_prefKey, 'light');
    } else if (mode == ThemeMode.dark) {
      await prefs.setString(_prefKey, 'dark');
    } else {
      await prefs.remove(_prefKey);
    }
  }

  void toggle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}

// ---------------------------------------------------------------------------
// Token-Based Color Scheme & Theme Extension
// ---------------------------------------------------------------------------

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.bgPrimary,
    required this.bgSurface,
    required this.bgInput,
    required this.textPrimary,
    required this.textMuted,
    required this.border,
    required this.borderSubtle,
    required this.accent,
    required this.onAccent,
    required this.accentSubtle,
    required this.success,
    required this.warning,
    required this.danger,
    required this.readerBg,
    required this.readerText,
    required this.readerHeading,
  });

  final Color bgPrimary;
  final Color bgSurface;
  final Color bgInput;
  final Color textPrimary;
  final Color textMuted;
  final Color border;
  final Color borderSubtle;
  final Color accent;
  final Color onAccent;
  final Color accentSubtle;
  final Color success;
  final Color warning;
  final Color danger;

  final Color readerBg;
  final Color readerText;
  final Color readerHeading;

  static const light = AppThemeTokens(
    bgPrimary: Color(0xFFFBFBFA),
    bgSurface: Color(0xFFFFFFFF),
    bgInput: Color(0xFFF4F4F5),
    textPrimary: Color(0xFF18181B),
    textMuted: Color(0xFF71717A),
    border: Color(0xFFE4E4E7),
    borderSubtle: Color(0xFFF0F0F2),
    accent: Color(0xFF1A6558), // Spruce Teal (7.08:1 contrast on white)
    onAccent: Color(0xFFFFFFFF),
    accentSubtle: Color(0xFFE8F2F0),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
    readerBg: Color(0xFFFFFFFF),
    readerText: Color(0xFF18181B),
    readerHeading: Color(0xFF09090B),
  );

  static const dark = AppThemeTokens(
    bgPrimary: Color(0xFF121316),
    bgSurface: Color(0xFF1A1C22),
    bgInput: Color(0xFF22252D),
    textPrimary: Color(0xFFF4F4F6),
    textMuted: Color(0xFF9CA3AF),
    border: Color(0xFF2D313B),
    borderSubtle: Color(0xFF21242C),
    accent: Color(0xFF3EB59E), // Mint Sage (7.34:1 contrast on dark button text)
    onAccent: Color(0xFF0D1513),
    accentSubtle: Color(0xFF162B26),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    readerBg: Color(0xFF1A1C22),
    readerText: Color(0xFFF4F4F6),
    readerHeading: Color(0xFFFFFFFF),
  );

  static AppThemeTokens of(BuildContext context) {
    return Theme.of(context).extension<AppThemeTokens>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  AppThemeTokens copyWith({
    Color? bgPrimary,
    Color? bgSurface,
    Color? bgInput,
    Color? textPrimary,
    Color? textMuted,
    Color? border,
    Color? borderSubtle,
    Color? accent,
    Color? onAccent,
    Color? accentSubtle,
    Color? success,
    Color? warning,
    Color? danger,
    Color? readerBg,
    Color? readerText,
    Color? readerHeading,
  }) {
    return AppThemeTokens(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSurface: bgSurface ?? this.bgSurface,
      bgInput: bgInput ?? this.bgInput,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSubtle: accentSubtle ?? this.accentSubtle,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      readerBg: readerBg ?? this.readerBg,
      readerText: readerText ?? this.readerText,
      readerHeading: readerHeading ?? this.readerHeading,
    );
  }

  @override
  ThemeExtension<AppThemeTokens> lerp(
    covariant ThemeExtension<AppThemeTokens>? other,
    double t,
  ) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgInput: Color.lerp(bgInput, other.bgInput, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentSubtle: Color.lerp(accentSubtle, other.accentSubtle, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      readerBg: Color.lerp(readerBg, other.readerBg, t)!,
      readerText: Color.lerp(readerText, other.readerText, t)!,
      readerHeading: Color.lerp(readerHeading, other.readerHeading, t)!,
    );
  }
}

// ---------------------------------------------------------------------------
// Backward Compatibility Bridge
// ---------------------------------------------------------------------------

abstract final class AppColors {
  static const danger = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
  static const working = Color(0xFF1A6558);
  static const needsInput = Color(0xFFD97706);
}

// ---------------------------------------------------------------------------
// Shared Markdown Style
// ---------------------------------------------------------------------------

MarkdownStyleSheet buildReaderStyleSheet(BuildContext context) {
  final tokens = AppThemeTokens.of(context);
  return MarkdownStyleSheet(
    p: GoogleFonts.plusJakartaSans(
      color: tokens.readerText,
      fontSize: 16,
      height: 1.7,
    ),
    h1: GoogleFonts.plusJakartaSans(
      color: tokens.readerHeading,
      fontSize: 26,
      height: 1.3,
      fontWeight: FontWeight.w700,
    ),
    h2: GoogleFonts.plusJakartaSans(
      color: tokens.readerHeading,
      fontSize: 20,
      height: 1.35,
      fontWeight: FontWeight.w600,
    ),
    h3: GoogleFonts.plusJakartaSans(
      color: tokens.readerHeading,
      fontSize: 17,
      height: 1.4,
      fontWeight: FontWeight.w600,
    ),
    blockquote: GoogleFonts.plusJakartaSans(
      color: tokens.textMuted,
      fontSize: 15,
      fontStyle: FontStyle.italic,
      height: 1.6,
    ),
    blockquoteDecoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: tokens.accent, width: 3),
      ),
    ),
    blockquotePadding: const EdgeInsets.only(left: Spacing.lg),
    listBullet: GoogleFonts.plusJakartaSans(
      color: tokens.readerText,
      fontSize: 16,
    ),
    code: GoogleFonts.jetBrainsMono(
      fontSize: 13,
      backgroundColor: tokens.bgInput,
      color: tokens.textPrimary,
    ),
    tableHead: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: tokens.textPrimary,
    ),
    tableBody: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      color: tokens.textPrimary,
      height: 1.5,
    ),
    tableHeadAlign: TextAlign.left,
    tableCellsPadding: const EdgeInsets.symmetric(
      horizontal: Spacing.md + 2,
      vertical: Spacing.sm + 2,
    ),
    tableBorder: TableBorder.all(
      color: tokens.border,
      width: 1,
      borderRadius: BorderRadius.circular(Radii.sm),
    ),
  );
}

BoxDecoration readerPaneDecoration(BuildContext context) {
  final tokens = AppThemeTokens.of(context);
  return BoxDecoration(
    color: tokens.readerBg,
    borderRadius: BorderRadius.circular(Radii.md),
    border: Border.all(color: tokens.border),
  );
}

// ---------------------------------------------------------------------------
// Theme Builder
// ---------------------------------------------------------------------------

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final tokens = isDark ? AppThemeTokens.dark : AppThemeTokens.light;
  final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

  final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
    bodyColor: tokens.textPrimary,
    displayColor: tokens.textPrimary,
  );

  return base.copyWith(
    scaffoldBackgroundColor: tokens.bgPrimary,
    extensions: [tokens],
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: tokens.accent,
      onPrimary: tokens.onAccent,
      secondary: tokens.accent,
      onSecondary: tokens.onAccent,
      error: tokens.danger,
      onError: Colors.white,
      surface: tokens.bgSurface,
      onSurface: tokens.textPrimary,
    ),
    textTheme: textTheme.copyWith(
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.2,
        color: tokens.textPrimary,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
        color: tokens.textPrimary,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        color: tokens.textMuted,
        fontSize: 16,
        height: 1.6,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        color: tokens.textMuted,
        fontSize: 14,
        height: 1.5,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: tokens.textMuted,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.bgPrimary,
      foregroundColor: tokens.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tokens.bgSurface,
      indicatorColor: tokens.accent.withValues(alpha: isDark ? 0.2 : 0.12),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? tokens.accent : tokens.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: isSelected ? tokens.accent : tokens.textMuted,
          size: 22,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.bgInput,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.lg),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: tokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: tokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: tokens.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: tokens.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: tokens.danger, width: 1.5),
      ),
      labelStyle: TextStyle(color: tokens.textMuted),
      hintStyle: TextStyle(color: tokens.textMuted.withValues(alpha: 0.8)),
      errorStyle: TextStyle(color: tokens.danger),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.accent,
        foregroundColor: tokens.onAccent,
        elevation: 0,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.textPrimary,
        minimumSize: const Size(0, 48),
        side: BorderSide(color: tokens.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: tokens.bgSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: tokens.border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tokens.bgSurface,
      contentTextStyle: TextStyle(color: tokens.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: tokens.border),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
